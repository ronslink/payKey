import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PayPeriod,
  PayPeriodStatus,
  PayPeriodFrequency,
} from './entities/pay-period.entity';
import { CreatePayPeriodDto } from './dto/create-pay-period.dto';
import { UpdatePayPeriodDto } from './dto/update-pay-period.dto';
import { PayrollRecord, PayrollStatus } from './entities/payroll-record.entity';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';
import { InjectRepository as InjectTaxRepository } from '@nestjs/typeorm';
import {
  TaxPayment,
  PaymentStatus,
} from '../tax-payments/entities/tax-payment.entity';
import {
  TaxSubmission,
  TaxSubmissionStatus,
} from '../taxes/entities/tax-submission.entity';

@Injectable()
export class PayPeriodsService {
  constructor(
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
    private taxPaymentsService: TaxPaymentsService,
  ) {}

  async create(
    createPayPeriodDto: CreatePayPeriodDto,
    userId: string,
  ): Promise<PayPeriod> {
    // Validate that start date is before end date
    if (
      new Date(createPayPeriodDto.startDate) >=
      new Date(createPayPeriodDto.endDate)
    ) {
      throw new BadRequestException('Start date must be before end date');
    }

    // Check for overlapping pay periods (only for this user)
    const overlapping = await this.payPeriodRepository
      .createQueryBuilder('pp')
      .where('pp.userId = :userId', { userId })
      .andWhere('pp.startDate <= :endDate', {
        endDate: createPayPeriodDto.endDate,
      })
      .andWhere('pp.endDate >= :startDate', {
        startDate: createPayPeriodDto.startDate,
      })
      .getOne();

    if (overlapping) {
      throw new BadRequestException('Pay period overlaps with existing period');
    }

    // Convert notes to proper format if it's a string
    const notes =
      typeof createPayPeriodDto.notes === 'string'
        ? { note: createPayPeriodDto.notes }
        : createPayPeriodDto.notes;

    const payPeriod = this.payPeriodRepository.create({
      name: createPayPeriodDto.name,
      startDate: createPayPeriodDto.startDate,
      endDate: createPayPeriodDto.endDate,
      payDate: createPayPeriodDto.payDate,
      frequency: createPayPeriodDto.frequency,
      notes,
      createdBy: createPayPeriodDto.createdBy,
      userId,
      status: PayPeriodStatus.DRAFT,
    });

    return this.payPeriodRepository.save(payPeriod);
  }

  async findAll(
    userId: string,
    page: number = 1,
    limit: number = 50,
    status?: PayPeriodStatus,
    frequency?: string,
    year?: number,
  ): Promise<{
    data: PayPeriod[];
    total: number;
    page: number;
    limit: number;
  }> {
    const queryBuilder = this.payPeriodRepository.createQueryBuilder('pp');

    // Filter by userId
    queryBuilder.where('pp.userId = :userId', { userId });

    if (status) {
      queryBuilder.andWhere('pp.status = :status', { status });
    }

    if (frequency) {
      queryBuilder.andWhere('pp.frequency = :frequency', { frequency });
    }

    if (year) {
      queryBuilder.andWhere('EXTRACT(YEAR FROM pp.startDate) = :year', { year });
    }

    const [data, total] = await queryBuilder
      .orderBy('pp.startDate', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data, total, page, limit };
  }

  async findOne(id: string): Promise<PayPeriod> {
    const payPeriod = await this.payPeriodRepository.findOne({ where: { id } });

    if (!payPeriod) {
      throw new NotFoundException(`Pay period with ID ${id} not found`);
    }

    return payPeriod;
  }

  async update(
    id: string,
    updatePayPeriodDto: UpdatePayPeriodDto,
  ): Promise<PayPeriod> {
    const payPeriod = await this.findOne(id);

    // Validate status transitions
    if (updatePayPeriodDto.status) {
      this.validateStatusTransition(
        payPeriod.status,
        updatePayPeriodDto.status,
      );
    }

    // Validate date changes
    if (updatePayPeriodDto.startDate || updatePayPeriodDto.endDate) {
      const newStartDate = updatePayPeriodDto.startDate || payPeriod.startDate;
      const newEndDate = updatePayPeriodDto.endDate || payPeriod.endDate;

      if (new Date(newStartDate) >= new Date(newEndDate)) {
        throw new BadRequestException('Start date must be before end date');
      }

      // Check for overlapping periods (excluding current one, only for this user)
      const overlapping = await this.payPeriodRepository
        .createQueryBuilder('pp')
        .where('pp.id != :id', { id })
        .andWhere('pp.userId = :userId', { userId: payPeriod.userId })
        .andWhere('pp.startDate <= :endDate', { endDate: newEndDate })
        .andWhere('pp.endDate >= :startDate', { startDate: newStartDate })
        .getOne();

      if (overlapping) {
        throw new BadRequestException(
          'Pay period overlaps with existing period',
        );
      }
    }

    // Update approved timestamp if status changes to completed
    if (
      updatePayPeriodDto.status === PayPeriodStatus.COMPLETED &&
      payPeriod.status !== PayPeriodStatus.COMPLETED
    ) {
      // This will be handled by the entity automatically
    }

    await this.payPeriodRepository.update(id, updatePayPeriodDto);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const payPeriod = await this.findOne(id);

    // Prevent deletion of processed or completed periods
    if (
      [
        PayPeriodStatus.PROCESSING,
        PayPeriodStatus.COMPLETED,
        PayPeriodStatus.CLOSED,
      ].includes(payPeriod.status)
    ) {
      throw new BadRequestException(
        'Cannot delete pay period that is processing, completed, or closed',
      );
    }

    // Check if there are payroll records for this period
    const payrollRecords = await this.payrollRecordRepository.count({
      where: {
        payPeriodId: id,
      },
    });

    if (payrollRecords > 0) {
      throw new BadRequestException(
        'Cannot delete pay period with existing payroll records',
      );
    }

    await this.payPeriodRepository.remove(payPeriod);
  }

  async activate(id: string): Promise<PayPeriod> {
    return this.update(id, { status: PayPeriodStatus.ACTIVE });
  }

  async process(id: string): Promise<PayPeriod> {
    const payPeriod = await this.findOne(id);

    if (
      payPeriod.status !== PayPeriodStatus.ACTIVE &&
      payPeriod.status !== PayPeriodStatus.DRAFT &&
      payPeriod.status !== PayPeriodStatus.COMPLETED && // Allow reopening from COMPLETED
      payPeriod.status !== PayPeriodStatus.CLOSED // Allow reopening from CLOSED
    ) {
      throw new BadRequestException(
        'Only draft, active, or completed pay periods can be processed',
      );
    }

    // If reopening from COMPLETED or CLOSED, we must revert records to DRAFT to allow editing
    if (
      payPeriod.status === PayPeriodStatus.COMPLETED ||
      payPeriod.status === PayPeriodStatus.CLOSED
    ) {
      await this.payrollRecordRepository.update(
        { payPeriodId: id },
        { status: PayrollStatus.DRAFT },
      );
    }

    // Calculate totals from payroll records
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        payPeriodId: id,
      },
    });

    if (payrollRecords.length === 0) {
      throw new BadRequestException(
        'Cannot process payroll with no records. Please add workers first.',
      );
    }

    const totals = payrollRecords.reduce(
      (acc, record) => ({
        grossAmount: acc.grossAmount + Number(record.grossSalary),
        netAmount: acc.netAmount + Number(record.netSalary),
        taxAmount: acc.taxAmount + Number(record.taxAmount),
        processedWorkers: acc.processedWorkers + 1,
      }),
      { grossAmount: 0, netAmount: 0, taxAmount: 0, processedWorkers: 0 },
    );

    await this.payPeriodRepository.update(id, {
      status: PayPeriodStatus.PROCESSING,
      totalGrossAmount: totals.grossAmount,
      totalNetAmount: totals.netAmount,
      totalTaxAmount: totals.taxAmount,
      processedWorkers: totals.processedWorkers,
      processedAt: new Date(),
    });

    return this.findOne(id);
  }

  async complete(id: string): Promise<PayPeriod> {
    const payPeriod = await this.findOne(id);

    // Validate that the pay period is in PROCESSING state
    if (payPeriod.status !== PayPeriodStatus.PROCESSING) {
      throw new BadRequestException(
        'Only processing pay periods can be completed',
      );
    }

    // Finalize all payroll records for this period
    await this.payrollRecordRepository.update(
      { payPeriodId: id },
      {
        status: 'finalized' as any,
        finalizedAt: new Date(),
      },
    );

    // Generate tax submission data automatically
    const adjustments = await this.generateTaxSubmissionData(id);

    // Update status to completed
    const updatedPeriod = await this.update(id, {
      status: PayPeriodStatus.COMPLETED,
    });

    return {
      ...updatedPeriod,
      adjustments,
    } as any;
  }

  /**
   * Generate tax submission data for completed pay period
   * Automatically creates TaxPayment entries for all tax types
   */
  async generateTaxSubmissionData(payPeriodId: string): Promise<any> {
    const payPeriod = await this.findOne(payPeriodId);

    // Get all payroll records for this pay period
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        payPeriodId: payPeriodId,
      },
    });

    if (payrollRecords.length === 0) {
      return; // No payroll records, nothing to generate
    }

    // Get unique user IDs (Employers)
    // Note: In this system, payroll records belong to the employer (User).
    // So all records for this payPeriod have the same userId (the employer).
    const userId = payPeriod.userId;

    // Get pay period date components
    const startDate = new Date(payPeriod.startDate);
    const paymentYear = startDate.getFullYear();
    const paymentMonth = startDate.getMonth() + 1;

    // Calculate totals from records
    const totals = {
      [TaxType.PAYE]: 0,
      [TaxType.SHIF]: 0,
      [TaxType.HOUSING_LEVY]: 0,
      [TaxType.NSSF_TIER1]: 0,
      [TaxType.NSSF_TIER2]: 0,
    };

    for (const record of payrollRecords) {
      const tb: any = record.taxBreakdown || {};
      totals[TaxType.PAYE] += Number(tb.paye || 0);
      totals[TaxType.SHIF] += Number(tb.nhif || 0); // NHIF maps to SHIF
      totals[TaxType.HOUSING_LEVY] += Number(tb.housingLevy || 0);
      totals[TaxType.NSSF_TIER1] += Number(tb.nssf || 0); // Total NSSF
    }

    // Save obligations for the employer
    for (const [taxType, amount] of Object.entries(totals)) {
      if (amount > 0) {
        await this.taxPaymentsService.ensureObligation(userId, {
          taxType: taxType as TaxType,
          amount: amount,
          paymentYear,
          paymentMonth,
        });
      }
    }

    // Create or update TaxSubmission record for the PayPeriod
    let submission = await this.taxSubmissionRepository.findOne({
      where: { payPeriodId: payPeriodId },
    });

    let adjustments = null;

    if (submission) {
      // Calculate differences if submission already exists (reopening case)
      const payeDifference =
        totals[TaxType.PAYE] - Number(submission.totalPaye);
      const shifDifference =
        totals[TaxType.SHIF] - Number(submission.totalNhif);
      const housingLevyDifference =
        totals[TaxType.HOUSING_LEVY] - Number(submission.totalHousingLevy);
      const nssfDifference =
        totals[TaxType.NSSF_TIER1] +
        (totals[TaxType.NSSF_TIER2] || 0) -
        Number(submission.totalNssf);

      adjustments = {
        payeDifference,
        shifDifference,
        housingLevyDifference,
        nssfDifference,
        totalTaxDifference:
          payeDifference +
          shifDifference +
          housingLevyDifference +
          nssfDifference,
      };
    } else {
      submission = this.taxSubmissionRepository.create({
        userId,
        payPeriodId,
        status: TaxSubmissionStatus.PENDING,
      });
    }

    // Update totals
    submission.totalPaye = totals[TaxType.PAYE];
    // Map SHIF to nhif column (Entity uses totalNhif)
    submission.totalNhif = totals[TaxType.SHIF];
    // Map NSSF (Entity uses totalNssf). Currently we put all in TIER1 in totals calculation.
    submission.totalNssf =
      totals[TaxType.NSSF_TIER1] + (totals[TaxType.NSSF_TIER2] || 0);
    submission.totalHousingLevy = totals[TaxType.HOUSING_LEVY];

    await this.taxSubmissionRepository.save(submission);

    console.log(`Tax submission data generated for payPeriod ${payPeriodId}`);
    return adjustments;
  }

  async close(id: string): Promise<PayPeriod> {
    return this.update(id, { status: PayPeriodStatus.CLOSED });
  }

  private validateStatusTransition(
    currentStatus: PayPeriodStatus,
    newStatus: PayPeriodStatus,
  ): void {
    const validTransitions: Record<PayPeriodStatus, PayPeriodStatus[]> = {
      [PayPeriodStatus.DRAFT]: [PayPeriodStatus.ACTIVE, PayPeriodStatus.CLOSED],
      [PayPeriodStatus.ACTIVE]: [
        PayPeriodStatus.PROCESSING,
        PayPeriodStatus.CLOSED,
      ],
      [PayPeriodStatus.PROCESSING]: [
        PayPeriodStatus.COMPLETED,
        PayPeriodStatus.CLOSED,
      ],
      [PayPeriodStatus.COMPLETED]: [
        PayPeriodStatus.CLOSED,
        PayPeriodStatus.PROCESSING, // Allow reopening
      ],
      [PayPeriodStatus.CLOSED]: [
        PayPeriodStatus.DRAFT, // Allow reopen to DRAFT
        PayPeriodStatus.ACTIVE, // Allow reopen to ACTIVE
        PayPeriodStatus.PROCESSING, // Allow reopening from CLOSED
      ],
    };

    if (!validTransitions[currentStatus]?.includes(newStatus)) {
      throw new BadRequestException(
        `Invalid status transition from ${currentStatus} to ${newStatus}`,
      );
    }
  }

  async getPayPeriodStatistics(id: string): Promise<any> {
    const payPeriod = await this.findOne(id);

    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        payPeriodId: id,
      },
    });

    return {
      payPeriod: {
        id: payPeriod.id,
        name: payPeriod.name,
        status: payPeriod.status,
        startDate: payPeriod.startDate,
        endDate: payPeriod.endDate,
      },
      statistics: {
        totalWorkers: payrollRecords.length,
        pendingPayments: payrollRecords.filter(
          (r) => r.paymentStatus === 'pending',
        ).length,
        processedPayments: payrollRecords.filter(
          (r) => r.paymentStatus === 'paid',
        ).length,
        totalGrossAmount: payrollRecords.reduce(
          (sum, r) => sum + Number(r.grossSalary),
          0,
        ),
        totalNetAmount: payrollRecords.reduce(
          (sum, r) => sum + Number(r.netSalary),
          0,
        ),
        totalTaxAmount: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxAmount),
          0,
        ),
      },
      taxSummary: {
        paye: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxBreakdown?.paye || 0),
          0,
        ),
        nhif: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxBreakdown?.nhif || 0),
          0,
        ),
        nssf: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxBreakdown?.nssf || 0),
          0,
        ),
        housingLevy: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxBreakdown?.housingLevy || 0),
          0,
        ),
        total: payrollRecords.reduce(
          (sum, r) => sum + Number(r.taxAmount || 0),
          0,
        ),
      },
    };
  }

  async generatePayPeriods(
    userId: string,
    frequency: string,
    startDate: Date,
    endDate: Date,
  ): Promise<PayPeriod[]> {
    const periods: PayPeriod[] = [];
    let currentDate = new Date(startDate);

    // Normalize start date to beginning of day
    currentDate.setHours(0, 0, 0, 0);

    while (currentDate <= endDate) {
      const periodStart = new Date(currentDate);
      let periodEnd: Date;

      if (frequency === PayPeriodFrequency.MONTHLY) {
        // First day of next month
        const nextMonth = new Date(
          currentDate.getFullYear(),
          currentDate.getMonth() + 1,
          1,
        );
        // Last day of current month is "day 0" of next month
        periodEnd = new Date(nextMonth.getTime() - 1); // effectively last millisecond, or set day 0
        // Clean up time
        periodEnd.setHours(0, 0, 0, 0);

        // Prepare for next iteration
        currentDate = new Date(nextMonth);
      } else {
        // Fallback for weekly/biweekly using step days (simplified)
        const stepDays = this.getStepDays(frequency);
        periodEnd = new Date(periodStart);
        periodEnd.setDate(periodEnd.getDate() + stepDays - 1);

        // Next start is day after end
        currentDate = new Date(periodEnd);
        currentDate.setDate(currentDate.getDate() + 1);
      }

      if (periodStart > endDate) break;

      // Adjust periodEnd if it exceeds the global endDate (optional, but for yearly gen usually we want full periods)
      // For clean years, we usually generate full months.

      const name = this.generatePeriodName(periodStart, periodEnd, frequency);

      const payPeriod = this.payPeriodRepository.create({
        name,
        startDate: this.formatDate(periodStart),
        endDate: this.formatDate(periodEnd),
        payDate: this.formatDate(periodEnd), // Default pay date to end of period
        frequency: frequency as PayPeriodFrequency,
        status: PayPeriodStatus.DRAFT,
        createdBy: userId,
        userId: userId,
      });

      periods.push(await this.payPeriodRepository.save(payPeriod));
    }

    return periods;
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private getStepDays(frequency: string): number {
    const frequencyMap: Record<string, number> = {
      [PayPeriodFrequency.WEEKLY]: 7,
      [PayPeriodFrequency.BIWEEKLY]: 14,
      [PayPeriodFrequency.MONTHLY]: 30, // Fallback, not used in customized loop
      [PayPeriodFrequency.QUARTERLY]: 90,
    };
    return frequencyMap[frequency] || 30;
  }

  private generatePeriodName(
    startDate: Date,
    endDate: Date,
    frequency: string,
  ): string {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const startMonth = monthNames[startDate.getMonth()];
    const endMonth = monthNames[endDate.getMonth()];

    if (frequency === 'MONTHLY' && startMonth === endMonth) {
      return `${startMonth} ${startDate.getFullYear()}`;
    }

    return `${startMonth} ${startDate.getDate()}, ${startDate.getFullYear()} - ${endMonth} ${endDate.getDate()}, ${endDate.getFullYear()}`;
  }
}
