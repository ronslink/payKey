import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TaxPayment, PaymentStatus } from '../entities/tax-payment.entity';
import { TaxConfigService } from '../../tax-config/services/tax-config.service';
import { TaxesService } from '../../taxes/taxes.service';
import { TaxType } from '../../tax-config/entities/tax-config.entity';
import {
  CreateTaxPaymentDto,
  MonthlyTaxSummaryDto,
  TaxSummaryDto,
} from '../dto/tax-payment.dto';

@Injectable()
export class TaxPaymentsService {
  constructor(
    @InjectRepository(TaxPayment)
    private taxPaymentRepository: Repository<TaxPayment>,
    private taxConfigService: TaxConfigService,
    private taxesService: TaxesService,
  ) { }

  /**
   * Generate monthly tax summary for a user
   * Calculates total tax obligations based on payroll for that month
   */
  async generateMonthlySummary(
    userId: string,
    year: number,
    month: number,
  ): Promise<MonthlyTaxSummaryDto> {
    // Get payroll data for the month (from transactions)
    const monthlyPayroll = await this.taxesService.getMonthlyPayrollSummary(
      userId,
      year,
      month,
    );

    // Get active tax configs
    const date = new Date(year, month - 1, 15); // Mid-month to get correct config
    const taxConfigs = await this.taxConfigService.getAllActiveTaxConfigs(date);

    const taxes: TaxSummaryDto[] = [];
    let totalDue = 0;
    let totalPaid = 0;

    // Calculate each tax type
    for (const config of taxConfigs) {
      const amount = this.calculateTaxAmount(config.taxType, monthlyPayroll);

      // Check if already paid
      const existingPayment = await this.taxPaymentRepository.findOne({
        where: {
          userId,
          taxType: config.taxType,
          paymentYear: year,
          paymentMonth: month,
        },
      });

      const status = existingPayment?.status || PaymentStatus.PENDING;
      const paidAmount = existingPayment?.amount || 0;

      taxes.push({
        taxType: config.taxType,
        amount,
        status,
        dueDate: this.calculateDueDate(year, month),
      });

      totalDue += amount;
      if (status === PaymentStatus.PAID) {
        totalPaid += paidAmount;
      }
    }

    return {
      year,
      month,
      totalDue,
      totalPaid,
      taxes,
      paymentInstructions: {
        mpesa: {
          paybill: '222222',
          accountNumber: 'Your iTax Payment Registration Number',
        },
        bank: 'Any KRA-appointed bank with payment slip from iTax',
        deadline: this.calculateDueDate(year, month),
      },
    };
  }

  /**
   * Calculate tax amount based on type and payroll data
   */
  private calculateTaxAmount(taxType: TaxType, payrollSummary: any): number {
    switch (taxType) {
      case TaxType.PAYE:
        return payrollSummary.totalPaye || 0;
      case TaxType.SHIF:
        return payrollSummary.totalShif || 0;
      case TaxType.NSSF_TIER1:
      case TaxType.NSSF_TIER2:
        return payrollSummary.totalNssf || 0;
      case TaxType.HOUSING_LEVY:
        return payrollSummary.totalHousingLevy || 0;
      default:
        return 0;
    }
  }

  /**
   * Calculate due date (9th of following month)
   */
  private calculateDueDate(year: number, month: number): string {
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;
    return `${nextYear}-${String(nextMonth).padStart(2, '0')}-09`;
  }

  /**
   * Record a manual tax payment
   */
  async recordPayment(
    userId: string,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    const payment = this.taxPaymentRepository.create({
      userId,
      ...dto,
      paymentDate: dto.paymentDate ? new Date(dto.paymentDate) : new Date(),
      status: dto.paymentDate ? PaymentStatus.PAID : PaymentStatus.PENDING,
    });

    return this.taxPaymentRepository.save(payment);
  }

  /**
   * Get payment history for a user
   */
  async getPaymentHistory(userId: string): Promise<TaxPayment[]> {
    return this.taxPaymentRepository.find({
      where: { userId },
      relations: ['user'],
      order: {
        paymentYear: 'DESC',
        paymentMonth: 'DESC',
        createdAt: 'DESC',
      },
    });
  }

  /**
   * Get pending payments
   */
  async getPendingPayments(userId: string): Promise<TaxPayment[]> {
    return this.taxPaymentRepository.find({
      where: {
        userId,
        status: PaymentStatus.PENDING,
      },
      order: {
        paymentYear: 'ASC',
        paymentMonth: 'ASC',
      },
    });
  }

  /**
   * Ensure a tax obligation exists (create if not, update if pending)
   */
  async ensureObligation(
    userId: string,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    let payment = await this.taxPaymentRepository.findOne({
      where: {
        userId,
        taxType: dto.taxType,
        paymentYear: dto.paymentYear,
        paymentMonth: dto.paymentMonth,
      },
    });

    if (!payment) {
      payment = this.taxPaymentRepository.create({
        userId,
        ...dto,
        status: PaymentStatus.PENDING,
      });
    } else if (payment.status === PaymentStatus.PENDING) {
      // Update amount if still pending (e.g. recalculation)
      payment.amount = dto.amount;
      // Update other fields if necessary
    }

    return this.taxPaymentRepository.save(payment);
  }

  /**
   * Update payment status
   */
  async updatePaymentStatus(
    id: string,
    userId: string,
    status: PaymentStatus,
  ): Promise<TaxPayment> {
    const payment = await this.taxPaymentRepository.findOne({
      where: { id, userId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    payment.status = status;
    return this.taxPaymentRepository.save(payment);
  }
}
