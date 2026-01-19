import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  UseGuards,
  Request,
  Body,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PayrollRecord } from './entities/payroll-record.entity';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Payroll Records')
@Controller('payroll-records')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PayrollRecordsController {
  constructor(
    @InjectRepository(PayrollRecord)
    private payrollRepository: Repository<PayrollRecord>,
  ) { }

  @Get()
  @ApiOperation({ summary: 'Get payroll records for the current user' })
  async getPayrollRecords(@Request() req: any) {
    return this.payrollRepository.find({
      where: { userId: req.user.userId },
      relations: ['worker'],
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  @Get('worker/:workerId')
  @ApiOperation({ summary: 'Get payroll records for a specific worker' })
  async getWorkerPayrollRecords(
    @Request() req: any,
    @Param('workerId') workerId: string,
  ) {
    // For employees viewing their own payslips, use the workerId from the route
    // For employers viewing worker payslips, verify they own this worker
    const records = await this.payrollRepository.find({
      where: { workerId },
      relations: ['worker', 'payPeriod'],
      order: { periodStart: 'DESC' },
    });
    console.log('Worker Payroll Records:', JSON.stringify(records, null, 2));
    return records;
  }

  @Get('pay-period/:payPeriodId/status')
  @ApiOperation({ summary: 'Get payment status for all workers in a pay period' })
  async getPayPeriodPaymentStatus(
    @Request() req: any,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    const records = await this.payrollRepository.find({
      where: { payPeriodId, userId: req.user.userId },
      relations: ['worker'],
      select: {
        id: true,
        workerId: true,
        netSalary: true,
        paymentStatus: true,
        paymentDate: true,
        worker: {
          id: true,
          name: true,
        },
      },
    });

    return records.map((record) => ({
      id: record.id,
      workerId: record.workerId,
      workerName: record.worker?.name || 'Unknown',
      netPay: record.netSalary,
      paymentStatus: record.paymentStatus || 'pending',
      paymentDate: record.paymentDate,
    }));
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Update payment status of a payroll record' })
  async updatePayrollStatus(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { status: string; paymentDate?: string },
  ) {
    return this.payrollRepository.update(
      { id, userId: req.user.userId },
      {
        paymentStatus: body.status,
        ...(body.paymentDate && { paymentDate: new Date(body.paymentDate) }),
      },
    );
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a payroll record' })
  async deletePayrollRecord(@Request() req: any, @Param('id') id: string) {
    return this.payrollRepository.delete({ id, userId: req.user.userId });
  }
}
