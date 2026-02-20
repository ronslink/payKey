import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  Transaction,
  TransactionType,
  TransactionStatus,
} from './entities/transaction.entity';
import { IntaSendService } from './intasend.service';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import { PaymentMethod } from '../workers/entities/worker.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PayrollPaymentService {
  private readonly logger = new Logger(PayrollPaymentService.name);

  // Delay for status check job (10 minutes)
  private readonly STATUS_CHECK_DELAY_MS = 10 * 60 * 1000;

  constructor(
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    private intaSendService: IntaSendService,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private configService: ConfigService,
    @InjectQueue('payroll-processing')
    private payrollQueue: Queue,
  ) { }

  /**
   * Process payouts for a list of finalized payroll records
   * Uses parallel processing for better performance
   */
  async processPayouts(payrollRecords: PayrollRecord[]): Promise<{
    successCount: number;
    failureCount: number;
    results: any[];
    bankFile?: string; // Content of simulated bank file
  }> {
    this.logger.log(`Processing payouts for ${payrollRecords.length} workers`);
    const startTime = Date.now();

    const allResults = [];
    const bankRecords: PayrollRecord[] = [];
    let successCount = 0;
    let failureCount = 0;

    // Separate Bank vs Mobile records
    const mobileRecords = payrollRecords.filter(
      (r) =>
        !r.worker.paymentMethod ||
        r.worker.paymentMethod === PaymentMethod.MPESA,
    );
    bankRecords.push(
      ...payrollRecords.filter(
        (r) => r.worker.paymentMethod === PaymentMethod.BANK,
      ),
    );

    // Process Mobile Payments (Batched)
    const BATCH_SIZE = 10;
    for (let i = 0; i < mobileRecords.length; i += BATCH_SIZE) {
      const batch = mobileRecords.slice(i, i + BATCH_SIZE);
      const batchResults = await this.processMobileBatch(batch);
      allResults.push(...batchResults);
    }

    // Process Bank Payments (Batched)
    for (let i = 0; i < bankRecords.length; i += BATCH_SIZE) {
      const batch = bankRecords.slice(i, i + BATCH_SIZE);
      const batchResults = await this.processBankBatch(batch);
      allResults.push(...batchResults);
    }

    // Tally results
    allResults.forEach((r) => {
      if (r.success) successCount++;
      else failureCount++;
    });

    const duration = Date.now() - startTime;
    this.logger.log(
      `Completed payout processing in ${duration}ms: ${successCount} successful, ${failureCount} failed`,
    );

    return {
      successCount,
      failureCount,
      results: allResults,
    };
  }

  private get MPESA_LIMIT(): number {
    return this.configService.get<number>('MPESA_LIMIT', 250000);
  }

  /**
 * Calculate IntaSend B2C/Payout fee (confirmed tiered structure).
 * < 200 KES  → KES 10
 * 200–1000   → KES 20
 * > 1000     → KES 100
 */
  private calculatePayoutFee(amount: number): number {
    if (amount < 200) return 10;
    if (amount <= 1000) return 20;
    return 100;
  }
  // PesaLink fee estimation (using safe upper bound or similar logic)
  // Often ranges KES 30-100. Using flat 50 for now as safe estimate.
  private readonly BANK_PAYOUT_FEE = 50;

  private async processMobileBatch(records: PayrollRecord[]) {
    if (records.length === 0) return [];

    const results: any[] = [];
    const allTransactions: Transaction[] = [];
    const intaSendPayload: {
      account: string;
      amount: number;
      narrative: string;
      name: string;
      recordId: string;
    }[] = [];
    let totalBatchAmount = 0;
    let totalBatchFees = 0;

    // Fetch Employer Wallet ID (assuming all records in batch belong to same employer)
    const firstRecord = records[0];
    const employer = await this.usersRepository.findOne({
      where: { id: firstRecord.userId },
      select: ['intasendWalletId'],
    });
    const walletId = employer?.intasendWalletId;

    // 1. Prepare Transactions (Splitting logic)
    for (const record of records) {
      if (record.status !== PayrollStatus.FINALIZED) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: false,
          error: `Record ${record.id} is not finalized`
        });
        continue;
      }

      // Check for already paid/processing
      if (['paid', 'processing'].includes(record.paymentStatus)) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: true,
          message: `Already ${record.paymentStatus}`
        });
        continue;
      }

      let remainingAmount = Number(record.netSalary);
      try {
        while (remainingAmount > 0) {
          const currentAmount = Math.min(remainingAmount, this.MPESA_LIMIT);

          // Store info for IntaSend
          intaSendPayload.push({
            account: record.worker.phoneNumber,
            amount: currentAmount,
            narrative: `Salary Payment${Number(record.netSalary) > this.MPESA_LIMIT ? ' (Part)' : ''}`,
            name: 'Worker',
            recordId: record.id
          });

          // Calculate Fee for this transaction chunk
          const fee = this.calculatePayoutFee(currentAmount);
          totalBatchFees += fee;

          // Create Transaction Entity
          const transaction = this.transactionRepository.create({
            userId: record.userId,
            workerId: record.workerId,
            walletId: walletId, // Track source wallet
            amount: currentAmount,
            currency: 'KES',
            type: TransactionType.SALARY_PAYOUT,
            status: TransactionStatus.PENDING,
            metadata: {
              payrollRecordId: record.id,
              workerName: record.worker.name,
              provider: 'MPESA',
              isSplit: Number(record.netSalary) > this.MPESA_LIMIT,
              splitChunk: currentAmount,
              taxBreakdown: record.taxBreakdown,
              grossSalary: record.grossSalary,
              netPay: record.netSalary,
              estimatedFee: fee, // Track fee in metadata
            },
          });

          allTransactions.push(transaction);
          totalBatchAmount += currentAmount;
          remainingAmount -= currentAmount;
        }
      } catch (err) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: false,
          error: `Preparation Failed: ${err.message}`
        });
      }
    }

    if (allTransactions.length === 0) return results;

    const firstUserId = records[0].userId;
    const totalDeduction = totalBatchAmount + totalBatchFees;

    // 2. Deduct Bundle Amount + Fees
    try {
      await this.usersRepository.decrement({ id: firstUserId }, 'walletBalance', totalDeduction);
    } catch (e) {
      this.logger.error(`Failed to deduct batch amount ${totalDeduction}`, e);
      records.forEach(r => {
        results.push({
          workerId: r.workerId,
          workerName: r.worker.name,
          success: false,
          error: 'Insufficient Funds or Wallet Error'
        });
      });
      return results;
    }

    // 3. Save Pending Transactions
    const savedTransactions = await this.transactionRepository.save(allTransactions);

    // 4. Send Bulk Request to IntaSend
    try {
      const b2cResponse = await this.intaSendService.sendMoney(intaSendPayload, walletId);

      const trackingId = (b2cResponse as { tracking_id?: string })?.tracking_id;
      const finalStatus = process.env.NODE_ENV === 'production' ? 'processing' : 'paid';

      // Update all transactions with tracking_id
      for (const tx of savedTransactions) {
        tx.providerRef = trackingId ?? '';
        if (finalStatus === 'paid') tx.status = TransactionStatus.SUCCESS;
      }
      await this.transactionRepository.save(savedTransactions);

      // Update Records
      const processedRecordIds = new Set(allTransactions.map(tx => tx.metadata.payrollRecordId));

      for (const record of records) {
        if (!processedRecordIds.has(record.id)) continue;

        record.paymentStatus = finalStatus;
        record.paymentDate = new Date();
        await this.payrollRecordRepository.save(record);

        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: true,
          transactionId: trackingId, // Batch ID
          message: 'Batch processing initiated'
        });
      }

      // Schedule safety net status check job (only in production where payouts are async)
      if (finalStatus === 'processing' && trackingId) {
        const payPeriodId = records[0]?.payPeriodId;
        const userId = records[0]?.userId;
        const recordIds = records.map(r => r.id);

        this.logger.log(`Scheduling status check for tracking ID ${trackingId} in ${this.STATUS_CHECK_DELAY_MS / 1000}s`);

        await this.payrollQueue.add(
          'check-payout-status',
          {
            trackingId,
            payPeriodId,
            userId,
            recordIds,
            attempt: 1,
          },
          {
            delay: this.STATUS_CHECK_DELAY_MS,
            attempts: 3, // Retry up to 3 times if job fails
            backoff: {
              type: 'exponential',
              delay: 60000, // 1 minute base delay for retries
            },
          }
        );
      }

    } catch (e: any) {
      this.logger.error('Bulk Payout Failed', e);

      const status = e.response?.status;
      const isSafeToRefund = status && status >= 400 && status < 500;

      if (isSafeToRefund) {
        // Safe to refund (Request rejected)
        await this.usersRepository.increment({ id: firstUserId }, 'walletBalance', totalDeduction);

        for (const tx of savedTransactions) {
          tx.status = TransactionStatus.FAILED;
          tx.metadata = { ...tx.metadata, error: e.message };
        }

        for (const record of records) {
          record.paymentStatus = 'failed';
          await this.payrollRecordRepository.save(record);
          results.push({
            workerId: record.workerId,
            workerName: record.worker.name,
            success: false,
            error: e.message
          });
        }
      } else {
        // Unsafe to refund (Network/Server Error - Unknown State)
        this.logger.warn(`CRITICAL: Potential Partial Failure (Status: ${status}). NOT Refunding automatically.`);

        for (const tx of savedTransactions) {
          tx.status = TransactionStatus.MANUAL_INTERVENTION;
          tx.metadata = { ...tx.metadata, error: e.message, partialFailure: true };
        }

        for (const record of records) {
          // Mark as manual_check to prevent auto-retry while keeping user informed
          record.paymentStatus = 'manual_check';
          await this.payrollRecordRepository.save(record);
          results.push({
            workerId: record.workerId,
            workerName: record.worker.name,
            success: false,
            error: 'Partial Failure: Manual Check Required'
          });
        }
      }
      await this.transactionRepository.save(savedTransactions);
    }

    return results;
  }

  private async processBankBatch(records: PayrollRecord[]) {
    if (records.length === 0) return [];

    const results: any[] = [];
    const allTransactions: Transaction[] = [];
    const intaSendPayload: {
      name: string;
      account: string;
      bankCode: string;
      amount: number;
      narrative: string;
    }[] = [];
    let totalBatchAmount = 0;
    let totalBatchFees = 0;

    // Fetch Employer Wallet ID
    const firstRecord = records[0];
    const employer = await this.usersRepository.findOne({
      where: { id: firstRecord.userId },
      select: ['intasendWalletId'],
    });
    const walletId = employer?.intasendWalletId;


    // 1. Prepare Transactions
    for (const record of records) {
      if (record.status !== PayrollStatus.FINALIZED) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: false,
          error: `Record ${record.id} is not finalized`,
        });
        continue;
      }

      // Check for already paid/processing
      if (['paid', 'processing'].includes(record.paymentStatus)) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: true,
          message: `Already ${record.paymentStatus}`,
        });
        continue;
      }

      // Check Bank Details
      if (!record.worker.bankAccount || !record.worker.bankCode) {
        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: false,
          error: 'Missing Bank Account or Bank Code'
        });
        continue;
      }

      const amount = Number(record.netSalary);

      intaSendPayload.push({
        name: record.worker.name,
        account: record.worker.bankAccount,
        bankCode: record.worker.bankCode,
        amount: amount,
        narrative: 'Salary Payment'
      });

      // Calculate Fee (Flat bank fee for now)
      const fee = this.BANK_PAYOUT_FEE;
      totalBatchFees += fee;

      // Create Transaction Entity
      const transaction = this.transactionRepository.create({
        userId: record.userId,
        workerId: record.workerId,
        walletId: walletId, // Track source wallet
        amount: amount,
        currency: 'KES',
        type: TransactionType.SALARY_PAYOUT,
        status: TransactionStatus.PENDING,
        metadata: {
          payrollRecordId: record.id,
          workerName: record.worker.name,
          provider: 'PESALINK',
          bankName: record.worker.bankName,
          taxBreakdown: record.taxBreakdown,
          grossSalary: record.grossSalary,
          netPay: record.netSalary,
          estimatedFee: fee,
        },
      });

      allTransactions.push(transaction);
      totalBatchAmount += amount;
    }

    if (allTransactions.length === 0) return results;

    const firstUserId = records[0].userId;
    const totalDeduction = totalBatchAmount + totalBatchFees;

    // 2. Deduct Amount + Fees
    try {
      await this.usersRepository.decrement({ id: firstUserId }, 'walletBalance', totalDeduction);
    } catch (e) {
      this.logger.error(`Failed to deduct bank batch amount ${totalDeduction}`, e);
      records.forEach(r => {
        results.push({
          workerId: r.workerId,
          workerName: r.worker.name,
          success: false,
          error: 'Insufficient Funds'
        });
      });
      return results;
    }

    // 3. Save Pending Transactions
    const savedTransactions = await this.transactionRepository.save(allTransactions);

    // 4. Send Bulk Request
    try {
      // NOTE: sendToBank might need update to accept walletId if using sub-wallets?
      // For now, assuming standard payout or master wallet if not supported.
      const response = await this.intaSendService.sendToBank(intaSendPayload, walletId) as any;

      // Assuming similar response structure for tracking
      const trackingId = response.tracking_id || response.invoice_id;
      const finalStatus = 'processing'; // Banks always take time

      // Update Transactions
      for (const tx of savedTransactions) {
        tx.providerRef = trackingId || '';
        if (trackingId) tx.status = TransactionStatus.PENDING; // Keep pending for webhook
      }
      await this.transactionRepository.save(savedTransactions);

      // Update Records
      const processedRecordIds = new Set(allTransactions.map(tx => tx.metadata.payrollRecordId));

      for (const record of records) {
        if (!processedRecordIds.has(record.id)) continue;

        record.paymentStatus = finalStatus;
        await this.payrollRecordRepository.save(record);

        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: true,
          transactionId: trackingId,
          message: 'Bank transfer initiated'
        });
      }

    } catch (e: any) {
      this.logger.error('Bank Bulk Payout Failed', e);

      const status = e.response?.status;
      const isSafeToRefund = status && status >= 400 && status < 500;

      if (isSafeToRefund) {
        // Safe to Refund
        await this.usersRepository.increment({ id: firstUserId }, 'walletBalance', totalDeduction);

        for (const tx of savedTransactions) {
          tx.status = TransactionStatus.FAILED;
          tx.metadata = { ...tx.metadata, error: e.message };
        }

        records.forEach(async r => {
          r.paymentStatus = 'failed';
          await this.payrollRecordRepository.save(r);
          results.push({
            workerId: r.workerId,
            workerName: r.worker.name,
            success: false,
            error: e.message
          });
        });
      } else {
        // Unsafe
        this.logger.warn(`CRITICAL: Potential Bank Partial Failure (Status: ${status}). NOT Refunding automatically.`);

        for (const tx of savedTransactions) {
          tx.status = TransactionStatus.MANUAL_INTERVENTION;
          tx.metadata = { ...tx.metadata, error: e.message, partialFailure: true };
        }

        records.forEach(async r => {
          r.paymentStatus = 'manual_check';
          await this.payrollRecordRepository.save(r);
          results.push({
            workerId: r.workerId,
            workerName: r.worker.name,
            success: false,
            error: 'Partial Failure: Manual Check Required'
          });
        });
      }
      await this.transactionRepository.save(savedTransactions);
    }

    return results;
  }

  /**
   * Helper to generate a simple CSV bank file content
   */
  private generateBankFileContent(records: PayrollRecord[]): string {
    const headers = 'Account Name,Account Number,Bank,Amount,Reference\n';
    const rows = records
      .map((r) => {
        return `${r.worker.name},${r.worker.bankAccount},${r.worker.bankName},${r.netSalary},SALARY`;
      })
      .join('\n');
    return headers + rows;
  }
}
