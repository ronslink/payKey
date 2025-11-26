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
  ) {}

  /**
   * Process payouts for a list of finalized payroll records
   */
  async processPayouts(payrollRecords: PayrollRecord[]): Promise<{
    successCount: number;
    failureCount: number;
    results: any[];
  }> {
    const results = [];
    let successCount = 0;
    let failureCount = 0;

    for (const record of payrollRecords) {
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
        // Note: In a real scenario, we might queue this or handle it asynchronously
        const b2cResult = await this.mpesaService.sendB2C(
          savedTransaction.id,
          record.worker.phoneNumber,
          Number(record.netSalary),
          `Salary Payment`,
        );

        if (b2cResult.error) {
          results.push({
            workerId: record.workerId,
            workerName: record.worker.name,
            success: false,
            error: b2cResult.error,
          });

          record.paymentStatus = 'failed';
          await this.payrollRecordRepository.save(record);

          failureCount++;
          continue;
        }

        // Update record status
        record.paymentStatus = 'processing'; // Will be updated to 'paid' via callback
        record.paymentDate = new Date();
        await this.payrollRecordRepository.save(record);

        results.push({
          workerId: record.workerId,
          workerName: record.worker.name,
          success: true,
          transactionId: savedTransaction.id,
        });

        successCount++;
      } catch (error) {
        this.logger.error(
          `Failed to process payout for record ${record.id}`,
          error,
        );
        results.push({
          workerId: record.workerId,
          workerName: record.worker?.name || 'Unknown',
          success: false,
          error: error.message || 'Processing failed',
        });
        failureCount++;
      }
    }

    return {
      successCount,
      failureCount,
      results,
    };
  }
}
