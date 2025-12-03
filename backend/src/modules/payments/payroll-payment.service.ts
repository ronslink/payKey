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
  }> {
    this.logger.log(`Processing payouts for ${payrollRecords.length} workers`);
    const startTime = Date.now();

    // Process in batches to avoid overwhelming M-Pesa API
    const BATCH_SIZE = 10;
    const allResults = [];
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < payrollRecords.length; i += BATCH_SIZE) {
      const batch = payrollRecords.slice(i, i + BATCH_SIZE);

      // Process batch in parallel
      const batchPromises = batch.map(async (record) => {
        try {
          if (record.status !== PayrollStatus.FINALIZED) {
            throw new Error(`Payroll record ${record.id} is not finalized`);
          }

          // Create transaction record
          const transaction = this.transactionRepository.create({
            userId: record.userId,
            workerId: record.workerId,
            amount: Number(record.netSalary),
            currency: 'KES',
            type: TransactionType.SALARY_PAYOUT,
            status: TransactionStatus.PENDING,
            metadata: {
              payrollRecordId: record.id,
              workerName: record.worker.name,
            },
          });

          const savedTransaction =
            await this.transactionRepository.save(transaction);

          // Initiate M-Pesa B2C
          const b2cResult = await this.mpesaService.sendB2C(
            savedTransaction.id,
            record.worker.phoneNumber,
            Number(record.netSalary),
            `Salary Payment`,
          );

          if (b2cResult.error) {
            record.paymentStatus = 'failed';
            await this.payrollRecordRepository.save(record);

            return {
              workerId: record.workerId,
              workerName: record.worker.name,
              success: false,
              error: b2cResult.error,
            };
          }

          // Update record status
          record.paymentStatus = 'processing'; // Will be updated to 'paid' via callback
          record.paymentDate = new Date();
          await this.payrollRecordRepository.save(record);

          return {
            workerId: record.workerId,
            workerName: record.worker.name,
            success: true,
            transactionId: savedTransaction.id,
          };
        } catch (error) {
          this.logger.error(
            `Failed to process payout for record ${record.id}`,
            error,
          );
          return {
            workerId: record.workerId,
            workerName: record.worker?.name || 'Unknown',
            success: false,
            error: error.message || 'Processing failed',
          };
        }
      });

      const batchResults = await Promise.all(batchPromises);
      allResults.push(...batchResults);

      // Count successes and failures
      batchResults.forEach(result => {
        if (result.success) {
          successCount++;
        } else {
          failureCount++;
        }
      });

      this.logger.log(
        `Processed batch ${Math.floor(i / BATCH_SIZE) + 1}: ${Math.min(i + BATCH_SIZE, payrollRecords.length)}/${payrollRecords.length} workers`,
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
    };
  }
}
