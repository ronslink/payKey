import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker, EmploymentType } from '../workers/entities/worker.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollCalculation } from '../taxes/interfaces/tax.interface';
import {
  Transaction,
  TransactionType,
  TransactionStatus,
} from './entities/transaction.entity';
import { TimeTrackingService } from '../time-tracking/time-tracking.service';
import {
  PayPeriod,
  PayPeriodStatus,
} from '../payroll/entities/pay-period.entity';
import {
  TaxSubmission,
  TaxSubmissionStatus,
} from '../taxes/entities/tax-submission.entity';
import { MpesaService } from './mpesa.service';

@Injectable()
export class PayrollService {
  constructor(
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
    private taxesService: TaxesService,
    private timeTrackingService: TimeTrackingService,
    private mpesaService: MpesaService,
  ) {}

  /**
   * Calculate payroll for a single worker
   */
  private async calculateWorkerPayroll(
    worker: Worker,
    startDate?: Date,
    endDate?: Date,
  ): Promise<PayrollCalculation> {
    let grossSalary = Number(worker.salaryGross);

    if (worker.employmentType === EmploymentType.HOURLY) {
      if (!startDate || !endDate) {
        const now = new Date();
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      }

      const timeEntries = await this.timeTrackingService.getEntriesForWorker(
        worker.id,
        worker.userId,
        startDate,
        endDate,
      );

      const totalHours = timeEntries.reduce(
        (sum: number, entry) => sum + (Number(entry.totalHours) || 0),
        0,
      );
      grossSalary = totalHours * Number(worker.hourlyRate || 0);
    }

    return await this.taxesService.calculatePayroll(
      worker.id,
      worker.name,
      grossSalary,
    );
  }

  /**
   * Calculate payroll for multiple workers
   */
  async calculatePayroll(
    workerIds: string[],
    userId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<PayrollCalculation[]> {
    const calculations: PayrollCalculation[] = [];

    for (const workerId of workerIds) {
      const worker = await this.workerRepository.findOne({
        where: { id: workerId, userId },
      });

      if (!worker) {
        throw new NotFoundException(`Worker ${workerId} not found`);
      }

      const calculation = await this.calculateWorkerPayroll(
        worker,
        startDate,
        endDate,
      );
      calculations.push(calculation);
    }

    return calculations;
  }

  /**
   * Process payroll for multiple workers with detailed status tracking
   * Returns results for each worker, even if some fail
   */
  /**
   * Create a new Pay Period for a given month
   */
  async createPayPeriod(
    userId: string,
    year: number,
    month: number,
  ): Promise<PayPeriod> {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);
    const name = startDate.toLocaleString('default', {
      month: 'long',
      year: 'numeric',
    });

    const payPeriod = this.payPeriodRepository.create({
      userId,
      name,
      startDate,
      endDate,
      status: PayPeriodStatus.ACTIVE,
    });

    return this.payPeriodRepository.save(payPeriod);
  }

  /**
   * Process payroll for multiple workers with detailed status tracking
   * Returns results for each worker, even if some fail
   */
  async processPayroll(
    userId: string,
    workerIds: string[],
    payPeriodId: string,
  ): Promise<any> {
    const payPeriod = await this.payPeriodRepository.findOne({
      where: { id: payPeriodId, userId },
    });
    if (!payPeriod) {
      throw new NotFoundException('Pay Period not found');
    }
    if (payPeriod.status !== PayPeriodStatus.ACTIVE) {
      throw new BadRequestException('Pay Period is not OPEN');
    }

    // Lock Pay Period
    payPeriod.status = PayPeriodStatus.PROCESSING;
    await this.payPeriodRepository.save(payPeriod);

    const results = [];
    let successCount = 0;
    let failureCount = 0;
    let totalGross = 0;
    let totalNet = 0;

    // Tax Accumulation
    let totalPaye = 0;
    let totalNssf = 0;
    let totalNhif = 0;
    let totalHousingLevy = 0;

    // Process each worker individually to handle partial failures
    for (const workerId of workerIds) {
      try {
        const worker = await this.workerRepository.findOne({
          where: { id: workerId, userId },
        });

        if (!worker) {
          results.push({
            workerId,
            workerName: 'Unknown',
            success: false,
            error: 'Worker not found',
          });
          failureCount++;
          continue;
        }

        // Calculate payroll for this worker using Pay Period dates
        const payroll = await this.calculateWorkerPayroll(
          worker,
          payPeriod.startDate,
          payPeriod.endDate,
        );

        // Create transaction record
        const transaction = this.transactionRepository.create({
          userId,
          workerId: worker.id,
          amount: payroll.netPay,
          currency: 'KES',
          type: TransactionType.SALARY_PAYOUT,
          status: TransactionStatus.PENDING,
          payPeriod,
          metadata: {
            grossSalary: payroll.grossSalary,
            taxBreakdown: payroll.taxBreakdown,
            netPay: payroll.netPay,
            workerName: payroll.workerName,
          },
        });

        const savedTransaction =
          await this.transactionRepository.save(transaction);

        // Initiate M-Pesa B2C
        const b2cResult = await this.mpesaService.sendB2C(
          savedTransaction.id,
          worker.phoneNumber,
          payroll.netPay,
          `Salary for ${payPeriod.name}`,
        );

        if (b2cResult.error) {
          results.push({
            workerId: worker.id,
            workerName: worker.name,
            success: false,
            error: b2cResult.error,
          });
          failureCount++;
          continue;
        }

        // Accumulate Taxes
        totalPaye += Number(payroll.taxBreakdown.paye);
        totalNssf += Number(payroll.taxBreakdown.nssf);
        totalNhif += Number(payroll.taxBreakdown.nhif);
        totalHousingLevy += Number(payroll.taxBreakdown.housingLevy);

        results.push({
          workerId: worker.id,
          workerName: worker.name,
          success: true,
          grossSalary: payroll.grossSalary,
          netPay: payroll.netPay,
          transactionId: savedTransaction.id,
        });

        successCount++;
        totalGross += payroll.grossSalary;
        totalNet += payroll.netPay;
      } catch (error) {
        results.push({
          workerId,
          workerName: 'Unknown',
          success: false,
          error: error.message || 'Processing failed',
        });
        failureCount++;
      }
    }

    // Create Tax Submission
    const taxSubmission = this.taxSubmissionRepository.create({
      userId,
      payPeriod,
      totalPaye,
      totalNssf,
      totalNhif,
      totalHousingLevy,
      status: TaxSubmissionStatus.PENDING,
    });
    await this.taxSubmissionRepository.save(taxSubmission);

    // Close Pay Period
    payPeriod.status = PayPeriodStatus.CLOSED;
    await this.payPeriodRepository.save(payPeriod);

    return {
      payPeriodId: payPeriod.id,
      totalWorkers: workerIds.length,
      successCount,
      failureCount,
      totalGross,
      totalNet,
      taxSubmissionId: taxSubmission.id,
      results,
      processedAt: new Date(),
    };
  }
}
