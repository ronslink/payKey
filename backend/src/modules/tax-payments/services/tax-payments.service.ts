import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindOptionsWhere } from 'typeorm';
import { TaxPayment, PaymentStatus } from '../entities/tax-payment.entity';
import { TaxConfigService } from '../../tax-config/services/tax-config.service';
import { TaxesService } from '../../taxes/taxes.service';
import { TaxType, TaxConfig } from '../../tax-config/entities/tax-config.entity';
import {
  CreateTaxPaymentDto,
  MonthlyTaxSummaryDto,
  TaxSummaryDto,
} from '../dto/tax-payment.dto';

// =============================================================================
// TYPES & INTERFACES
// =============================================================================

/** Payroll summary data structure from TaxesService */
interface PayrollSummary {
  totalPaye: number;
  totalShif: number;
  totalNssf: number;
  totalHousingLevy: number;
  totalGross?: number;
  workerCount?: number;
}

/** Payment instructions for different payment methods */
interface PaymentInstructions {
  mpesa: {
    paybill: string;
    accountNumber: string;
  };
  bank: string;
  deadline: string;
}

/** Result of tax calculation for a single tax type */
interface TaxCalculationResult {
  taxType: TaxType;
  calculatedAmount: number;
  existingPayment: TaxPayment | null;
  status: PaymentStatus;
  paidAmount: number;
}

// =============================================================================
// CONSTANTS
// =============================================================================

/** KRA M-Pesa Paybill number */
const KRA_PAYBILL = '222222';

/** Tax payment due day (9th of following month) */
const TAX_DUE_DAY = 9;

/** Mapping of tax types to payroll summary fields */
const TAX_TYPE_FIELD_MAP: Record<TaxType, keyof PayrollSummary | null> = {
  [TaxType.PAYE]: 'totalPaye',
  [TaxType.NHIF]: 'totalShif', // Map legacy NHIF to totalShif field for now, or add totalNhif
  [TaxType.SHIF]: 'totalShif',
  [TaxType.NSSF_TIER1]: 'totalNssf',
  [TaxType.NSSF_TIER2]: 'totalNssf',
  [TaxType.HOUSING_LEVY]: 'totalHousingLevy',
};

// =============================================================================
// SERVICE
// =============================================================================

@Injectable()
export class TaxPaymentsService {
  private readonly logger = new Logger(TaxPaymentsService.name);

  constructor(
    @InjectRepository(TaxPayment)
    private readonly taxPaymentRepository: Repository<TaxPayment>,
    private readonly taxConfigService: TaxConfigService,
    private readonly taxesService: TaxesService,
  ) { }

  // ---------------------------------------------------------------------------
  // Public Methods: Monthly Summary
  // ---------------------------------------------------------------------------

  /**
   * Generate monthly tax summary for a user.
   * Calculates total tax obligations based on payroll for that month.
   *
   * @param userId - The user's ID
   * @param year - Tax year
   * @param month - Tax month (1-12)
   * @returns Monthly tax summary with payment instructions
   */
  async generateMonthlySummary(
    userId: string,
    year: number,
    month: number,
  ): Promise<MonthlyTaxSummaryDto> {
    this.validateYearMonth(year, month);

    const [payrollSummary, taxConfigs] = await Promise.all([
      this.getPayrollSummary(userId, year, month),
      this.getActiveTaxConfigs(year, month),
    ]);

    const taxCalculations = await this.calculateAllTaxes(
      userId,
      year,
      month,
      payrollSummary,
      taxConfigs,
    );

    const { taxes, totalDue, totalPaid } = this.aggregateTaxResults(
      taxCalculations,
      year,
      month,
    );

    return {
      year,
      month,
      totalDue,
      totalPaid,
      taxes,
      paymentInstructions: this.getPaymentInstructions(year, month),
    };
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Payment Management
  // ---------------------------------------------------------------------------

  /**
   * Record a manual tax payment.
   *
   * @param userId - The user's ID
   * @param dto - Payment creation data
   * @returns The created payment record
   */
  async recordPayment(
    userId: string,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    this.validateYearMonth(dto.paymentYear, dto.paymentMonth);

    const paymentDate = dto.paymentDate ? new Date(dto.paymentDate) : new Date();
    const status = dto.paymentDate ? PaymentStatus.PAID : PaymentStatus.PENDING;

    const payment = this.taxPaymentRepository.create({
      userId,
      ...dto,
      paymentDate,
      status,
    });

    const saved = await this.taxPaymentRepository.save(payment);

    this.logger.log(
      `Recorded ${status} payment for user ${userId}: ${dto.taxType} ${dto.paymentYear}/${dto.paymentMonth}`,
    );

    return saved;
  }

  /**
   * Ensure a tax obligation exists.
   * Creates if not exists, updates amount if still pending.
   *
   * @param userId - The user's ID
   * @param dto - Tax obligation data
   * @returns The existing or created payment record
   */
  async ensureObligation(
    userId: string,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    const existing = await this.findPayment(userId, {
      taxType: dto.taxType,
      paymentYear: dto.paymentYear,
      paymentMonth: dto.paymentMonth,
    });

    if (!existing) {
      return this.createPendingObligation(userId, dto);
    }

    if (existing.status === PaymentStatus.PENDING) {
      return this.updatePendingObligation(existing, dto);
    }

    // Already paid or in another non-pending state - return as is
    return existing;
  }

  /**
   * Update payment status.
   *
   * @param id - Payment record ID
   * @param userId - The user's ID (for authorization)
   * @param status - New payment status
   * @returns Updated payment record
   * @throws NotFoundException if payment not found
   */
  async updatePaymentStatus(
    id: string,
    userId: string,
    status: PaymentStatus,
  ): Promise<TaxPayment> {
    const payment = await this.findPaymentById(id, userId);

    if (!payment) {
      throw new NotFoundException(`Payment with ID ${id} not found`);
    }

    const previousStatus = payment.status;
    payment.status = status;

    if (status === PaymentStatus.PAID && !payment.paymentDate) {
      payment.paymentDate = new Date();
    }

    const updated = await this.taxPaymentRepository.save(payment);

    this.logger.log(
      `Updated payment ${id} status: ${previousStatus} -> ${status}`,
    );

    return updated;
  }

  // ---------------------------------------------------------------------------
  // Public Methods: Payment Queries
  // ---------------------------------------------------------------------------

  /**
   * Get payment history for a user.
   *
   * @param userId - The user's ID
   * @returns List of all payments, newest first
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
   * Get pending payments for a user.
   *
   * @param userId - The user's ID
   * @returns List of pending payments, oldest first
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
   * Get payments for a specific month.
   *
   * @param userId - The user's ID
   * @param year - Tax year
   * @param month - Tax month
   * @returns List of payments for that month
   */
  async getPaymentsByMonth(
    userId: string,
    year: number,
    month: number,
  ): Promise<TaxPayment[]> {
    return this.taxPaymentRepository.find({
      where: {
        userId,
        paymentYear: year,
        paymentMonth: month,
      },
      order: { createdAt: 'DESC' },
    });
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Data Retrieval
  // ---------------------------------------------------------------------------

  private async getPayrollSummary(
    userId: string,
    year: number,
    month: number,
  ): Promise<PayrollSummary> {
    try {
      return await this.taxesService.getMonthlyPayrollSummary(userId, year, month);
    } catch (error) {
      this.logger.warn(
        `Failed to get payroll summary for ${userId} ${year}/${month}: ${error.message}`,
      );
      return this.emptyPayrollSummary();
    }
  }

  private async getActiveTaxConfigs(
    year: number,
    month: number,
  ): Promise<TaxConfig[]> {
    // Use mid-month date to get correct config for the period
    const referenceDate = new Date(year, month - 1, 15);
    return this.taxConfigService.getAllActiveTaxConfigs(referenceDate);
  }

  private async findPayment(
    userId: string,
    criteria: Partial<Pick<TaxPayment, 'taxType' | 'paymentYear' | 'paymentMonth'>>,
  ): Promise<TaxPayment | null> {
    return this.taxPaymentRepository.findOne({
      where: {
        userId,
        ...criteria,
      } as FindOptionsWhere<TaxPayment>,
    });
  }

  private async findPaymentById(
    id: string,
    userId: string,
  ): Promise<TaxPayment | null> {
    return this.taxPaymentRepository.findOne({
      where: { id, userId },
    });
  }

  private async findExistingPayment(
    userId: string,
    taxType: TaxType,
    year: number,
    month: number,
  ): Promise<TaxPayment | null> {
    return this.taxPaymentRepository.findOne({
      where: {
        userId,
        taxType,
        paymentYear: year,
        paymentMonth: month,
      },
    });
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Tax Calculations
  // ---------------------------------------------------------------------------

  private async calculateAllTaxes(
    userId: string,
    year: number,
    month: number,
    payrollSummary: PayrollSummary,
    taxConfigs: TaxConfig[],
  ): Promise<TaxCalculationResult[]> {
    const results: TaxCalculationResult[] = [];

    for (const config of taxConfigs) {
      const calculatedAmount = this.calculateTaxAmount(
        config.taxType,
        payrollSummary,
      );

      const existingPayment = await this.findExistingPayment(
        userId,
        config.taxType,
        year,
        month,
      );

      results.push({
        taxType: config.taxType,
        calculatedAmount,
        existingPayment,
        status: existingPayment?.status ?? PaymentStatus.PENDING,
        paidAmount: existingPayment?.amount ?? 0,
      });
    }

    return results;
  }

  private calculateTaxAmount(
    taxType: TaxType,
    payrollSummary: PayrollSummary,
  ): number {
    const field = TAX_TYPE_FIELD_MAP[taxType];

    if (!field) {
      this.logger.warn(`Unknown tax type: ${taxType}`);
      return 0;
    }

    return payrollSummary[field] ?? 0;
  }

  private aggregateTaxResults(
    calculations: TaxCalculationResult[],
    year: number,
    month: number,
  ): { taxes: TaxSummaryDto[]; totalDue: number; totalPaid: number } {
    const dueDate = this.calculateDueDate(year, month);

    let totalDue = 0;
    let totalPaid = 0;

    const taxes: TaxSummaryDto[] = calculations.map((calc) => {
      totalDue += calc.calculatedAmount;

      if (calc.status === PaymentStatus.PAID) {
        totalPaid += calc.paidAmount;
      }

      return {
        taxType: calc.taxType,
        amount: calc.calculatedAmount,
        status: calc.status,
        dueDate,
      };
    });

    return { taxes, totalDue, totalPaid };
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Payment Creation/Updates
  // ---------------------------------------------------------------------------

  private async createPendingObligation(
    userId: string,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    const payment = this.taxPaymentRepository.create({
      userId,
      ...dto,
      status: PaymentStatus.PENDING,
    });

    this.logger.log(
      `Created pending obligation for user ${userId}: ${dto.taxType} ${dto.paymentYear}/${dto.paymentMonth}`,
    );

    return this.taxPaymentRepository.save(payment);
  }

  private async updatePendingObligation(
    existing: TaxPayment,
    dto: CreateTaxPaymentDto,
  ): Promise<TaxPayment> {
    const previousAmount = existing.amount;
    existing.amount = dto.amount;

    if (previousAmount !== dto.amount) {
      this.logger.log(
        `Updated pending obligation amount: ${previousAmount} -> ${dto.amount}`,
      );
    }

    return this.taxPaymentRepository.save(existing);
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Date Calculations
  // ---------------------------------------------------------------------------

  /**
   * Calculate tax payment due date (9th of following month).
   */
  private calculateDueDate(year: number, month: number): string {
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;

    return this.formatDate(nextYear, nextMonth, TAX_DUE_DAY);
  }

  private formatDate(year: number, month: number, day: number): string {
    const monthStr = String(month).padStart(2, '0');
    const dayStr = String(day).padStart(2, '0');
    return `${year}-${monthStr}-${dayStr}`;
  }

  // ---------------------------------------------------------------------------
  // Private Methods: Utilities
  // ---------------------------------------------------------------------------

  private validateYearMonth(year: number, month: number): void {
    if (month < 1 || month > 12) {
      throw new BadRequestException(`Invalid month: ${month}. Must be 1-12.`);
    }

    const currentYear = new Date().getFullYear();
    if (year < 2000 || year > currentYear + 1) {
      throw new BadRequestException(
        `Invalid year: ${year}. Must be between 2000 and ${currentYear + 1}.`,
      );
    }
  }

  private emptyPayrollSummary(): PayrollSummary {
    return {
      totalPaye: 0,
      totalShif: 0,
      totalNssf: 0,
      totalHousingLevy: 0,
    };
  }

  private getPaymentInstructions(year: number, month: number): PaymentInstructions {
    return {
      mpesa: {
        paybill: KRA_PAYBILL,
        accountNumber: 'Your iTax Payment Registration Number',
      },
      bank: 'Any KRA-appointed bank with payment slip from iTax',
      deadline: this.calculateDueDate(year, month),
    };
  }
}