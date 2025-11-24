import { Controller, Get, Patch, Delete, Param, UseGuards, Request, Body } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PayrollRecord } from './entities/payroll-record.entity';

@Controller('payroll-records')
@UseGuards(JwtAuthGuard)
export class PayrollRecordsController {
  constructor(
    @InjectRepository(PayrollRecord)
    private payrollRepository: Repository<PayrollRecord>,
  ) {}

  @Get()
  async getPayrollRecords(@Request() req: any) {
    return this.payrollRepository.find({
      where: { userId: req.user.userId },
      relations: ['worker'],
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  @Patch(':id/status')
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
  async deletePayrollRecord(@Request() req: any, @Param('id') id: string) {
    return this.payrollRepository.delete({ id, userId: req.user.userId });
  }
}