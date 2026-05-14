import { Processor, WorkerHost, InjectQueue } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job, Queue } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { PayrollService } from './payroll.service';
import { PayrollRecord } from './entities/payroll-record.entity';
import { IntaSendService } from '../payments/intasend.service';
import {
  Transaction,
  TransactionStatus,
} from '../payments/entities/transaction.entity';

export interface PayrollJobData {
  userId: string;
  payPeriodId: string;
  skipPayout: boolean;
  workerIds?: string[];
}

export interface PayoutStatusCheckData {
  trackingId: string;
  payPeriodId: string;
  userId: string;
  recordIds: string[];
  attempt: number;
}

@Processor('payroll-processing')
export class PayrollProcessor extends WorkerHost {
  private readonly logger = new Logger(PayrollProcessor.name);

  // Max status check attempts before giving up
  private readonly MAX_STATUS_CHECKS = 5;
  // Delay between status checks (5 minutes)
  private readonly STATUS_CHECK_INTERVAL_MS = 5 * 60 * 1000;

  constructor(
    private readonly payrollService: PayrollService,
    private readonly intaSendService: IntaSendService,
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectQueue('payroll-processing')
    private readonly payrollQueue: Queue,
  ) {
    super();
  }

  async process(
    job: Job<PayrollJobData | PayoutStatusCheckData>,
  ): Promise<any> {
    this.logger.log(`Processing job ${job.id} (${job.name})`);

    try {
      switch (job.name) {
        case 'finalize-payroll':
          return await this.handlePayrollFinalization(
            job as Job<PayrollJobData>,
          );
        case 'check-payout-status':
          return await this.handlePayoutStatusCheck(
            job as Job<PayoutStatusCheckData>,
          );
        default:
          this.logger.warn(`Unknown job type: ${job.name}`);
          return { status: 'ignored', reason: `Unknown job type: ${job.name}` };
      }
    } catch (error) {
      this.logger.error(`Job ${job.id} failed:`, error.message);
      throw error; // Let BullMQ handle retries
    }
  }

  private async handlePayrollFinalization(job: Job<PayrollJobData>) {
    await job.updateProgress(10);

    try {
      const result = await this.payrollService.executePayrollFinalization(
        job.data.userId,
        job.data.payPeriodId,
        job.data.skipPayout,
        job.data.workerIds,
      );

      await job.updateProgress(100);
      this.logger.log(`Payroll job ${job.id} completed successfully`);
      return result;
    } catch (error) {
      this.logger.error(
        `Payroll job ${job.id} crashed — reverting PayPeriod ${job.data.payPeriodId} to ACTIVE`,
        error.message,
      );
      // Revert PayPeriod so employer is not stuck with a PROCESSING status
      await this.payrollService.revertPayPeriodToActive(job.data.payPeriodId);
      throw error; // Re-throw so BullMQ marks the job as failed
    }
  }

  /**
   * Safety net: Check IntaSend payout status if webhook hasn't updated records yet.
   * This job runs 10 minutes after payout initiation and checks if records
   * are still in 'processing' state. If so, it queries IntaSend for status.
   */
  private async handlePayoutStatusCheck(job: Job<PayoutStatusCheckData>) {
    const { trackingId, recordIds, attempt } = job.data;
    this.logger.log(
      `[Attempt ${attempt}] Checking payout status for tracking ID: ${trackingId}`,
    );

    // 1. Check if any records are still pending
    const pendingRecords = await this.payrollRecordRepository.find({
      where: {
        id: In(recordIds),
        paymentStatus: 'processing',
      },
    });

    if (pendingRecords.length === 0) {
      this.logger.log(
        `All records updated (likely via webhook). No action needed.`,
      );
      return {
        status: 'complete',
        message: 'All records already updated via webhook',
        trackingId,
      };
    }

    // 2. Query IntaSend for current status
    let intaSendStatus: any;
    try {
      intaSendStatus = await this.intaSendService.checkPayoutStatus(trackingId);
      this.logger.log(
        `IntaSend status for ${trackingId}: ${JSON.stringify(intaSendStatus)}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to fetch status from IntaSend: ${error.message}`,
      );
      // Reschedule check if we couldn't reach IntaSend
      return this.rescheduleOrGiveUp(job, 'IntaSend API error');
    }

    // 3. Determine final status from IntaSend response.
    // Prefer itemized transaction statuses when IntaSend returns them; a
    // completed batch can still contain failed beneficiary transactions.
    const payoutStatus = this.resolvePayoutStatus(intaSendStatus);

    if (payoutStatus === TransactionStatus.SUCCESS) {
      // Update records to 'paid'
      await this.payrollRecordRepository.update(
        { id: In(recordIds), paymentStatus: 'processing' },
        { paymentStatus: 'paid' },
      );

      // Update transactions
      await this.transactionRepository.update(
        { providerRef: trackingId },
        { status: TransactionStatus.SUCCESS },
      );

      this.logger.log(
        `Updated ${pendingRecords.length} records to 'paid' via safety net`,
      );
      return {
        status: 'updated',
        message: 'Records updated to paid via safety net check',
        trackingId,
        updatedCount: pendingRecords.length,
      };
    } else if (payoutStatus === TransactionStatus.FAILED) {
      // Update records to 'failed'
      await this.payrollRecordRepository.update(
        { id: In(recordIds), paymentStatus: 'processing' },
        { paymentStatus: 'failed' },
      );

      await this.transactionRepository.update(
        { providerRef: trackingId },
        { status: TransactionStatus.FAILED },
      );

      this.logger.warn(`Payout ${trackingId} failed according to IntaSend`);
      return {
        status: 'failed',
        message: 'Payout failed according to IntaSend',
        trackingId,
        intaSendStatus,
      };
    } else if (payoutStatus === TransactionStatus.MANUAL_INTERVENTION) {
      await this.payrollRecordRepository.update(
        { id: In(recordIds), paymentStatus: 'processing' },
        { paymentStatus: 'manual_check' },
      );

      await this.transactionRepository.update(
        { providerRef: trackingId },
        { status: TransactionStatus.MANUAL_INTERVENTION },
      );

      this.logger.warn(
        `Payout ${trackingId} requires manual review due to mixed or uncertain IntaSend item statuses`,
      );
      return {
        status: 'manual_review',
        message: 'Payout requires manual review based on IntaSend status',
        trackingId,
        intaSendStatus,
      };
    } else {
      // Still processing - reschedule another check
      return this.rescheduleOrGiveUp(
        job,
        `IntaSend status still: ${intaSendStatus?.file_status || intaSendStatus?.status || 'unknown'}`,
      );
    }
  }

  private resolvePayoutStatus(intaSendStatus: any): TransactionStatus {
    const itemStatuses: TransactionStatus[] = Array.isArray(
      intaSendStatus?.transactions,
    )
      ? (intaSendStatus.transactions as any[]).map(
          (item: any): TransactionStatus =>
            this.mapIntaSendStatus(
              item.status || item.state || item.status_code,
            ),
        )
      : [];

    if (itemStatuses.length > 0) {
      const allSucceeded = itemStatuses.every(
        (status: TransactionStatus) => status === TransactionStatus.SUCCESS,
      );
      const allFailed = itemStatuses.every(
        (status: TransactionStatus) => status === TransactionStatus.FAILED,
      );
      const hasSuccess = itemStatuses.includes(TransactionStatus.SUCCESS);
      const hasFailure = itemStatuses.includes(TransactionStatus.FAILED);
      const hasPending = itemStatuses.includes(TransactionStatus.PENDING);

      if (allSucceeded) return TransactionStatus.SUCCESS;
      if (allFailed) return TransactionStatus.FAILED;
      if (hasFailure) return TransactionStatus.MANUAL_INTERVENTION;
      if (hasSuccess && hasPending) return TransactionStatus.PENDING;
    }

    return this.mapIntaSendStatus(
      intaSendStatus?.file_status ||
        intaSendStatus?.status ||
        intaSendStatus?.status_code,
    );
  }

  private mapIntaSendStatus(status: unknown): TransactionStatus {
    const normalized = String(status || '')
      .trim()
      .toUpperCase()
      .replace(/[\s_-]/g, '');

    if (
      [
        'BC100',
        'COMPLETE',
        'COMPLETED',
        'SENT',
        'SUCCESS',
        'SUCCESSFUL',
        'TS100',
      ].includes(normalized)
    ) {
      return TransactionStatus.SUCCESS;
    }

    if (
      [
        'BE111',
        'BF102',
        'CANCELED',
        'CANCELLED',
        'DECLINED',
        'FAILED',
        'TF103',
        'TF106',
        'TC108',
      ].includes(normalized)
    ) {
      return TransactionStatus.FAILED;
    }

    if (normalized === 'TF105' || normalized === 'TH107') {
      return TransactionStatus.MANUAL_INTERVENTION;
    }

    return TransactionStatus.PENDING;
  }

  /**
   * Reschedule status check or give up after max attempts
   */
  private async rescheduleOrGiveUp(
    job: Job<PayoutStatusCheckData>,
    reason: string,
  ) {
    const { attempt } = job.data;

    if (attempt >= this.MAX_STATUS_CHECKS) {
      this.logger.warn(
        `Max status check attempts reached for ${job.data.trackingId}. Marking for manual review.`,
      );

      // Mark records for manual intervention
      await this.payrollRecordRepository.update(
        { id: In(job.data.recordIds), paymentStatus: 'processing' },
        { paymentStatus: 'manual_check' },
      );

      return {
        status: 'manual_review',
        message: `Max attempts reached. ${reason}. Marked for manual review.`,
        trackingId: job.data.trackingId,
        attempts: attempt,
      };
    }

    // Schedule another check
    this.logger.log(
      `Rescheduling status check (attempt ${attempt + 1}) for ${job.data.trackingId}`,
    );

    await this.payrollQueue.add(
      'check-payout-status',
      {
        ...job.data,
        attempt: attempt + 1,
      },
      {
        delay: this.STATUS_CHECK_INTERVAL_MS,
      },
    );

    return {
      status: 'rescheduled',
      message: reason,
      trackingId: job.data.trackingId,
      nextAttempt: attempt + 1,
    };
  }
}
