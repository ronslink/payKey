import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  UseGuards,
  Request,
  Res,
} from '@nestjs/common';
import { TaxPaymentsService } from '../services/tax-payments.service';
import {
  CreateTaxPaymentDto,
  MonthlyTaxSummaryDto,
} from '../dto/tax-payment.dto';
import { TaxPayment, PaymentStatus } from '../entities/tax-payment.entity';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import type { Response } from 'express';

@Controller('tax-payments')
@UseGuards(JwtAuthGuard)
export class TaxPaymentsController {
  constructor(private readonly taxPaymentsService: TaxPaymentsService) {}

  @Get('summary/:year/:month')
  async getMonthlySummary(
    @Request() req: any,
    @Param('year') year: string,
    @Param('month') month: string,
  ): Promise<MonthlyTaxSummaryDto> {
    return this.taxPaymentsService.generateMonthlySummary(
      req.user.userId,
      parseInt(year),
      parseInt(month),
    );
  }

  @Post()
  async recordPayment(
    @Request() req: any,
    @Body() dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    return this.taxPaymentsService.recordPayment(req.user.userId, dto);
  }

  @Get('history')
  async getPaymentHistory(@Request() req: any): Promise<TaxPayment[]> {
    return this.taxPaymentsService.getPaymentHistory(req.user.userId);
  }

  @Get('pending')
  async getPendingPayments(@Request() req: any): Promise<TaxPayment[]> {
    return this.taxPaymentsService.getPendingPayments(req.user.userId);
  }

  @Patch(':id/status')
  async updatePaymentStatus(
    @Request() req: any,
    @Param('id') id: string,
    @Body('status') status: PaymentStatus,
  ): Promise<TaxPayment> {
    return this.taxPaymentsService.updatePaymentStatus(
      id,
      req.user.userId,
      status,
    );
  }

  @Get('instructions')
  async getPaymentInstructions(): Promise<any> {
    return {
      mpesa: {
        paybill: '222222',
        accountNumber: 'Your iTax Payment Registration Number',
        steps: [
          'Go to M-Pesa menu',
          'Select Lipa na M-Pesa',
          'Select Pay Bill',
          'Enter Business Number: 222222',
          'Enter Account Number: Your iTax Payment Registration Number',
          'Enter Amount',
          'Enter M-Pesa PIN',
          'Confirm payment',
        ],
      },
      bank: {
        method: 'Visit any KRA-appointed bank',
        requirement: 'Payment slip from iTax portal',
        steps: [
          'Log in to iTax portal (itax.kra.go.ke)',
          'Navigate to Payments section',
          'Select tax type (PAYE, NSSF, SHIF, Housing Levy)',
          'Generate payment slip',
          'Present slip at any KRA-appointed bank',
        ],
      },
      deadline: '9th day of the following month',
      penalties: 'Late payment attracts penalties and interest',
    };
  }
}
