import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { PayrollService } from './payroll.service';
import { MpesaService } from '../payments/mpesa.service';
import { TaxesService } from '../taxes/taxes.service';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { BatchPayrollRequest, BatchPayrollResult } from './interfaces/payroll.interface';
export declare class BatchPayrollService {
    private workersRepository;
    private transactionsRepository;
    private payrollService;
    private mpesaService;
    private taxesService;
    private taxPaymentsService;
    constructor(workersRepository: Repository<Worker>, transactionsRepository: Repository<Transaction>, payrollService: PayrollService, mpesaService: MpesaService, taxesService: TaxesService, taxPaymentsService: TaxPaymentsService);
    processBatchPayroll(userId: string, batchRequest: BatchPayrollRequest): Promise<BatchPayrollResult>;
    getBatchPayrollStatus(batchId: string, userId: string): Promise<{
        batchId: string;
        totalTransactions: number;
        pendingTransactions: number;
        successfulTransactions: number;
        failedTransactions: number;
        transactions: {
            transactionId: string;
            workerId: string;
            amount: number;
            status: import("../payments/entities/transaction.entity").TransactionStatus;
            createdAt: Date;
            providerRef: string;
        }[];
    }>;
    getUserPayrollHistory(userId: string, limit?: number): Promise<{
        transactionId: string;
        workerId: string;
        amount: number;
        status: import("../payments/entities/transaction.entity").TransactionStatus;
        createdAt: Date;
        metadata: any;
    }[]>;
    accumulateTaxPayments(userId: string, batchId: string, year: number, month: number): Promise<void>;
}
