import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { BatchPayrollService } from './batch-payroll.service';
export declare class BatchPayrollController {
    private readonly batchPayrollService;
    constructor(batchPayrollService: BatchPayrollService);
    processBatchPayroll(req: AuthenticatedRequest, body: {
        workerIds: string[];
        processDate?: string;
    }): Promise<import("./interfaces/payroll.interface").BatchPayrollResult>;
    getBatchStatus(req: AuthenticatedRequest, batchId: string): Promise<{
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
    getPayrollHistory(req: AuthenticatedRequest): Promise<{
        transactionId: string;
        workerId: string;
        amount: number;
        status: import("../payments/entities/transaction.entity").TransactionStatus;
        createdAt: Date;
        metadata: any;
    }[]>;
}
