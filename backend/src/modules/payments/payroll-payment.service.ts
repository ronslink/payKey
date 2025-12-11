import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Transaction,
  TransactionType,
  TransactionStatus,
} from './entities/transaction.entity';
import { MpesaService } from './mpesa.service';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import { PaymentMethod } from '../workers/entities/worker.entity';

@Injectable()
export class PayrollPaymentService {
  private readonly logger = new Logger(PayrollPaymentService.name);

  constructor(
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    private mpesaService: MpesaService,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
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
    const mobileRecords = payrollRecords.filter(r =>
      !r.worker.paymentMethod || r.worker.paymentMethod === PaymentMethod.MPESA
    );
    bankRecords.push(...payrollRecords.filter(r => r.worker.paymentMethod === PaymentMethod.BANK));

    // Process Mobile Payments (Batched)
    const BATCH_SIZE = 10;
    for (let i = 0; i < mobileRecords.length; i += BATCH_SIZE) {
      const batch = mobileRecords.slice(i, i + BATCH_SIZE);
      const batchPromises = batch.map(async (record) => {
        return this.processMobilePayment(record);
      });

      const batchResults = await Promise.all(batchPromises);
      allResults.push(...batchResults);
    }

    // Process Bank Payments (Simulation)
    for (const record of bankRecords) {
      const result = await this.processBankPayment(record);
      allResults.push(result);
    }

    // Tally results
    allResults.forEach(r => {
      if (r.success) successCount++;
      else failureCount++;
    });

    // Generate bank file if needed
    let bankFile: string | undefined;
    if (bankRecords.length > 0) {
      bankFile = this.generateBankFileContent(bankRecords);
      this.logger.log('Generated Bank File for ' + bankRecords.length + ' records');
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

  private async processMobilePayment(record: PayrollRecord) {
    try {
      if (record.status !== PayrollStatus.FINALIZED) {
        throw new Error(`Payroll record ${record.id} is not finalized`);
      }

      let remainingAmount = Number(record.netSalary);
      const transactions: string[] = [];
      const errors: string[] = [];

      // Smart Splitting Loop
      while (remainingAmount > 0) {
        const currentAmount = Math.min(remainingAmount, this.MPESA_LIMIT);

        // Create pending transaction for this chunk
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
            netPay: record.netSalary
          },
        });
        const savedTransaction = await this.transactionRepository.save(transaction);

        // Send B2C for this chunk
        const b2cResult = await this.mpesaService.sendB2C(
          savedTransaction.id,
          record.worker.phoneNumber,
          currentAmount,
          `Salary Payment${Number(record.netSalary) > this.MPESA_LIMIT ? ' (Part)' : ''}`,
        );

        if (b2cResult.error) {
          // If a chunk fails, we log it and potentially stop or continue. 
          // For safety, we'll mark this chunk failed and stop processing the rest to avoid partial mess if possible,
          // OR we could try to process other chunks. 
          // Safest to stop and report error so admin can handle the rest manually.
          errors.push(b2cResult.error);
          break; // Stop splitting on first error
        } else {
          transactions.push(savedTransaction.id);
          remainingAmount -= currentAmount;
        }
      }

      if (errors.length > 0) {
        record.paymentStatus = 'failed';
        await this.payrollRecordRepository.save(record);
        return {
          workerId: record.workerId,
          workerName: record.worker.name,
          success: false,
          error: `Partial/Full Failure: ${errors.join(', ')}. Processed ${transactions.length} chunks.`,
        };
      }

      record.paymentStatus = 'processing';
      record.paymentDate = new Date();
      await this.payrollRecordRepository.save(record);

      return {
        workerId: record.workerId,
        workerName: record.worker.name,
        success: true,
        transactionId: transactions.join(','), // Return all IDs
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
          provider: 'BANK'
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
        message: 'Bank transfer simulated'
      };
    } catch (error) {
      return {
        workerId: record.workerId,
        workerName: record.worker?.name,
        success: false,
        error: error.message
      };
    }
  }

  private generateBankFileContent(records: PayrollRecord[]): string {
    // Simple CSV format: Account Name, Account Number, Amount, Currency
    const header = 'Worker Name,Account Number,Amount,Currency\n';
    const rows = records.map(r => {
      // Assuming account number is in worker details or metadata. Using phone as fallback/placeholder
      return `${r.worker.name},${r.worker.phoneNumber || 'N/A'},${r.netSalary},KES`;
    }).join('\n');
    return header + rows;
  }
}
