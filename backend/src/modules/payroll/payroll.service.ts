import { Injectable, Logger, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual, Between, DataSource, In } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollRecord, PayrollStatus } from './entities/payroll-record.entity';
import { PayrollPaymentService } from '../payments/payroll-payment.service';
import { ActivitiesService } from '../activities/activities.service';
import { ActivityType } from '../activities/entities/activity.entity';
import { PayslipService } from './payslip.service';
import { PayPeriod, PayPeriodStatus } from './entities/pay-period.entity';

@Injectable()
export class PayrollService {
  private readonly logger = new Logger(PayrollService.name);

  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    @InjectRepository(PayrollRecord)
    private payrollRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    private taxesService: TaxesService,
    private payrollPaymentService: PayrollPaymentService,
    private activitiesService: ActivitiesService,
    private dataSource: DataSource,
    private payslipService: PayslipService,
  ) { }

  async calculatePayrollForUser(userId: string) {
    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const payrollItems = await Promise.all(
      workers.map(async (worker) => {
        try {
          // Convert salaryGross to number (handle string values from database)
          const grossSalary = Number(worker.salaryGross);

          // Validate salary value
          if (isNaN(grossSalary) || grossSalary <= 0) {
            this.logger.warn(
              `Invalid salary for worker ${worker.id}: ${worker.salaryGross}`,
            );
            return {
              workerId: worker.id,
              workerName: worker.name,
              grossSalary: 0,
              taxBreakdown: {
                nssf: 0,
                nhif: 0,
                housingLevy: 0,
                paye: 0,
                totalDeductions: 0,
              },
              netPay: 0,
              phoneNumber: worker.phoneNumber,
              error: 'Invalid salary amount',
            };
          }

          const taxBreakdown = await this.taxesService.calculateTaxes(
            grossSalary,
          );
          const netPay = grossSalary - taxBreakdown.totalDeductions;

          return {
            workerId: worker.id,
            workerName: worker.name,
            grossSalary,
            taxBreakdown,
            netPay: Math.round(netPay * 100) / 100,
            phoneNumber: worker.phoneNumber,
          };
        } catch (error) {
          // Log error but continue with other workers
          this.logger.error(
            `Error calculating payroll for worker ${worker.id}:`,
            error,
          );
          return {
            workerId: worker.id,
            workerName: worker.name,
            grossSalary: Number(worker.salaryGross) || 0,
            taxBreakdown: {
              nssf: 0,
              nhif: 0,
              housingLevy: 0,
              paye: 0,
              totalDeductions: 0,
            },
            netPay: 0,
            phoneNumber: worker.phoneNumber,
            error: error.message || 'Failed to calculate taxes',
          };
        }
      }),
    );

    const totalGross = payrollItems.reduce(
      (sum, item) => sum + (item.grossSalary || 0),
      0,
    );
    const totalDeductions = payrollItems.reduce(
      (sum, item) => sum + (item.taxBreakdown?.totalDeductions || 0),
      0,
    );
    const totalNetPay = payrollItems.reduce(
      (sum, item) => sum + (item.netPay || 0),
      0,
    );

    return {
      payrollItems,
      summary: {
        totalGross: Math.round(totalGross * 100) / 100,
        totalDeductions: Math.round(totalDeductions * 100) / 100,
        totalNetPay: Math.round(totalNetPay * 100) / 100,
        workerCount: workers.length,
      },
    };
  }

  /**
   * Optimized batch calculation for multiple workers
   * Uses parallel processing with chunking to avoid memory issues
   */
  async calculatePayrollBatch(
    userId: string,
    workerIds: string[],
  ): Promise<{
    payrollItems: any[];
    summary: any;
  }> {
    const startTime = Date.now();
    this.logger.log(`Starting batch payroll calculation for ${workerIds.length} workers`);

    // Fetch all workers in one query
    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const selectedWorkers = workerIds.length > 0
      ? workers.filter(w => workerIds.includes(w.id))
      : workers;

    if (selectedWorkers.length === 0) {
      throw new Error('No workers found');
    }

    // Batch tax calculations - process in chunks to avoid memory issues
    const CHUNK_SIZE = 50;
    const payrollItems = [];

    for (let i = 0; i < selectedWorkers.length; i += CHUNK_SIZE) {
      const chunk = selectedWorkers.slice(i, i + CHUNK_SIZE);
      const chunkResults = await Promise.all(
        chunk.map(async (worker) => {
          try {
            // Convert salaryGross to number (handle string values from database)
            const grossSalary = Number(worker.salaryGross);

            // Validate salary value
            if (isNaN(grossSalary) || grossSalary <= 0) {
              this.logger.warn(
                `Invalid salary for worker ${worker.id}: ${worker.salaryGross}`,
              );
              return {
                workerId: worker.id,
                workerName: worker.name,
                grossSalary: 0,
                taxBreakdown: {
                  nssf: 0,
                  nhif: 0,
                  housingLevy: 0,
                  paye: 0,
                  totalDeductions: 0,
                },
                netPay: 0,
                phoneNumber: worker.phoneNumber,
                error: 'Invalid salary amount',
              };
            }

            const taxBreakdown = await this.taxesService.calculateTaxes(
              grossSalary,
            );
            const netPay = grossSalary - taxBreakdown.totalDeductions;

            return {
              workerId: worker.id,
              workerName: worker.name,
              grossSalary,
              taxBreakdown,
              netPay: Math.round(netPay * 100) / 100,
              phoneNumber: worker.phoneNumber,
            };
          } catch (error) {
            // Log error but continue with other workers
            this.logger.error(
              `Error calculating payroll for worker ${worker.id}:`,
              error,
            );
            return {
              workerId: worker.id,
              workerName: worker.name,
              grossSalary: Number(worker.salaryGross) || 0,
              taxBreakdown: {
                nssf: 0,
                nhif: 0,
                housingLevy: 0,
                paye: 0,
                totalDeductions: 0,
              },
              netPay: 0,
              phoneNumber: worker.phoneNumber,
              error: error.message || 'Failed to calculate taxes',
            };
          }
        }),
      );
      payrollItems.push(...chunkResults);
    }

    const totalGross = payrollItems.reduce(
      (sum, item) => sum + (item.grossSalary || 0),
      0,
    );
    const totalDeductions = payrollItems.reduce(
      (sum, item) => sum + (item.taxBreakdown?.totalDeductions || 0),
      0,
    );
    const totalNetPay = payrollItems.reduce(
      (sum, item) => sum + (item.netPay || 0),
      0,
    );

    const duration = Date.now() - startTime;
    this.logger.log(
      `Batch payroll calculation completed: ${selectedWorkers.length} workers in ${duration}ms (${(duration / selectedWorkers.length).toFixed(2)}ms avg)`,
    );

    return {
      payrollItems,
      summary: {
        totalGross: Math.round(totalGross * 100) / 100,
        totalDeductions: Math.round(totalDeductions * 100) / 100,
        totalNetPay: Math.round(totalNetPay * 100) / 100,
        workerCount: selectedWorkers.length,
      },
    };
  }

  async calculateSingleWorkerPayroll(workerId: string, userId: string) {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new Error('Worker not found');
    }

    // Convert salaryGross to number (handle string values from database)
    const grossSalary = Number(worker.salaryGross);

    // Validate salary value
    if (isNaN(grossSalary) || grossSalary <= 0) {
      throw new Error(`Invalid salary amount for worker: ${worker.salaryGross}`);
    }

    const taxBreakdown = await this.taxesService.calculateTaxes(
      grossSalary,
    );
    const netPay = grossSalary - taxBreakdown.totalDeductions;

    return {
      worker,
      payrollCalculation: {
        grossSalary,
        taxBreakdown,
        netPay: Math.round(netPay * 100) / 100,
      },
    };
  }

  /**
   * Save draft payroll with optimized batch processing
   * Uses transactions and bulk operations for better performance
   */
  async saveDraftPayroll(
    userId: string,
    payPeriodId: string,
    items: Array<{
      workerId: string;
      grossSalary: number;
      bonuses?: number;
      otherEarnings?: number;
      otherDeductions?: number;
    }>,
  ) {
    const startTime = Date.now();
    this.logger.log(`Saving ${items.length} draft payroll records`);

    // Fetch the pay period to get actual dates
    const payPeriod = await this.payPeriodRepository.findOne({
      where: { id: payPeriodId },
    });

    if (!payPeriod) {
      throw new Error(`Pay period with ID ${payPeriodId} not found`);
    }

    const periodStart = new Date(payPeriod.startDate);
    const periodEnd = new Date(payPeriod.endDate);

    // Validate Pay Period Status
    if (
      payPeriod.status === PayPeriodStatus.CLOSED ||
      payPeriod.status === PayPeriodStatus.COMPLETED
    ) {
      throw new BadRequestException(
        'Cannot modify payroll for a closed or completed pay period.',
      );
    }

    // Use transaction for data integrity
    const savedRecords = await this.dataSource.transaction(async (manager) => {
      const results = [];

      // Process in batches for better performance
      const BATCH_SIZE = 100;
      for (let i = 0; i < items.length; i += BATCH_SIZE) {
        const batch = items.slice(i, i + BATCH_SIZE);
        const batchPromises = batch.map(async (item) => {
          // Calculate taxes
          const totalEarnings =
            item.grossSalary + (item.bonuses || 0) + (item.otherEarnings || 0);
          const taxBreakdown =
            await this.taxesService.calculateTaxes(totalEarnings);

          const totalDeductions =
            taxBreakdown.totalDeductions + (item.otherDeductions || 0);
          const netPay = totalEarnings - totalDeductions;

          // Check if ANY record exists for this worker in this period
          let record = await manager.findOne(PayrollRecord, {
            where: {
              userId,
              payPeriodId,
              workerId: item.workerId,
            },
          });

          if (record) {
            // If record exists but is not DRAFT, we cannot overwrite it via draft save
            if (record.status !== PayrollStatus.DRAFT) {
              throw new BadRequestException(
                `Payroll record for worker ${item.workerId} is already ${record.status} and cannot be modified.`,
              );
            }
            // If DRAFT, we update it (fall through)
          } else {
            // Create new record
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
        });

        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);
      }

      return results;
    });

    const duration = Date.now() - startTime;
    this.logger.log(
      `Saved ${savedRecords.length} draft records in ${duration}ms (${(duration / savedRecords.length).toFixed(2)}ms avg)`,
    );

    return savedRecords;
  }

  async updateDraftPayrollItem(
    userId: string,
    recordId: string,
    updates: {
      grossSalary?: number;
      bonuses?: number;
      otherEarnings?: number;
      otherDeductions?: number;
      holidayHours?: number;
      sundayHours?: number;
    },
  ) {
    const record = await this.payrollRepository.findOne({
      where: { id: recordId, userId, status: PayrollStatus.DRAFT },
    });

    if (!record) {
      throw new Error('Draft payroll record not found');
    }

    if (updates.grossSalary !== undefined)
      record.grossSalary = updates.grossSalary;
    if (updates.bonuses !== undefined) record.bonuses = updates.bonuses;
    if (updates.otherEarnings !== undefined)
      record.otherEarnings = updates.otherEarnings;
    if (updates.otherDeductions !== undefined)
      record.otherDeductions = updates.otherDeductions;
    if (updates.holidayHours !== undefined) record.holidayHours = updates.holidayHours;
    if (updates.sundayHours !== undefined) record.sundayHours = updates.sundayHours;

    // Fetch worker to get employment details for hourly rate calculation
    const worker = await this.workersRepository.findOne({
      where: { id: record.workerId },
    });

    let overtimePay = 0;
    if (worker) {
      // Determine hourly rate
      let hourlyRate = 0;
      if (worker.employmentType === 'HOURLY') {
        hourlyRate = Number(worker.hourlyRate) || 0;
      } else {
        // Fixed: Standard Kenya practice (26 days * 8 hours = 208 hours)
        hourlyRate = Number(record.grossSalary) / 208;
      }

      const holidayPay = hourlyRate * 1.5 * Number(record.holidayHours);
      const sundayPay = hourlyRate * 2.0 * Number(record.sundayHours);
      overtimePay = holidayPay + sundayPay;
    }

    record.overtimePay = overtimePay;

    // Recalculate
    const totalEarnings =
      Number(record.grossSalary) +
      Number(record.bonuses) +
      Number(record.otherEarnings) +
      overtimePay;

    const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);

    const totalDeductions =
      taxBreakdown.totalDeductions + Number(record.otherDeductions);
    const netPay = totalEarnings - totalDeductions;

    record.taxAmount = taxBreakdown.paye;
    record.netSalary = netPay;
    record.taxBreakdown = taxBreakdown;
    record.deductions = {
      ...taxBreakdown,
      otherDeductions: record.otherDeductions,
    };

    return this.payrollRepository.save(record);
  }

  async getDraftPayroll(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: {
        userId,
        payPeriodId,
        status: PayrollStatus.DRAFT,
      },
      relations: ['worker'],
    });

    return this._transformRecords(records);
  }

  async getPeriodRecords(userId: string, payPeriodId: string) {
    const records = await this.payrollRepository.find({
      where: {
        userId,
        payPeriodId,
      },
      relations: ['worker'],
    });

    return this._transformRecords(records);
  }

  private _transformRecords(records: PayrollRecord[]) {
    return records.map((record) => ({
      id: record.id,
      workerId: record.workerId,
      workerName: record.worker.name,
      grossSalary: Number(record.grossSalary),
      bonuses: Number(record.bonuses),
      otherEarnings: Number(record.otherEarnings),
      otherDeductions: Number(record.otherDeductions),
      taxBreakdown: record.taxBreakdown,
      netPay: Number(record.netSalary),
      status: record.status,
    }));
  }

  /**
   * Finalize payroll with optimized batch processing
   * Uses transactions and parallel processing
   */
  async finalizePayroll(userId: string, payPeriodId: string) {
    const startTime = Date.now();
    this.logger.log(`Finalizing payroll for period ${payPeriodId}`);

    const records = await this.payrollRepository.find({
      where: {
        userId,
        payPeriodId,
        status: PayrollStatus.DRAFT,
      },
      relations: ['worker', 'payPeriod'],
    });

    if (records.length === 0) {
      throw new Error('No draft payroll records found for this period');
    }

    const finalizedDate = new Date();

    // 1. Mark as finalized using bulk update for better performance
    const updatedRecords = await this.dataSource.transaction(async (manager) => {
      const updates = records.map(async (record) => {
        record.status = PayrollStatus.FINALIZED;
        record.finalizedAt = finalizedDate;
        return manager.save(PayrollRecord, record);
      });

      return Promise.all(updates);
    });

    const duration = Date.now() - startTime;
    this.logger.log(
      `Finalized ${updatedRecords.length} payroll records in ${duration}ms`,
    );

    // 2. Generate Payslips (in parallel with payments for efficiency)
    this.logger.log('Starting payslip generation...');
    const payslipGenerationPromise = this.payslipService
      .generatePayslipsBatch(updatedRecords)
      .then((payslips) => {
        this.logger.log(`Generated ${payslips.length} payslips successfully`);
        return { success: true, count: payslips.length };
      })
      .catch((error) => {
        this.logger.error('Failed to generate payslips:', error);
        return { success: false, error: error.message };
      });

    // 3. Process M-Pesa Payouts (in parallel with payslips)
    this.logger.log('Starting M-Pesa payout processing...');
    const payoutPromise = this.payrollPaymentService
      .processPayouts(updatedRecords)
      .then((results) => {
        this.logger.log(
          `Payouts processed: ${results.successCount} successful, ${results.failureCount} failed`,
        );
        return results;
      })
      .catch((error) => {
        this.logger.error('Failed to process payouts:', error);
        return {
          successCount: 0,
          failureCount: updatedRecords.length,
          results: [],
          error: error.message,
        };
      });

    // Wait for both payslips and payouts to complete
    const [payslipResults, payoutResults] = await Promise.all([
      payslipGenerationPromise,
      payoutPromise,
    ]);

    // 4. Generate Tax Submission
    try {
      this.logger.log('Generating tax submission...');
      await this.taxesService.generateTaxSubmission(payPeriodId, userId);
      this.logger.log('Tax submission generated successfully');
    } catch (error) {
      // Log error but don't fail the finalization
      this.logger.error('Failed to generate tax submission:', error);
    }

    // 5. Log Activity
    const totalAmount = updatedRecords.reduce(
      (sum, r) => sum + Number(r.netSalary),
      0,
    );
    const payslipsGenerated = payslipResults.success && 'count' in payslipResults ? payslipResults.count : 0;

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.PAYROLL,
        'Payroll Finalized',
        `Finalized payroll for ${updatedRecords.length} workers. Payments: ${payoutResults.successCount} successful, ${payoutResults.failureCount} failed. Payslips: ${payslipsGenerated} generated.`,
        {
          workerCount: updatedRecords.length,
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

    const totalDuration = Date.now() - startTime;
    this.logger.log(
      `Payroll finalization completed in ${totalDuration}ms: ${updatedRecords.length} records, ${payoutResults.successCount} payments successful, ${payslipsGenerated} payslips generated`,
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

  async getPayrollStats(userId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    const thisMonthRecords = await this.payrollRepository.find({
      where: {
        userId,
        status: PayrollStatus.FINALIZED,
        periodEnd: MoreThanOrEqual(startOfMonth),
      },
    });

    const lastMonthRecords = await this.payrollRepository.find({
      where: {
        userId,
        status: PayrollStatus.FINALIZED,
        periodEnd: Between(startOfLastMonth, endOfLastMonth),
      },
    });

    const thisMonthTotal = thisMonthRecords.reduce((sum, r) => sum + Number(r.netSalary), 0);
    const lastMonthTotal = lastMonthRecords.reduce((sum, r) => sum + Number(r.netSalary), 0);

    const trend = thisMonthTotal - lastMonthTotal;
    const trendDescription = trend >= 0 ? `+${trend}` : `${trend}`;

    return {
      thisMonthTotal,
      lastMonthTotal,
      trend: trendDescription,
      trendUp: trend >= 0,
      processedCount: thisMonthRecords.length,
    };
  }
  async getEmployeePayslips(userId: string, workerId?: string) {
    let worker;
    if (workerId) {
      worker = { id: workerId }; // Min object needed for query
    } else {
      worker = await this.workersRepository.findOne({
        where: { linkedUserId: userId },
      });

      if (!worker) {
        throw new NotFoundException('Worker profile not found');
      }
    }

    return this.payrollRepository.find({
      where: {
        workerId: worker.id,
        status: PayrollStatus.FINALIZED,
      },
      relations: ['payPeriod'],
      order: { periodStart: 'DESC' },
    });
  }

  async getEmployeePayslipPdf(userId: string, recordId: string, workerId?: string) {
    let worker;
    if (workerId) {
      worker = { id: workerId };
    } else {
      worker = await this.workersRepository.findOne({
        where: { linkedUserId: userId },
      });

      if (!worker) {
        throw new NotFoundException('Worker profile not found');
      }
    }

    const record = await this.payrollRepository.findOne({
      where: {
        id: recordId,
        workerId: worker.id,
        status: PayrollStatus.FINALIZED,
      },
      relations: ['worker', 'payPeriod'],
    });

    if (!record) {
      throw new NotFoundException('Payslip not found');
    }

    return this.payslipService.generatePayslip(record);
  }

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
   * Verify if user has sufficient wallet balance to process payroll for a pay period
   */
  async verifyFundsForPeriod(userId: string, payPeriodId: string) {
    // Get user with wallet balance
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

    // Get all payroll records for this period (any status that contribute to payout)
    const records = await this.payrollRepository.find({
      where: {
        payPeriodId,
        userId,
        status: In([PayrollStatus.FINALIZED, PayrollStatus.DRAFT]),
      },
    });

    // Calculate total net pay required
    const totalNetPay = records.reduce(
      (sum, r) => sum + (parseFloat(r.netSalary as any) || 0),
      0,
    );

    const canProceed = walletBalance >= totalNetPay;
    const shortfall = Math.max(0, totalNetPay - walletBalance);

    return {
      requiredAmount: totalNetPay,
      availableBalance: walletBalance,
      canProceed,
      shortfall,
      workerCount: records.length,
    };
  }
}
