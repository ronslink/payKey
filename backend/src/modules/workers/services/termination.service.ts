import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Worker } from '../entities/worker.entity';
import { Termination } from '../entities/termination.entity';
import { PayrollRecord, PayrollStatus } from '../../payroll/entities/payroll-record.entity';
import { PayPeriod, PayPeriodStatus, PayPeriodFrequency } from '../../payroll/entities/pay-period.entity';
import { TaxesService } from '../../taxes/taxes.service';
import {
  CreateTerminationDto,
  FinalPaymentCalculationDto,
  FinalPayMode,
} from '../dto/termination.dto';

@Injectable()
export class TerminationService {
  private readonly logger = new Logger(TerminationService.name);

  constructor(
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
    @InjectRepository(Termination)
    private terminationRepository: Repository<Termination>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    private taxesService: TaxesService,
    @InjectQueue('payroll-processing')
    private readonly payrollQueue: Queue,
  ) {}

  /**
   * Calculate final payment for a worker
   * Includes prorated salary and unused leave payout
   */
  async calculateFinalPayment(
    workerId: string,
    userId: string,
    terminationDate: Date,
  ): Promise<FinalPaymentCalculationDto> {
    const worker = await this.workerRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (!worker.isActive) {
      throw new BadRequestException('Worker is already terminated');
    }

    const grossSalary = Number(worker.salaryGross);

    if (!grossSalary || grossSalary <= 0) {
      throw new BadRequestException(
        'Worker has no gross salary configured. Please set the salary before terminating.',
      );
    }

    const termDate = terminationDate instanceof Date
      ? terminationDate
      : new Date(terminationDate as unknown as string);

    if (isNaN(termDate.getTime())) {
      throw new BadRequestException('Invalid termination date provided');
    }

    const year = termDate.getFullYear();
    const month = termDate.getMonth();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysWorked = termDate.getDate();
    const dailyRate = grossSalary / daysInMonth;
    const proratedSalary = dailyRate * daysWorked;

    const unusedLeaveDays = Math.max(0, worker.leaveBalance || 0);
    const leavePayoutRate = dailyRate;
    const unusedLeavePayout = unusedLeaveDays * leavePayoutRate;

    const severancePay = 0;
    const totalGross = proratedSalary + unusedLeavePayout + severancePay;

    const taxCalculation = await this.taxesService.calculatePayroll(
      worker.id,
      worker.name,
      totalGross,
    );

    const totalNet = Math.max(0, taxCalculation.netPay);

    return {
      proratedSalary: Math.round(proratedSalary * 100) / 100,
      unusedLeavePayout: Math.round(unusedLeavePayout * 100) / 100,
      severancePay: Math.round(severancePay * 100) / 100,
      totalGross: Math.round(totalGross * 100) / 100,
      taxDeductions: {
        nssf: taxCalculation.taxBreakdown.nssf,
        nhif: taxCalculation.taxBreakdown.nhif,
        housingLevy: taxCalculation.taxBreakdown.housingLevy,
        paye: taxCalculation.taxBreakdown.paye,
        total: taxCalculation.taxBreakdown.totalDeductions,
      },
      totalNet,
      breakdown: {
        daysWorked,
        totalDaysInMonth: daysInMonth,
        dailyRate: Math.round(dailyRate * 100) / 100,
        unusedLeaveDays,
        leavePayoutRate: Math.round(leavePayoutRate * 100) / 100,
      },
    };
  }

  /**
   * Terminate a worker and create termination record.
   * final pay is handled according to dto.finalPayMode:
   *   - immediate_offcycle (default): create off-cycle PayPeriod + enqueue finalize job
   *   - include_in_regular: write DRAFT PayrollRecord into current active period
   *   - defer: skip PayrollRecord creation entirely
   */
  async terminateWorker(
    workerId: string,
    userId: string,
    dto: CreateTerminationDto,
  ): Promise<Termination> {
    const worker = await this.workerRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (!worker.isActive) {
      throw new BadRequestException('Worker is already terminated');
    }

    const terminationDate = new Date(dto.terminationDate);
    if (isNaN(terminationDate.getTime())) {
      throw new BadRequestException('Invalid termination date provided');
    }

    const finalPayment = await this.calculateFinalPayment(workerId, userId, terminationDate);

    const severancePay = dto.severancePay ?? 0;
    const outstandingPayments = dto.outstandingPayments ?? 0;
    const totalGross =
      finalPayment.proratedSalary +
      finalPayment.unusedLeavePayout +
      severancePay +
      outstandingPayments;

    const taxCalculation = await this.taxesService.calculatePayroll(
      worker.id,
      worker.name,
      totalGross,
    );

    const finalPayMode = dto.finalPayMode ?? FinalPayMode.IMMEDIATE_OFFCYCLE;

    // -------------------------------------------------------------------------
    // Handle final pay record based on employer's chosen mode
    // -------------------------------------------------------------------------
    if (finalPayMode === FinalPayMode.DEFER) {
      // Employer will handle payment manually — no payroll record created
      this.logger.log(
        `Termination deferred pay for worker ${workerId}. No PayrollRecord created.`,
      );
    } else if (finalPayMode === FinalPayMode.INCLUDE_IN_REGULAR) {
      // Write a DRAFT record into the current/next active regular period.
      // The normal payroll run will pick it up.
      const activePeriod = await this.payPeriodRepository
        .createQueryBuilder('period')
        .where('period.userId = :userId', { userId })
        .andWhere('period.isOffCycle = :isOffCycle', { isOffCycle: false })
        .andWhere('period.status IN (:...statuses)', {
          statuses: [PayPeriodStatus.DRAFT, PayPeriodStatus.ACTIVE],
        })
        .orderBy('period.startDate', 'ASC')
        .getOne();

      if (!activePeriod) {
        throw new BadRequestException(
          'No active or draft pay period found. Cannot include final pay in regular payroll. ' +
          'Please create a pay period first or choose a different final pay mode.',
        );
      }

      let payrollRecord = await this.payrollRecordRepository.findOne({
        where: { payPeriodId: activePeriod.id, workerId, userId },
      });

      if (!payrollRecord) {
        payrollRecord = this.payrollRecordRepository.create({
          payPeriodId: activePeriod.id,
          workerId,
          userId,
          periodStart: activePeriod.startDate,
          periodEnd: activePeriod.endDate,
        });
      }

      payrollRecord.grossSalary = totalGross;
      payrollRecord.netSalary = Math.max(0, taxCalculation.netPay);
      payrollRecord.taxAmount = taxCalculation.taxBreakdown.paye;
      payrollRecord.taxBreakdown = {
        nssf: taxCalculation.taxBreakdown.nssf,
        nhif: taxCalculation.taxBreakdown.nhif,
        housingLevy: taxCalculation.taxBreakdown.housingLevy,
        paye: taxCalculation.taxBreakdown.paye,
        totalDeductions: taxCalculation.taxBreakdown.totalDeductions,
      };
      payrollRecord.otherEarnings = severancePay + outstandingPayments;
      payrollRecord.deductions = {};
      // Leave as DRAFT so it's processed by the next payroll run
      payrollRecord.status = PayrollStatus.DRAFT;

      await this.payrollRecordRepository.save(payrollRecord);
      this.logger.log(
        `Final pay for worker ${workerId} added as DRAFT to period ${activePeriod.id} (include_in_regular)`,
      );
    } else {
      // IMMEDIATE_OFFCYCLE (default): create an off-cycle PayPeriod and enqueue finalization
      const termEndOfMonth = new Date(
        terminationDate.getFullYear(),
        terminationDate.getMonth() + 1,
        0,
      );
      const terminationDateStr = this.formatDate(terminationDate);
      const endOfMonthStr = this.formatDate(termEndOfMonth);

      const offCyclePeriod = this.payPeriodRepository.create({
        name: `Final Pay — ${worker.name} (${terminationDateStr})`,
        startDate: terminationDateStr as unknown as Date,
        endDate: endOfMonthStr as unknown as Date,
        payDate: terminationDateStr as unknown as Date,
        frequency: PayPeriodFrequency.MONTHLY,
        status: PayPeriodStatus.ACTIVE,
        isOffCycle: true,
        userId,
        createdBy: userId,
        notes: { comments: `Auto-created for final pay of terminated worker ${worker.name}` },
      });

      const savedPeriod = (await this.payPeriodRepository.save(
        offCyclePeriod,
      )) as PayPeriod;

      // Write the PayrollRecord into the new off-cycle period as DRAFT
      const payrollRecord = this.payrollRecordRepository.create({
        payPeriodId: savedPeriod.id,
        workerId,
        userId,
        periodStart: savedPeriod.startDate,
        periodEnd: savedPeriod.endDate,
        grossSalary: totalGross,
        netSalary: Math.max(0, taxCalculation.netPay),
        taxAmount: taxCalculation.taxBreakdown.paye,
        taxBreakdown: {
          nssf: taxCalculation.taxBreakdown.nssf,
          nhif: taxCalculation.taxBreakdown.nhif,
          housingLevy: taxCalculation.taxBreakdown.housingLevy,
          paye: taxCalculation.taxBreakdown.paye,
          totalDeductions: taxCalculation.taxBreakdown.totalDeductions,
        },
        otherEarnings: severancePay + outstandingPayments,
        deductions: {},
        status: PayrollStatus.DRAFT,
      });

      await this.payrollRecordRepository.save(payrollRecord);

      // Enqueue the finalization job for this worker only (skipPayout: false)
      await this.payrollQueue.add(
        'finalize-payroll',
        {
          userId,
          payPeriodId: savedPeriod.id,
          skipPayout: false,
          workerIds: [workerId],
        },
        {
          attempts: 1,
          removeOnComplete: false,
          removeOnFail: false,
        },
      );

      this.logger.log(
        `Off-cycle period ${savedPeriod.id} created and finalize-payroll job enqueued for worker ${workerId}`,
      );
    }

    // -------------------------------------------------------------------------
    // Create termination record and deactivate the worker
    // -------------------------------------------------------------------------
    const termination = this.terminationRepository.create({
      workerId,
      userId,
      reason: dto.reason,
      terminationDate,
      lastWorkingDate: dto.lastWorkingDate
        ? new Date(dto.lastWorkingDate)
        : terminationDate,
      noticePeriodDays: dto.noticePeriodDays || 0,
      notes: dto.notes,
      proratedSalary: finalPayment.proratedSalary,
      unusedLeavePayout: finalPayment.unusedLeavePayout,
      severancePay,
      totalFinalPayment: Math.max(0, taxCalculation.netPay),
      paymentBreakdown: {
        ...finalPayment.breakdown,
        severancePay,
        outstandingPayments,
      },
    });

    const savedTermination = (await this.terminationRepository.save(
      termination,
    )) as Termination;

    worker.isActive = false;
    worker.terminatedAt = terminationDate;
    worker.terminationId = savedTermination.id;
    await this.workerRepository.save(worker);

    // Generate tax submission if we created a regular payroll record
    if (finalPayMode === FinalPayMode.INCLUDE_IN_REGULAR) {
      try {
        const activePeriod = await this.payPeriodRepository
          .createQueryBuilder('period')
          .where('period.userId = :userId', { userId })
          .andWhere('period.isOffCycle = :isOffCycle', { isOffCycle: false })
          .andWhere('period.status IN (:...statuses)', {
            statuses: [PayPeriodStatus.DRAFT, PayPeriodStatus.ACTIVE],
          })
          .orderBy('period.startDate', 'ASC')
          .getOne();
        if (activePeriod) {
          await this.taxesService.generateTaxSubmission(activePeriod.id, userId);
        }
      } catch (e) {
        this.logger.warn('Failed to update tax submission after termination:', e);
      }
    }

    return savedTermination;
  }

  /**
   * Get termination history for a user
   */
  async getTerminationHistory(userId: string): Promise<Termination[]> {
    return this.terminationRepository.find({
      where: { userId },
      relations: ['worker'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get termination details by ID
   */
  async getTermination(id: string, userId: string): Promise<Termination> {
    const termination = await this.terminationRepository.findOne({
      where: { id, userId },
      relations: ['worker'],
    });

    if (!termination) {
      throw new NotFoundException('Termination record not found');
    }

    return termination;
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}
