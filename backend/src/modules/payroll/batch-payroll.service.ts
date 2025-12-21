import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { PayrollService } from './payroll.service';
import { MpesaService } from '../payments/mpesa.service';
import { TaxesService } from '../taxes/taxes.service';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import {
  BatchPayrollRequest,
  PayrollPaymentResult,
  BatchPayrollResult,
} from './interfaces/payroll.interface';

@Injectable()
export class BatchPayrollService {
  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    private payrollService: PayrollService,
    private mpesaService: MpesaService,
    private taxesService: TaxesService,
    private taxPaymentsService: TaxPaymentsService,
  ) { }

  async processBatchPayroll(
    userId: string,
    batchRequest: BatchPayrollRequest,
  ): Promise<BatchPayrollResult> {
    // Get all workers for the user
    const allWorkers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    // Filter to only include requested workers
    const selectedWorkers = allWorkers.filter((worker) =>
      batchRequest.workerIds.includes(worker.id),
    );

    if (selectedWorkers.length !== batchRequest.workerIds.length) {
      throw new BadRequestException('Some workers not found or not active');
    }

    const batchId = `batch_${Date.now()}_${userId}`;
    const results: PayrollPaymentResult[] = [];

    // Process each worker's payroll
    for (const worker of selectedWorkers) {
      try {
        const processDate = new Date(batchRequest.processDate);
        // Calculate adjusted salary based on leave
        const { adjustedGross, deduction, leaveDays } =
          await this.payrollService.calculateAdjustedSalary(worker, {
            year: processDate.getFullYear(),
            month: processDate.getMonth() + 1,
          });

        // Calculate payroll taxes on ADJUSTED gross
        const taxBreakdown = await this.taxesService.calculateTaxes(
          adjustedGross,
        );
        const netPay = adjustedGross - taxBreakdown.totalDeductions;

        // Create transaction record
        const transaction = this.transactionsRepository.create({
          userId,
          workerId: worker.id,
          amount: netPay,
          type: 'SALARY_PAYOUT' as any,
          status: 'PENDING' as any,
          metadata: {
            grossSalary: worker.salaryGross,
            taxBreakdown,
            batchId,
            processDate: batchRequest.processDate.toISOString(),
          },
        });

        const savedTransaction =
          await this.transactionsRepository.save(transaction);

        // Initiate M-Pesa B2C payment
        const paymentResult = await this.mpesaService.sendB2C(
          savedTransaction.id,
          worker.phoneNumber,
          netPay,
          `Salary Payment - ${batchId}`,
        );

        let paymentStatus: 'SUCCESS' | 'FAILED' | 'PENDING' = 'PENDING';
        let errorMessage: string | undefined;

        if (paymentResult.error) {
          paymentStatus = 'FAILED';
          errorMessage = paymentResult.error;
        } else {
          paymentStatus = 'PENDING'; // Will be updated by callback
        }

        results.push({
          workerId: worker.id,
          workerName: worker.name,
          grossSalary: worker.salaryGross,
          netPay: Math.round(netPay * 100) / 100,
          paymentStatus,
          transactionId: savedTransaction.id,
          errorMessage,
        });
      } catch (error) {
        results.push({
          workerId: worker.id,
          workerName: worker.name,
          grossSalary: worker.salaryGross,
          netPay: 0,
          paymentStatus: 'FAILED',
          errorMessage: error.message,
        });
      }
    }

    const successfulPayments = results.filter(
      (r) => r.paymentStatus === 'SUCCESS',
    ).length;
    const failedPayments = results.filter(
      (r) => r.paymentStatus === 'FAILED',
    ).length;

    // Accumulate tax payments for successful payroll
    if (successfulPayments > 0) {
      const processDate = batchRequest.processDate;
      await this.accumulateTaxPayments(
        userId,
        batchId,
        processDate.getFullYear(),
        processDate.getMonth() + 1, // JavaScript months are 0-indexed
      );
    }

    return {
      batchId,
      totalWorkers: selectedWorkers.length,
      successfulPayments,
      failedPayments,
      results,
    };
  }

  async getBatchPayrollStatus(batchId: string, userId: string) {
    const transactions = await this.transactionsRepository.find({
      where: {
        userId,
        metadata: { batchId } as any,
      },
      relations: ['workerId'],
    });

    return {
      batchId,
      totalTransactions: transactions.length,
      pendingTransactions: transactions.filter((t) => t.status === 'PENDING')
        .length,
      successfulTransactions: transactions.filter((t) => t.status === 'SUCCESS')
        .length,
      failedTransactions: transactions.filter((t) => t.status === 'FAILED')
        .length,
      transactions: transactions.map((t) => ({
        transactionId: t.id,
        workerId: t.workerId,
        amount: t.amount,
        status: t.status,
        createdAt: t.createdAt,
        providerRef: t.providerRef,
      })),
    };
  }

  async getUserPayrollHistory(userId: string, limit = 10) {
    const transactions = await this.transactionsRepository.find({
      where: { userId, type: 'SALARY_PAYOUT' as any },
      order: { createdAt: 'DESC' },
      take: limit,
    });

    return transactions.map((transaction) => ({
      transactionId: transaction.id,
      workerId: transaction.workerId,
      amount: transaction.amount,
      status: transaction.status,
      createdAt: transaction.createdAt,
      metadata: transaction.metadata,
    }));
  }

  /**
   * Accumulate tax payments when payroll is finalized
   * This ensures employer tax obligations are tracked
   */
  async accumulateTaxPayments(
    userId: string,
    batchId: string,
    year: number,
    month: number,
  ): Promise<void> {
    try {
      // Get all transactions for this batch
      const transactions = await this.transactionsRepository.find({
        where: {
          userId,
          metadata: { batchId } as any,
          status: 'SUCCESS' as any,
        },
      });

      if (transactions.length === 0) {
        return;
      }

      // Calculate accumulated taxes from successful transactions
      let totalNssf = 0;
      let totalShif = 0;
      let totalHousingLevy = 0;
      let totalPaye = 0;

      for (const transaction of transactions) {
        const metadata = transaction.metadata;
        if (metadata?.taxBreakdown) {
          totalNssf += metadata.taxBreakdown.nssf || 0;
          totalShif += metadata.taxBreakdown.nhif || 0;
          totalHousingLevy += metadata.taxBreakdown.housingLevy || 0;
          totalPaye += metadata.taxBreakdown.paye || 0;
        }
      }

      // Log the accumulated tax obligations for the month
      console.log(`Tax obligations accumulated for ${year}-${month}:`);
      console.log(`NSSF: ${totalNssf}`);
      console.log(`SHIF: ${totalShif}`);
      console.log(`Housing Levy: ${totalHousingLevy}`);
      console.log(`PAYE: ${totalPaye}`);
      console.log(
        `Total: ${totalNssf + totalShif + totalHousingLevy + totalPaye}`,
      );

      // Here you could also create TaxPayment records if needed
      // This would be useful for generating tax payment summaries
      // await this.taxPaymentsService.recordPayment(userId, {
      //   taxType: TaxType.NSSF_TIER1,
      //   amount: totalNssf,
      //   paymentYear: year,
      //   paymentMonth: month,
      // });
    } catch (error) {
      console.error('Error accumulating tax payments:', error);
      // Don't throw error - tax accumulation is secondary to payroll
    }
  }
}
