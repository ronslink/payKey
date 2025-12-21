import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import {
  Repository,
  MoreThanOrEqual,
  Between,
  DataSource,
  In,
  EntityManager,
} from 'typeorm';

import { ActivitiesService } from '../activities/activities.service';
import { ActivityType } from '../activities/entities/activity.entity';
import { PayrollPaymentService } from '../payments/payroll-payment.service';
import { TaxesService } from '../taxes/taxes.service';
import { User } from '../users/entities/user.entity';
import { LeaveRequest, LeaveStatus, LeaveType } from '../workers/entities/leave-request.entity';
import { Worker, EmploymentType } from '../workers/entities/worker.entity';
import { PayPeriod, PayPeriodStatus } from './entities/pay-period.entity';
import { TimeEntry, TimeEntryStatus } from '../time-tracking/entities/time-entry.entity';
import { PayrollRecord, PayrollStatus } from './entities/payroll-record.entity';
import { PayslipService } from './payslip.service';

// =============================================================================
// Types & Interfaces
// =============================================================================

interface TaxBreakdown {
  nssf: number;
  nhif: number;
  housingLevy: number;
  paye: number;
  totalDeductions: number;
}

interface PayrollItem {
  workerId: string;
  workerName: string;
  grossSalary: number;
  originalGross?: number;
  leaveDeduction?: number;
  unpaidLeaveDays?: number;
  taxBreakdown: TaxBreakdown;
  netPay: number;
  phoneNumber: string;
  error?: string;
}

interface PayrollSummary {
  totalGross: number;
  totalDeductions: number;
  totalNetPay: number;
  workerCount: number;
}

interface PayrollCalculationResult {
  payrollItems: PayrollItem[];
  summary: PayrollSummary;
}

interface AdjustedSalaryResult {
  adjustedGross: number;
  deduction: number;
  leaveDays: number;
}

interface DraftPayrollItem {
  workerId: string;
  grossSalary: number;
  bonuses?: number;
  otherEarnings?: number;
  otherDeductions?: number;
}

interface DraftPayrollUpdateInput {
  grossSalary?: number;
  bonuses?: number;
  otherEarnings?: number;
  otherDeductions?: number;
  holidayHours?: number;
  sundayHours?: number;
}

interface FundsVerificationResult {
  requiredAmount: number;
  availableBalance: number;
  canProceed: boolean;
  shortfall: number;
  workerCount: number;
}

// =============================================================================
// Constants
// =============================================================================

const BATCH_CHUNK_SIZE = 50;
const SAVE_BATCH_SIZE = 100;
const DAYS_IN_MONTH = 30;
const HOURS_PER_DAY = 8;
const STANDARD_MONTHLY_HOURS = 208; // 26 days * 8 hours
const HOLIDAY_OVERTIME_RATE = 1.5;
const SUNDAY_OVERTIME_RATE = 2.0;

// =============================================================================
// Service
// =============================================================================

@Injectable()
export class PayrollService {
  private readonly logger = new Logger(PayrollService.name);

  constructor(
    @InjectRepository(Worker)
    private readonly workersRepository: Repository<Worker>,
    @InjectRepository(PayrollRecord)
    private readonly payrollRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private readonly payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(LeaveRequest)
    private readonly leaveRepository: Repository<LeaveRequest>,
    @InjectRepository(TimeEntry)
    private readonly timeEntryRepository: Repository<TimeEntry>,
    private readonly taxesService: TaxesService,
    private readonly payrollPaymentService: PayrollPaymentService,
    private readonly activitiesService: ActivitiesService,
    private readonly dataSource: DataSource,
    private readonly payslipService: PayslipService,
  ) { }

  // ===========================================================================
  // Public Methods - Payroll Calculation
  // ===========================================================================

  /**
   * Calculate payroll for all active workers belonging to a user.
   */
  async calculatePayrollForUser(userId: string): Promise<PayrollCalculationResult> {
    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const { year, month } = this.getCurrentPeriod();

    const payrollItems = await Promise.all(
      workers.map((worker) => this.calculateWorkerPayroll(worker, { year, month })),
    );

    return {
      payrollItems,
      summary: this.calculateSummary(payrollItems),
    };
  }

  /**
   * Optimized batch calculation for multiple workers.
   * Uses parallel processing with chunking to avoid memory issues.
   */
  async calculatePayrollBatch(
    userId: string,
    workerIds: string[],
  ): Promise<PayrollCalculationResult> {
    const startTime = Date.now();
    this.logger.log(`Starting batch payroll calculation for ${workerIds.length} workers`);

    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const selectedWorkers = workerIds.length > 0
      ? workers.filter((w) => workerIds.includes(w.id))
      : workers;

    if (selectedWorkers.length === 0) {
      throw new NotFoundException('No workers found');
    }

    const { year, month } = this.getCurrentPeriod();
    const payrollItems = await this.processWorkersInChunks(selectedWorkers, { year, month });

    this.logBatchDuration('Batch payroll calculation', startTime, selectedWorkers.length);

    return {
      payrollItems,
      summary: this.calculateSummary(payrollItems),
    };
  }

  /**
   * Calculate payroll for a single worker.
   */
  async calculateSingleWorkerPayroll(workerId: string, userId: string) {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    const grossSalary = this.parseNumber(worker.salaryGross);

    if (isNaN(grossSalary) || grossSalary <= 0) {
      throw new BadRequestException(`Invalid salary amount for worker: ${worker.salaryGross}`);
    }

    const taxBreakdown = await this.taxesService.calculateTaxes(grossSalary);
    const netPay = this.roundCurrency(grossSalary - taxBreakdown.totalDeductions);

    return {
      worker,
      payrollCalculation: {
        grossSalary,
        taxBreakdown,
        netPay,
      },
    };
  }

  /**
   * Calculate adjusted salary based on leave (paid and unpaid).
   */
  async calculateAdjustedSalary(
    worker: Worker,
    period: { year: number; month: number } | { payPeriodId: string },
  ): Promise<AdjustedSalaryResult> {
    const { startDate, endDate } = await this.resolvePeriodDates(period);
    const leaveRequests = await this.fetchApprovedLeave(worker.id);
    const overlappingRequests = this.filterOverlappingLeave(leaveRequests, startDate, endDate);

    const { unpaidDays, paidDays } = this.calculateLeaveDays(
      overlappingRequests,
      startDate,
      endDate,
    );

    let adjustedGross = 0;
    let deduction = 0;

    if (worker.employmentType === EmploymentType.HOURLY) {
      // HOURLY: Calculate from Time Entries + Paid Leave
      const hourlyRate = this.parseNumber(worker.hourlyRate) || 0;

      // Fetch valid time entries
      const timeEntries = await this.timeEntryRepository.find({
        where: {
          workerId: worker.id,
          clockIn: Between(startDate, endDate),
          status: In([TimeEntryStatus.COMPLETED, TimeEntryStatus.ADJUSTED])
        }
      });

      const totalWorkedHours = timeEntries.reduce((sum, entry) => sum + (Number(entry.totalHours) || 0), 0);
      const paidLeaveHours = paidDays * HOURS_PER_DAY;

      adjustedGross = (totalWorkedHours + paidLeaveHours) * hourlyRate;
      deduction = 0; // Deductions irrelevant as we build from 0

      // If NO hours recorded and NO leave, check if we should fallback?
      // For now, 0 hours = 0 pay.

    } else {
      // FIXED: Monthly Salary - Unpaid Leave + Paid Hours? (Usually fixed is fixed)
      const grossSalary = this.parseNumber(worker.salaryGross);
      deduction = this.calculateLeaveDeduction(grossSalary, unpaidDays);
      const addition = this.calculatePaidLeaveAddition(worker, paidDays);
      adjustedGross = Math.max(0, grossSalary - deduction + addition);
    }

    return {
      adjustedGross: this.roundCurrency(adjustedGross),
      deduction: this.roundCurrency(deduction),
      leaveDays: unpaidDays + paidDays,
    };
  }

  // ===========================================================================
  // Public Methods - Draft Payroll Management
  // ===========================================================================

  /**
   * Save draft payroll with optimized batch processing.
   * Uses transactions and bulk operations for better performance.
   */
  async saveDraftPayroll(
    userId: string,
    payPeriodId: string,
    items: DraftPayrollItem[],
  ): Promise<PayrollRecord[]> {
    const startTime = Date.now();
    this.logger.log(`Saving ${items.length} draft payroll records`);

    const payPeriod = await this.getPayPeriodOrThrow(payPeriodId);
    this.validatePayPeriodModifiable(payPeriod);

    const periodStart = new Date(payPeriod.startDate);
    const periodEnd = new Date(payPeriod.endDate);

    const savedRecords = await this.dataSource.transaction(async (manager) => {
      return this.processDraftItemsInBatches(
        manager,
        userId,
        payPeriodId,
        items,
        periodStart,
        periodEnd,
      );
    });

    this.logBatchDuration('Draft payroll save', startTime, savedRecords.length);

    return savedRecords;
  }

  /**
   * Update a single draft payroll item.
   */
  async updateDraftPayrollItem(
    userId: string,
    recordId: string,
    updates: DraftPayrollUpdateInput,
  ): Promise<PayrollRecord> {
    const record = await this.payrollRepository.findOne({
      where: { id: recordId, userId, status: PayrollStatus.DRAFT },
    });

    if (!record) {
      throw new NotFoundException('Draft payroll record not found');
    }

    this.applyRecordUpdates(record, updates);

    const worker = await this.workersRepository.findOne({
      where: { id: record.workerId },
    });

    const overtimePay = this.calculateOvertimePay(record, worker);
    record.overtimePay = overtimePay;

    await this.recalculateRecordTotals(record, overtimePay);

    return this.payrollRepository.save(record);
  }

  /**
   * Get all draft payroll records for a pay period.
   */
  async getDraftPayroll(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: { userId, payPeriodId, status: PayrollStatus.DRAFT },
      relations: ['worker'],
    });

    return this.transformRecords(records);
  }

  /**
   * Get all payroll records for a pay period (any status).
   */
  async getPeriodRecords(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: { userId, payPeriodId },
      relations: ['worker'],
    });

    return this.transformRecords(records);
  }

  // ===========================================================================
  // Public Methods - Payroll Finalization
  // ===========================================================================

  /**
   * Finalize payroll with optimized batch processing.
   * Generates payslips, processes payments, and creates tax submissions.
   */
  async finalizePayroll(userId: string, payPeriodId: string) {
    const startTime = Date.now();
    this.logger.log(`Finalizing payroll for period ${payPeriodId}`);

    const records = await this.payrollRepository.find({
      where: { userId, payPeriodId, status: PayrollStatus.DRAFT },
      relations: ['worker', 'payPeriod'],
    });

    if (records.length === 0) {
      throw new NotFoundException('No draft payroll records found for this period');
    }

    const employerName = await this.getEmployerName(userId);
    const updatedRecords = await this.markRecordsAsFinalized(records);

    const [payslipResults, payoutResults] = await Promise.all([
      this.generatePayslipsAsync(updatedRecords, employerName),
      this.processPayoutsAsync(updatedRecords),
    ]);

    await this.generateTaxSubmissionSafe(payPeriodId, userId);

    const totalAmount = this.sumNetSalaries(updatedRecords);
    const payslipsGenerated = payslipResults.success ? payslipResults.count : 0;

    await this.logFinalizationActivity(
      userId,
      payPeriodId,
      updatedRecords.length,
      totalAmount,
      payoutResults,
      payslipsGenerated,
    );

    const totalDuration = Date.now() - startTime;
    this.logger.log(
      `Payroll finalization completed in ${totalDuration}ms: ` +
      `${updatedRecords.length} records, ${payoutResults.successCount} payments, ` +
      `${payslipsGenerated} payslips`,
    );

    return {
      finalizedRecords: updatedRecords,
      payoutResults,
      payslipResults,
      summary: {
        totalRecords: updatedRecords.length,
        paymentsSuccessful: payoutResults.successCount,
        paymentsFailed: payoutResults.failureCount,
        payslipsGenerated,
        totalAmount,
        duration: totalDuration,
      },
    };
  }

  // ===========================================================================
  // Public Methods - Payroll Statistics & History
  // ===========================================================================

  /**
   * Get payroll statistics for the current and previous month.
   */
  async getPayrollStats(userId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    const [thisMonthRecords, lastMonthRecords] = await Promise.all([
      this.payrollRepository.find({
        where: {
          userId,
          status: PayrollStatus.FINALIZED,
          periodEnd: MoreThanOrEqual(startOfMonth),
        },
      }),
      this.payrollRepository.find({
        where: {
          userId,
          status: PayrollStatus.FINALIZED,
          periodEnd: Between(startOfLastMonth, endOfLastMonth),
        },
      }),
    ]);

    const thisMonthTotal = this.sumNetSalaries(thisMonthRecords);
    const lastMonthTotal = this.sumNetSalaries(lastMonthRecords);
    const trend = thisMonthTotal - lastMonthTotal;

    return {
      thisMonthTotal,
      lastMonthTotal,
      trend: trend >= 0 ? `+${trend}` : `${trend}`,
      trendUp: trend >= 0,
      processedCount: thisMonthRecords.length,
    };
  }

  /**
   * Get payslips for an employee (self-service or by worker ID).
   */
  async getEmployeePayslips(userId: string, workerId?: string) {
    const resolvedWorkerId = await this.resolveWorkerId(userId, workerId);

    return this.payrollRepository.find({
      where: { workerId: resolvedWorkerId, status: PayrollStatus.FINALIZED },
      relations: ['payPeriod'],
      order: { periodStart: 'DESC' },
    });
  }

  /**
   * Generate PDF payslip for an employee.
   */
  async getEmployeePayslipPdf(userId: string, recordId: string, workerId?: string) {
    const resolvedWorkerId = await this.resolveWorkerId(userId, workerId);

    const record = await this.payrollRepository.findOne({
      where: {
        id: recordId,
        workerId: resolvedWorkerId,
        status: PayrollStatus.FINALIZED,
      },
      relations: ['worker', 'payPeriod'],
    });

    if (!record) {
      throw new NotFoundException('Payslip not found');
    }

    return this.payslipService.generatePayslip(record);
  }

  /**
   * Get payroll history for a specific worker.
   */
  async getWorkerPayrollHistory(userId: string, workerId: string) {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new ForbiddenException('Worker not found or access denied');
    }

    return this.payrollRepository.find({
      where: {
        workerId: worker.id,
        status: In([PayrollStatus.FINALIZED, PayrollStatus.PAID]),
      },
      relations: ['payPeriod'],
      order: { periodStart: 'DESC' },
    });
  }

  /**
   * Verify if user has sufficient wallet balance to process payroll.
   */
  async verifyFundsForPeriod(
    userId: string,
    payPeriodId: string,
  ): Promise<FundsVerificationResult> {
    const userResult = await this.dataSource
      .createQueryBuilder()
      .select(['id', '"walletBalance"'])
      .from('users', 'u')
      .where('u.id = :userId', { userId })
      .getRawOne();

    if (!userResult) {
      throw new NotFoundException('User not found');
    }

    const walletBalance = parseFloat(userResult.walletBalance) || 0;

    const records = await this.payrollRepository.find({
      where: {
        payPeriodId,
        userId,
        status: In([PayrollStatus.FINALIZED, PayrollStatus.DRAFT]),
      },
    });

    const totalNetPay = records.reduce(
      (sum, r) => sum + (parseFloat(r.netSalary as any) || 0),
      0,
    );

    return {
      requiredAmount: totalNetPay,
      availableBalance: walletBalance,
      canProceed: walletBalance >= totalNetPay,
      shortfall: Math.max(0, totalNetPay - walletBalance),
      workerCount: records.length,
    };
  }

  // ===========================================================================
  // Private Methods - Payroll Calculation Helpers
  // ===========================================================================

  private async calculateWorkerPayroll(
    worker: Worker,
    period: { year: number; month: number },
  ): Promise<PayrollItem> {
    try {
      const { adjustedGross, deduction, leaveDays } =
        await this.calculateAdjustedSalary(worker, period);

      if (adjustedGross <= 0 && deduction === 0) {
        const originalGross = this.parseNumber(worker.salaryGross);
        if (isNaN(originalGross) || originalGross <= 0) {
          return this.createErrorPayrollItem(worker, 'Invalid salary amount');
        }
      }

      const taxBreakdown = await this.taxesService.calculateTaxes(adjustedGross);
      const netPay = this.roundCurrency(adjustedGross - taxBreakdown.totalDeductions);

      return {
        workerId: worker.id,
        workerName: worker.name,
        grossSalary: adjustedGross,
        originalGross: this.parseNumber(worker.salaryGross),
        leaveDeduction: deduction,
        unpaidLeaveDays: leaveDays,
        taxBreakdown,
        netPay,
        phoneNumber: worker.phoneNumber,
      };
    } catch (error) {
      this.logger.error(`Error calculating payroll for worker ${worker.id}:`, error);
      return this.createErrorPayrollItem(worker, error.message || 'Failed to calculate taxes');
    }
  }

  private createErrorPayrollItem(worker: Worker, error: string): PayrollItem {
    return {
      workerId: worker.id,
      workerName: worker.name,
      grossSalary: this.parseNumber(worker.salaryGross) || 0,
      taxBreakdown: this.createEmptyTaxBreakdown(),
      netPay: 0,
      phoneNumber: worker.phoneNumber,
      error,
    };
  }

  private createEmptyTaxBreakdown(): TaxBreakdown {
    return {
      nssf: 0,
      nhif: 0,
      housingLevy: 0,
      paye: 0,
      totalDeductions: 0,
    };
  }

  private async processWorkersInChunks(
    workers: Worker[],
    period: { year: number; month: number },
  ): Promise<PayrollItem[]> {
    const payrollItems: PayrollItem[] = [];

    for (let i = 0; i < workers.length; i += BATCH_CHUNK_SIZE) {
      const chunk = workers.slice(i, i + BATCH_CHUNK_SIZE);
      const chunkResults = await Promise.all(
        chunk.map((worker) => this.calculateWorkerPayroll(worker, period)),
      );
      payrollItems.push(...chunkResults);
    }

    return payrollItems;
  }

  private calculateSummary(items: PayrollItem[]): PayrollSummary {
    const totalGross = items.reduce((sum, item) => sum + (item.grossSalary || 0), 0);
    const totalDeductions = items.reduce(
      (sum, item) => sum + (item.taxBreakdown?.totalDeductions || 0),
      0,
    );
    const totalNetPay = items.reduce((sum, item) => sum + (item.netPay || 0), 0);

    return {
      totalGross: this.roundCurrency(totalGross),
      totalDeductions: this.roundCurrency(totalDeductions),
      totalNetPay: this.roundCurrency(totalNetPay),
      workerCount: items.length,
    };
  }

  // ===========================================================================
  // Private Methods - Leave Calculation Helpers
  // ===========================================================================

  private async resolvePeriodDates(
    period: { year: number; month: number } | { payPeriodId: string },
  ): Promise<{ startDate: Date; endDate: Date }> {
    if ('payPeriodId' in period) {
      const payPeriod = await this.payPeriodRepository.findOne({
        where: { id: period.payPeriodId },
      });
      if (!payPeriod) {
        throw new NotFoundException('Pay period not found');
      }
      return {
        startDate: new Date(payPeriod.startDate),
        endDate: new Date(payPeriod.endDate),
      };
    }

    return {
      startDate: new Date(period.year, period.month - 1, 1),
      endDate: new Date(period.year, period.month, 0),
    };
  }

  private async fetchApprovedLeave(workerId: string): Promise<LeaveRequest[]> {
    return this.leaveRepository.find({
      where: { workerId, status: LeaveStatus.APPROVED },
    });
  }

  private filterOverlappingLeave(
    requests: LeaveRequest[],
    startDate: Date,
    endDate: Date,
  ): LeaveRequest[] {
    return requests.filter((req) => {
      const reqStart = new Date(req.startDate);
      const reqEnd = new Date(req.endDate);
      return reqStart <= endDate && reqEnd >= startDate;
    });
  }

  private calculateLeaveDays(
    requests: LeaveRequest[],
    periodStart: Date,
    periodEnd: Date,
  ): { unpaidDays: number; paidDays: number } {
    let unpaidDays = 0;
    let paidDays = 0;

    for (const req of requests) {
      const reqStart = new Date(req.startDate);
      const reqEnd = new Date(req.endDate);

      const start = reqStart > periodStart ? reqStart : periodStart;
      const end = reqEnd < periodEnd ? reqEnd : periodEnd;

      const days = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;

      if (days > 0) {
        if (req.leaveType === LeaveType.UNPAID || req.paidLeave === false) {
          unpaidDays += days;
        } else {
          paidDays += days;
        }
      }
    }

    return { unpaidDays, paidDays };
  }

  private calculateLeaveDeduction(grossSalary: number, unpaidDays: number): number {
    if (unpaidDays <= 0) return 0;
    const dailyRate = grossSalary / DAYS_IN_MONTH;
    return this.roundCurrency(dailyRate * unpaidDays);
  }

  private calculatePaidLeaveAddition(worker: Worker, paidDays: number): number {
    if (worker.employmentType !== EmploymentType.HOURLY || paidDays <= 0) {
      return 0;
    }

    const hourlyRate = this.parseNumber(worker.hourlyRate);
    if (!hourlyRate) return 0;

    return this.roundCurrency(paidDays * HOURS_PER_DAY * hourlyRate);
  }

  // ===========================================================================
  // Private Methods - Draft Payroll Helpers
  // ===========================================================================

  private async processDraftItemsInBatches(
    manager: EntityManager,
    userId: string,
    payPeriodId: string,
    items: DraftPayrollItem[],
    periodStart: Date,
    periodEnd: Date,
  ): Promise<PayrollRecord[]> {
    const results: PayrollRecord[] = [];

    for (let i = 0; i < items.length; i += SAVE_BATCH_SIZE) {
      const batch = items.slice(i, i + SAVE_BATCH_SIZE);
      const batchPromises = batch.map((item) =>
        this.processDraftItem(manager, userId, payPeriodId, item, periodStart, periodEnd),
      );

      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);
    }

    return results;
  }

  private async processDraftItem(
    manager: EntityManager,
    userId: string,
    payPeriodId: string,
    item: DraftPayrollItem,
    periodStart: Date,
    periodEnd: Date,
  ): Promise<PayrollRecord> {
    const totalEarnings = item.grossSalary + (item.bonuses || 0) + (item.otherEarnings || 0);
    const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);
    const totalDeductions = taxBreakdown.totalDeductions + (item.otherDeductions || 0);
    const netPay = totalEarnings - totalDeductions;

    let record = await manager.findOne(PayrollRecord, {
      where: { userId, payPeriodId, workerId: item.workerId },
    });

    if (record) {
      if (record.status !== PayrollStatus.DRAFT) {
        throw new BadRequestException(
          `Payroll record for worker ${item.workerId} is already ${record.status} and cannot be modified.`,
        );
      }
    } else {
      record = new PayrollRecord();
      record.userId = userId;
      record.payPeriodId = payPeriodId;
      record.workerId = item.workerId;
      record.status = PayrollStatus.DRAFT;
      record.periodStart = periodStart;
      record.periodEnd = periodEnd;
    }

    record.grossSalary = item.grossSalary;
    record.bonuses = item.bonuses || 0;
    record.otherEarnings = item.otherEarnings || 0;
    record.otherDeductions = item.otherDeductions || 0;
    record.taxAmount = taxBreakdown.paye;
    record.netSalary = netPay;
    record.taxBreakdown = taxBreakdown;
    record.deductions = {
      ...taxBreakdown,
      otherDeductions: item.otherDeductions || 0,
    };

    return manager.save(PayrollRecord, record);
  }

  private applyRecordUpdates(record: PayrollRecord, updates: DraftPayrollUpdateInput): void {
    if (updates.grossSalary !== undefined) record.grossSalary = updates.grossSalary;
    if (updates.bonuses !== undefined) record.bonuses = updates.bonuses;
    if (updates.otherEarnings !== undefined) record.otherEarnings = updates.otherEarnings;
    if (updates.otherDeductions !== undefined) record.otherDeductions = updates.otherDeductions;
    if (updates.holidayHours !== undefined) record.holidayHours = updates.holidayHours;
    if (updates.sundayHours !== undefined) record.sundayHours = updates.sundayHours;
  }

  private calculateOvertimePay(record: PayrollRecord, worker: Worker | null): number {
    if (!worker) return 0;

    let hourlyRate: number;
    if (worker.employmentType === EmploymentType.HOURLY) {
      hourlyRate = this.parseNumber(worker.hourlyRate) || 0;
    } else {
      hourlyRate = this.parseNumber(record.grossSalary) / STANDARD_MONTHLY_HOURS;
    }

    const holidayPay = hourlyRate * HOLIDAY_OVERTIME_RATE * this.parseNumber(record.holidayHours);
    const sundayPay = hourlyRate * SUNDAY_OVERTIME_RATE * this.parseNumber(record.sundayHours);

    return holidayPay + sundayPay;
  }

  private async recalculateRecordTotals(
    record: PayrollRecord,
    overtimePay: number,
  ): Promise<void> {
    const totalEarnings =
      this.parseNumber(record.grossSalary) +
      this.parseNumber(record.bonuses) +
      this.parseNumber(record.otherEarnings) +
      overtimePay;

    const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);
    const totalDeductions = taxBreakdown.totalDeductions + this.parseNumber(record.otherDeductions);

    record.taxAmount = taxBreakdown.paye;
    record.netSalary = totalEarnings - totalDeductions;
    record.taxBreakdown = taxBreakdown;
    record.deductions = {
      ...taxBreakdown,
      otherDeductions: record.otherDeductions,
    };
  }

  private transformRecords(records: PayrollRecord[]) {
    return records.map((record) => ({
      id: record.id,
      workerId: record.workerId,
      workerName: record.worker.name,
      grossSalary: this.parseNumber(record.grossSalary),
      bonuses: this.parseNumber(record.bonuses),
      otherEarnings: this.parseNumber(record.otherEarnings),
      otherDeductions: this.parseNumber(record.otherDeductions),
      taxBreakdown: record.taxBreakdown,
      netPay: this.parseNumber(record.netSalary),
      status: record.status,
    }));
  }

  // ===========================================================================
  // Private Methods - Finalization Helpers
  // ===========================================================================

  private async markRecordsAsFinalized(records: PayrollRecord[]): Promise<PayrollRecord[]> {
    const finalizedDate = new Date();

    return this.dataSource.transaction(async (manager) => {
      const updates = records.map(async (record) => {
        record.status = PayrollStatus.FINALIZED;
        record.finalizedAt = finalizedDate;
        return manager.save(PayrollRecord, record);
      });

      return Promise.all(updates);
    });
  }

  private async generatePayslipsAsync(
    records: PayrollRecord[],
    employerName: string,
  ): Promise<{ success: boolean; count: number; error?: string }> {
    this.logger.log('Starting payslip generation...');

    try {
      const payslips = await this.payslipService.generatePayslipsBatch(records, employerName);
      this.logger.log(`Generated ${payslips.length} payslips successfully`);
      return { success: true, count: payslips.length };
    } catch (error) {
      this.logger.error('Failed to generate payslips:', error);
      return { success: false, count: 0, error: error.message };
    }
  }

  private async processPayoutsAsync(records: PayrollRecord[]) {
    this.logger.log('Starting M-Pesa payout processing...');

    try {
      const results = await this.payrollPaymentService.processPayouts(records);
      this.logger.log(
        `Payouts processed: ${results.successCount} successful, ${results.failureCount} failed`,
      );
      return results;
    } catch (error) {
      this.logger.error('Failed to process payouts:', error);
      return {
        successCount: 0,
        failureCount: records.length,
        results: [],
        error: error.message,
      };
    }
  }

  private async generateTaxSubmissionSafe(payPeriodId: string, userId: string): Promise<void> {
    try {
      this.logger.log('Generating tax submission...');
      await this.taxesService.generateTaxSubmission(payPeriodId, userId);
      this.logger.log('Tax submission generated successfully');
    } catch (error) {
      this.logger.error('Failed to generate tax submission:', error);
    }
  }

  private async logFinalizationActivity(
    userId: string,
    payPeriodId: string,
    workerCount: number,
    totalAmount: number,
    payoutResults: { successCount: number; failureCount: number },
    payslipsGenerated: number,
  ): Promise<void> {
    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.PAYROLL,
        'Payroll Finalized',
        `Finalized payroll for ${workerCount} workers. ` +
        `Payments: ${payoutResults.successCount} successful, ${payoutResults.failureCount} failed. ` +
        `Payslips: ${payslipsGenerated} generated.`,
        {
          workerCount,
          totalAmount,
          payPeriodId,
          payoutSuccess: payoutResults.successCount,
          payoutFailed: payoutResults.failureCount,
          payslipsGenerated,
        },
      );
    } catch (e) {
      this.logger.error('Failed to log activity:', e);
    }
  }

  // ===========================================================================
  // Private Methods - Utility Helpers
  // ===========================================================================

  private async getEmployerName(userId: string): Promise<string> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    return (
      user?.businessName ||
      [user?.firstName, user?.lastName].filter(Boolean).join(' ') ||
      'Employer'
    );
  }

  private async getPayPeriodOrThrow(payPeriodId: string): Promise<PayPeriod> {
    const payPeriod = await this.payPeriodRepository.findOne({
      where: { id: payPeriodId },
    });

    if (!payPeriod) {
      throw new NotFoundException(`Pay period with ID ${payPeriodId} not found`);
    }

    return payPeriod;
  }

  private validatePayPeriodModifiable(payPeriod: PayPeriod): void {
    if (
      payPeriod.status === PayPeriodStatus.CLOSED ||
      payPeriod.status === PayPeriodStatus.COMPLETED
    ) {
      throw new BadRequestException(
        'Cannot modify payroll for a closed or completed pay period.',
      );
    }
  }

  private async resolveWorkerId(userId: string, workerId?: string): Promise<string> {
    if (workerId) {
      return workerId;
    }

    const worker = await this.workersRepository.findOne({
      where: { linkedUserId: userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker profile not found');
    }

    return worker.id;
  }

  private getCurrentPeriod(): { year: number; month: number } {
    const now = new Date();
    return {
      year: now.getFullYear(),
      month: now.getMonth() + 1,
    };
  }

  private parseNumber(value: unknown): number {
    return Number(value) || 0;
  }

  private roundCurrency(value: number): number {
    return Math.round(value * 100) / 100;
  }

  private sumNetSalaries(records: PayrollRecord[]): number {
    return records.reduce((sum, r) => sum + this.parseNumber(r.netSalary), 0);
  }

  private logBatchDuration(operation: string, startTime: number, count: number): void {
    const duration = Date.now() - startTime;
    this.logger.log(
      `${operation} completed: ${count} items in ${duration}ms ` +
      `(${(duration / count).toFixed(2)}ms avg)`,
    );
  }
}