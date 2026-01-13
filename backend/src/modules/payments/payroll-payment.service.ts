import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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

  constructor(
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    private intaSendService: IntaSendService,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
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

    // Process Bank Payments (Simulation)
    for (const record of bankRecords) {
      const result = await this.processBankPayment(record);
      allResults.push(result);
    }

    // Tally results
    allResults.forEach((r) => {
      if (r.success) successCount++;
      else failureCount++;
    });

    // Generate bank file if needed
    let bankFile: string | undefined;
    if (bankRecords.length > 0) {
      bankFile = this.generateBankFileContent(bankRecords);
      this.logger.log(
        'Generated Bank File for ' + bankRecords.length + ' records',
      );
    }

    const duration = Date.now() - startTime;
    this.logger.log(
      `Completed payout processing in ${duration}ms: ${successCount} successful, ${failureCount} failed`,
    );

    return {
      successCount,
      failureCount,
      results: allResults,
      bankFile,
    };
  }

  private readonly MPESA_LIMIT = 150000;

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

          // Create Transaction Entity
          const transaction = this.transactionRepository.create({
            userId: record.userId,
            workerId: record.workerId,
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

    // 2. Deduct Bundle Amount
    try {
      await this.usersRepository.decrement({ id: firstUserId }, 'walletBalance', totalBatchAmount);
    } catch (e) {
      this.logger.error(`Failed to deduct batch amount ${totalBatchAmount}`, e);
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

    // 4. Send Bulk Request
    try {
      const b2cResponse = await this.intaSendService.sendMoney(intaSendPayload);

      const trackingId = b2cResponse.tracking_id;
      const status = this.intaSendService['isLive'] ? 'processing' : 'paid';

      const finalStatus = process.env.NODE_ENV === 'production' ? 'processing' : 'paid';

      // Update all transactions with tracking_id
      for (const tx of savedTransactions) {
        tx.providerRef = trackingId;
        // tx.status remains PENDING until webhook
        if (finalStatus === 'paid') tx.status = TransactionStatus.SUCCESS;
      }
      await this.transactionRepository.save(savedTransactions);

      // Update Records
      for (const record of records) {
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

    } catch (e) {
      this.logger.error('Bulk Payout Failed', e);

      // Refund
      await this.usersRepository.increment({ id: firstUserId }, 'walletBalance', totalBatchAmount);

      // Mark Transactions Failed
      for (const tx of savedTransactions) {
        tx.status = TransactionStatus.FAILED;
        tx.metadata = { ...tx.metadata, error: e.message };
      }
      await this.transactionRepository.save(savedTransactions);

      // Update Records Logic (Mark failed)
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
    }

    return results;
  }

  private async processBankPayment(record: PayrollRecord) {
    try {
      const transaction = this.transactionRepository.create({
        userId: record.userId,
        workerId: record.workerId,
        amount: Number(record.netSalary),
        currency: 'KES',
        type: TransactionType.SALARY_PAYOUT,
        status: TransactionStatus.SUCCESS, // Mark SUCCESS for bank sim
        metadata: {
          payrollRecordId: record.id,
          workerName: record.worker.name,
          provider: 'BANK',
        },
      });
      await this.transactionRepository.save(transaction);

      record.paymentStatus = 'paid'; // Assessing immediate success for bank sim
      record.paymentDate = new Date();
      await this.payrollRecordRepository.save(record);

      return {
        workerId: record.workerId,
        workerName: record.worker.name,
        success: true,
        transactionId: transaction.id,
      };
    } catch (error) {
      return {
        workerId: record.workerId,
        workerName: record.worker?.name || 'Unknown',
        success: false,
        error: error.message || 'Processing failed',
      };
    }
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
