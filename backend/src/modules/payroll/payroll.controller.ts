import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  Res,
  StreamableFile,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import type { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PayrollRecord } from './entities/payroll-record.entity';
import { User } from '../users/entities/user.entity';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import {
  PayrollService,
  PayrollCalculationResult,
  PayrollItem,
  PayrollSummary,
  FundsVerificationResult,
} from './payroll.service';
import { PayslipService } from './payslip.service';
import { TaxesService } from '../taxes/taxes.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('payroll')
@UseGuards(JwtAuthGuard)
export class PayrollController {
  constructor(
    private readonly payrollService: PayrollService,
    private readonly payslipService: PayslipService,
    private readonly taxesService: TaxesService,
    @InjectRepository(PayrollRecord)
    private payrollRepository: Repository<PayrollRecord>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) { }

  // Helper method to get employer name (fetch once, use for all payslips)
  private async getEmployerName(userId: string): Promise<string> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    return (
      user?.businessName ||
      [user?.firstName, user?.lastName].filter(Boolean).join(' ') ||
      'Employer'
    );
  }

  // ... existing methods ...

  @Post('regenerate-documents/:payPeriodId')
  async regenerateDocuments(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    // Fetch employer name ONCE for all payslips
    const employerName = await this.getEmployerName(req.user.userId);

    // 1. Fetch all finalized records for this period
    const records = await this.payrollRepository.find({
      where: {
        payPeriodId,
        userId: req.user.userId,
        status: 'finalized' as any,
      },
      relations: ['worker', 'payPeriod'],
    });

    if (records.length === 0) {
      throw new Error(
        'No finalized payroll records found for this period. Please verify the period is completed.',
      );
    }

    // 2. Generate Payslips (employer name passed once for all)
    const payslips = await this.payslipService.generatePayslipsBatch(
      records,
      employerName,
    );

    // 3. Generate Tax Submission
    const taxSubmission = await this.taxesService.generateTaxSubmission(
      payPeriodId,
      req.user.userId,
    );

    return {
      success: true,
      message: 'Documents regenerated successfully',
      details: {
        recordsFound: records.length,
        payslipsGenerated: payslips.length,
        taxSubmissionId: taxSubmission.id,
      },
    };
  }

  @Get('calculate')
  async calculatePayroll(
    @Request() req: AuthenticatedRequest,
  ): Promise<PayrollCalculationResult> {
    return this.payrollService.calculatePayrollForUser(req.user.userId);
  }

  @Get('stats')
  async getStats(@Request() req: AuthenticatedRequest) {
    return this.payrollService.getPayrollStats(req.user.userId);
  }

  @Post('calculate')
  async calculatePayrollForWorkers(
    @Request() req: AuthenticatedRequest,
    @Body() body: { workerIds: string[]; startDate?: string; endDate?: string },
  ) {
    // For now, we ignore dates as calculation is based on fixed salary
    // In the future, we can use dates to prorate salary
    const fullPayroll = await this.payrollService.calculatePayrollForUser(
      req.user.userId,
    );

    if (body.workerIds && body.workerIds.length > 0) {
      const filteredItems = fullPayroll.payrollItems.filter((item) =>
        body.workerIds.includes(item.workerId),
      );

      // Recalculate summary
      const totalGross = filteredItems.reduce(
        (sum, item) => sum + item.grossSalary,
        0,
      );
      const totalDeductions = filteredItems.reduce(
        (sum, item) => sum + item.taxBreakdown.totalDeductions,
        0,
      );
      const totalNetPay = filteredItems.reduce(
        (sum, item) => sum + item.netPay,
        0,
      );

      return {
        payrollItems: filteredItems,
        summary: {
          totalGross: Math.round(totalGross * 100) / 100,
          totalDeductions: Math.round(totalDeductions * 100) / 100,
          totalNetPay: Math.round(totalNetPay * 100) / 100,
          workerCount: filteredItems.length,
        },
      };
    }

    return fullPayroll;
  }

  @Get('calculate/:workerId')
  async calculateSingleWorkerPayroll(
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
  ) {
    return this.payrollService.calculateSingleWorkerPayroll(
      workerId,
      req.user.userId,
    );
  }

  @Post('process')
  async processPayroll(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: { workerIds: string[]; payPeriodId: string; skipPayout?: boolean },
  ) {
    // 1. Calculate payroll for verification
    const payrollCalculation =
      await this.payrollService.calculatePayrollForUser(req.user.userId);

    // Filter to ensure we only process what is requested
    const itemsToProcess = payrollCalculation.payrollItems.filter((item) =>
      body.workerIds.includes(item.workerId),
    );

    if (itemsToProcess.length === 0) {
      throw new Error('No workers selected for processing');
    }

    // 2. Ensure they are saved as DRAFT first (Repo relies on DRAFT records to finalize)
    // FIX: Do NOT recalculate and overwrite here. The frontend has already saved the draft with specific user inputs (e.g. partial pay).
    // Overwriting here with default calculation destroys those edits.
    // We assume the draft is already saved correctly by the client.

    /* 
    const draftItems = itemsToProcess.map((item) => ({
      workerId: item.workerId,
      grossSalary: item.grossSalary,
      bonuses: 0, // Default for auto-run
      otherEarnings: 0,
      otherDeductions: 0,
    }));

    await this.payrollService.saveDraftPayroll(
      req.user.userId,
      body.payPeriodId,
      draftItems,
    );
    */

    // 3. Finalize immediately (Automated Flow)
    // This executes: Funds Check -> Finalize Records -> Generate Payslips -> Tax Submission
    return this.payrollService.finalizePayroll(
      req.user.userId,
      body.payPeriodId,
      body.skipPayout ?? false, // Pass skipPayout flag
    );
  }
  @Post('recalculate/:payPeriodId')
  @UseGuards(JwtAuthGuard)
  async recalculatePayroll(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    // 1. Get current draft items
    const draftItems = await this.payrollService.getDraftPayroll(
      req.user.userId,
      payPeriodId,
    );

    if (!draftItems || draftItems.length === 0) {
      throw new NotFoundException(
        'No draft records found for this period. Please calculate payroll first.',
      );
    }

    // 2. Map to DraftPayrollItem format for saving
    // This will trigger a fresh calculation with current tax rates
    const itemsToRecalculate = draftItems.map((item) => ({
      workerId: item.workerId,
      grossSalary: item.grossSalary,
      bonuses: item.bonuses || 0,
      otherEarnings: item.otherEarnings || 0,
      otherDeductions: item.otherDeductions || 0,
    }));

    // 3. Save (Recalculate)
    // The service handles status validation (must be modifiable)
    return this.payrollService.saveDraftPayroll(
      req.user.userId,
      payPeriodId,
      itemsToRecalculate,
    );
  }

  @Post('draft')
  @UseGuards(JwtAuthGuard)
  async saveDraftPayroll(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: {
      payPeriodId: string;
      payrollItems: Array<{
        workerId: string;
        grossSalary: number;
        bonuses?: number;
        otherEarnings?: number;
        otherDeductions?: number;
      }>;
    },
  ) {
    return this.payrollService.saveDraftPayroll(
      req.user.userId,
      body.payPeriodId,
      body.payrollItems,
    );
  }

  @Patch('draft/:payrollRecordId')
  async updateDraftPayrollItem(
    @Request() req: AuthenticatedRequest,
    @Param('payrollRecordId') payrollRecordId: string,
    @Body()
    body: {
      grossSalary?: number;
      bonuses?: number;
      otherEarnings?: number;
      otherDeductions?: number;
      holidayHours?: number;
      sundayHours?: number;
    },
  ) {
    return this.payrollService.updateDraftPayrollItem(
      req.user.userId,
      payrollRecordId,
      body,
    );
  }

  @Get('draft/:payPeriodId')
  async getDraftPayroll(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.payrollService.getDraftPayroll(req.user.userId, payPeriodId);
  }

  @Get('period-records/:payPeriodId')
  async getPeriodRecords(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.payrollService.getPeriodRecords(req.user.userId, payPeriodId);
  }

  @Post('finalize/:payPeriodId')
  @UseGuards(JwtAuthGuard)
  async finalizePayroll(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
    @Body() body: { skipPayout?: boolean } = {},
  ) {
    return this.payrollService.finalizePayroll(
      req.user.userId,
      payPeriodId,
      body.skipPayout ?? false,
    );
  }

  @Get('payslip/:payrollRecordId')
  async downloadPayslip(
    @Request() req: AuthenticatedRequest,
    @Param('payrollRecordId') payrollRecordId: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const record = await this.payrollRepository.findOne({
      where: { id: payrollRecordId, userId: req.user.userId },
      relations: ['worker', 'payPeriod', 'user'],
    });

    if (!record) {
      throw new NotFoundException('Payroll record not found');
    }

    try {
      // Get employer name: prefer businessName, fallback to fullName
      const employerName =
        record.user?.businessName ||
        [record.user?.firstName, record.user?.lastName]
          .filter(Boolean)
          .join(' ') ||
        'Employer';

      const buffer = await this.payslipService.generatePayslip(
        record,
        employerName,
      );

      return new StreamableFile(buffer, {
        type: 'application/pdf',
        disposition: `attachment; filename="payslip-${record.worker.name}-${record.payPeriodId}.pdf"`,
        length: buffer.length,
      });
    } catch (error) {
      console.error('Error generating payslip:', error);
      throw new InternalServerErrorException(
        error.message || 'Failed to generate payslip',
      );
    }
  }

  @Get('payslips/batch/:payPeriodId')
  async downloadPayslipsBatch(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
    @Res() res: Response,
  ) {
    // Fetch employer name ONCE
    const employerName = await this.getEmployerName(req.user.userId);

    // Fetch all finalized payroll records for the pay period
    const records = await this.payrollRepository.find({
      where: {
        payPeriodId,
        userId: req.user.userId,
        status: 'finalized' as any,
      },
      relations: ['worker'],
    });

    if (records.length === 0) {
      throw new Error('No payroll records found for this pay period');
    }

    // Generate ZIP file with all payslips (employer name passed once)
    const { stream, filename } = await this.payslipService.generatePayslipsZip(
      records,
      employerName,
    );

    res.set({
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename=${filename}`,
    });

    stream.pipe(res);
  }

  @Post('payslips/batch')
  async downloadSelectedPayslips(
    @Request() req: AuthenticatedRequest,
    @Body() body: { payrollRecordIds: string[] },
    @Res() res: Response,
  ) {
    // Fetch employer name ONCE
    const employerName = await this.getEmployerName(req.user.userId);

    // Fetch selected payroll records
    const records = await this.payrollRepository.find({
      where: {
        userId: req.user.userId,
      },
      relations: ['worker', 'payPeriod'],
    });

    const selectedRecords = records.filter((r) =>
      body.payrollRecordIds.includes(r.id),
    );

    if (selectedRecords.length === 0) {
      throw new Error('No payroll records found');
    }

    // Generate ZIP file with selected payslips (employer name passed once)
    const { stream, filename } = await this.payslipService.generatePayslipsZip(
      selectedRecords,
      employerName,
    );

    res.set({
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename=${filename}`,
    });

    stream.pipe(res);
  }

  @Post('payslips/generate/:payPeriodId')
  async generatePayslipsForPeriod(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    // Fetch all finalized payroll records for the pay period
    const records = await this.payrollRepository.find({
      where: {
        payPeriodId,
        userId: req.user.userId,
        status: 'finalized' as any,
      },
      relations: ['worker'],
    });

    if (records.length === 0) {
      throw new Error('No finalized payroll records found for this pay period');
    }

    // Generate payslips for all records
    await this.payslipService.generatePayslipsBatch(records);

    return {
      message: 'Payslips generated successfully',
      count: records.length,
      records: records.map((r) => ({
        id: r.id,
        workerId: r.workerId,
        workerName: r.worker.name,
      })),
    };
  }

  @Get('worker/:workerId')
  async getWorkerHistory(
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
  ) {
    return this.payrollService.getWorkerPayrollHistory(
      req.user.userId,
      workerId,
    );
  }

  @Get('me')
  async getMyPayslips(@Request() req: AuthenticatedRequest) {
    // If workerId is available (from JWT), pass it directly (requires service update to accept optional workerId)
    // Or just pass userId and let service resolve it.
    // Ideally we update service to support workerId lookup directly.
    return this.payrollService.getEmployeePayslips(
      req.user.userId,
      req.user.workerId,
    );
  }

  @Get('me/:recordId/pdf')
  async downloadMyPayslip(
    @Request() req: AuthenticatedRequest,
    @Param('recordId') recordId: string,
    @Res() res: Response,
  ) {
    const buffer = await this.payrollService.getEmployeePayslipPdf(
      req.user.userId,
      recordId,
      req.user.workerId,
    );

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="payslip.pdf"',
      'Content-Length': buffer.length,
    });

    res.end(buffer);
  }

  /**
   * Verify if user has sufficient wallet balance to process payroll for a period
   */
  @Get('verify-funds/:payPeriodId')
  async verifyPayrollFunds(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.payrollService.verifyFundsForPeriod(
      req.user.userId,
      payPeriodId,
    );
  }
}
