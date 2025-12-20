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
} from '@nestjs/common';
import type { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PayrollRecord } from './entities/payroll-record.entity';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { PayrollService } from './payroll.service';
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
  ) { }

  // ... existing methods ...

  @Post('regenerate-documents/:payPeriodId')
  async regenerateDocuments(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
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
      throw new Error('No finalized payroll records found for this period. Please verify the period is completed.');
    }

    // 2. Generate Payslips
    const payslips = await this.payslipService.generatePayslipsBatch(records);

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
  async calculatePayroll(@Request() req: AuthenticatedRequest) {
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
    @Body() body: { workerIds: string[] },
  ) {
    // TODO: Implement actual payroll processing with payments
    // For now, just return calculation
    const payrollCalculation =
      await this.payrollService.calculatePayrollForUser(req.user.userId);

    // Filter for selected workers
    const selectedPayrollItems = payrollCalculation.payrollItems.filter(
      (item) => body.workerIds.includes(item.workerId),
    );

    return {
      ...payrollCalculation,
      payrollItems: selectedPayrollItems,
      message: 'Payroll processing initiated',
    };
  }
  @Post('draft')
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
  async finalizePayroll(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.payrollService.finalizePayroll(req.user.userId, payPeriodId);
  }

  @Get('payslip/:payrollRecordId')
  async downloadPayslip(
    @Request() req: AuthenticatedRequest,
    @Param('payrollRecordId') payrollRecordId: string,
    @Res() res: Response,
  ) {
    const record = await this.payrollRepository.findOne({
      where: { id: payrollRecordId, userId: req.user.userId },
      relations: ['worker', 'payPeriod'],
    });

    if (!record) {
      throw new Error('Payroll record not found');
    }

    const buffer = await this.payslipService.generatePayslip(record);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename=payslip-${record.worker.name}-${record.payPeriodId}.pdf`,
      'Content-Length': buffer.length,
    });

    res.end(buffer);
  }

  @Get('payslips/batch/:payPeriodId')
  async downloadPayslipsBatch(
    @Request() req: AuthenticatedRequest,
    @Param('payPeriodId') payPeriodId: string,
    @Res() res: Response,
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
      throw new Error('No payroll records found for this pay period');
    }

    // Generate ZIP file with all payslips
    const { stream, filename } = await this.payslipService.generatePayslipsZip(records);

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
    // Fetch selected payroll records
    const records = await this.payrollRepository.find({
      where: {
        userId: req.user.userId,
      },
      relations: ['worker', 'payPeriod'],
    });

    const selectedRecords = records.filter(r => body.payrollRecordIds.includes(r.id));

    if (selectedRecords.length === 0) {
      throw new Error('No payroll records found');
    }

    // Generate ZIP file with selected payslips
    const { stream, filename } = await this.payslipService.generatePayslipsZip(selectedRecords);

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
      records: records.map(r => ({
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
    return this.payrollService.getWorkerPayrollHistory(req.user.userId, workerId);
  }

  @Get('me')
  async getMyPayslips(@Request() req: AuthenticatedRequest) {
    return this.payrollService.getEmployeePayslips(req.user.userId);
  }

  @Get('me/:recordId/pdf')
  async downloadMyPayslip(
    @Request() req: AuthenticatedRequest,
    @Param('recordId') recordId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const buffer = await this.payrollService.getEmployeePayslipPdf(
      req.user.userId,
      recordId,
    );

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="payslip.pdf"`,
    });

    return new StreamableFile(buffer);
  }
}
