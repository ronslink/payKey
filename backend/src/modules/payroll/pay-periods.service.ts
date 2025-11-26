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
import { PayrollRecord } from './entities/payroll-record.entity';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';
import { InjectRepository as InjectTaxRepository } from '@nestjs/typeorm';
import {
  TaxPayment,
  PaymentStatus,
} from '../tax-payments/entities/tax-payment.entity';

@Injectable()
export class PayPeriodsService {
  constructor(
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    private taxPaymentsService: TaxPaymentsService,
  ) {}

  async create(createPayPeriodDto: CreatePayPeriodDto): Promise<PayPeriod> {
    // Validate that start date is before end date
    if (
      new Date(createPayPeriodDto.startDate) >=
      new Date(createPayPeriodDto.endDate)
    ) {
      throw new BadRequestException('Start date must be before end date');
    }

    // Check for overlapping pay periods
    const overlapping = await this.payPeriodRepository
      .createQueryBuilder('pp')
      .where('pp.startDate <= :endDate', {
        endDate: createPayPeriodDto.endDate,
      })
      .andWhere('pp.endDate >= :startDate', {
        startDate: createPayPeriodDto.startDate,
      })
      .getOne();

    if (overlapping) {
      throw new BadRequestException('Pay period overlaps with existing period');
    }

    const payPeriod = this.payPeriodRepository.create({
      ...createPayPeriodDto,
      status: PayPeriodStatus.DRAFT,
    });

    return this.payPeriodRepository.save(payPeriod);
  }

  async findAll(
    page: number = 1,
    limit: number = 10,
    status?: PayPeriodStatus,
    frequency?: string,
  ): Promise<{
    data: PayPeriod[];
    total: number;
    page: number;
    limit: number;
  }> {
    const queryBuilder = this.payPeriodRepository.createQueryBuilder('pp');

    if (status) {
      queryBuilder.andWhere('pp.status = :status', { status });
    }

    if (frequency) {
      queryBuilder.andWhere('pp.frequency = :frequency', { frequency });
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

      // Check for overlapping periods (excluding current one)
      const overlapping = await this.payPeriodRepository
        .createQueryBuilder('pp')
        .where('pp.id != :id', { id })
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
        periodStart: payPeriod.startDate,
        periodEnd: payPeriod.endDate,
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
      payPeriod.status !== PayPeriodStatus.DRAFT
    ) {
      throw new BadRequestException(
        'Only draft or active pay periods can be processed',
      );
    }

    // Calculate totals from payroll records
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        periodStart: payPeriod.startDate,
        periodEnd: payPeriod.endDate,
      },
    });

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

    // Generate tax submission data automatically
    await this.generateTaxSubmissionData(id);

    // Update status to completed
    return this.update(id, { status: PayPeriodStatus.COMPLETED });
  }

  /**
   * Generate tax submission data for completed pay period
   * Automatically creates TaxPayment entries for all tax types
   */
  private async generateTaxSubmissionData(payPeriodId: string): Promise<void> {
    const payPeriod = await this.findOne(payPeriodId);

    // Get all payroll records for this pay period
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        periodStart: payPeriod.startDate,
        periodEnd: payPeriod.endDate,
      },
    });

    if (payrollRecords.length === 0) {
      return; // No payroll records, nothing to generate
    }

    // Get unique user IDs from payroll records
    const uniqueUserIds = [...new Set(payrollRecords.map((r) => r.userId))];

    // Get pay period date components
    const startDate = new Date(payPeriod.startDate);
    const paymentYear = startDate.getFullYear();
    const paymentMonth = startDate.getMonth() + 1;

    // For each user, generate tax submission data using existing TaxPaymentsService
    for (const userId of uniqueUserIds) {
      try {
        // Use existing TaxPaymentsService to generate monthly summary
        const monthlySummary =
          await this.taxPaymentsService.generateMonthlySummary(
            userId,
            paymentYear,
            paymentMonth,
          );

        // The generateMonthlySummary method will create the tax payment entries
        // as part of its implementation
        console.log(
          `Tax submission data generated for user ${userId}: ${monthlySummary.totalDue} total due`,
        );
      } catch (error) {
        console.error(
          `Failed to generate tax submission for user ${userId}:`,
          error,
        );
        // Continue with other users even if one fails
      }
    }
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
      [PayPeriodStatus.COMPLETED]: [PayPeriodStatus.CLOSED],
      [PayPeriodStatus.CLOSED]: [], // No transitions from closed
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
        periodStart: payPeriod.startDate,
        periodEnd: payPeriod.endDate,
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
    };
  }

  async generatePayPeriods(
    userId: string,
    frequency: string,
    startDate: Date,
    endDate: Date,
  ): Promise<PayPeriod[]> {
    const periods: PayPeriod[] = [];
    const currentDate = new Date(startDate);
    const stepDays = this.getStepDays(frequency);

    while (currentDate <= endDate) {
      const periodEnd = new Date(currentDate);
      periodEnd.setDate(periodEnd.getDate() + stepDays - 1);

      if (periodEnd > endDate) break;

      const periodStart = new Date(currentDate);
      const name = this.generatePeriodName(periodStart, periodEnd, frequency);

      const payPeriod = this.payPeriodRepository.create({
        name,
        startDate: periodStart.toISOString().split('T')[0],
        endDate: periodEnd.toISOString().split('T')[0],
        frequency: frequency as PayPeriodFrequency,
        status: PayPeriodStatus.DRAFT,
        createdBy: userId,
      });

      periods.push(await this.payPeriodRepository.save(payPeriod));

      currentDate.setDate(currentDate.getDate() + stepDays);
    }

    return periods;
  }

  private getStepDays(frequency: string): number {
    const frequencyMap: Record<string, number> = {
      WEEKLY: 7,
      BIWEEKLY: 14,
      MONTHLY: 30,
      QUARTERLY: 90,
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
