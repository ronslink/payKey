import { User } from '../../users/entities/user.entity';
import { Worker } from '../../workers/entities/worker.entity';
import { PayPeriod } from '../../payroll/entities/pay-period.entity';
export declare enum TransactionType {
    SUBSCRIPTION = "SUBSCRIPTION",
    SALARY_PAYOUT = "SALARY_PAYOUT",
    TOPUP = "TOPUP"
}
export declare enum TransactionStatus {
    PENDING = "PENDING",
    SUCCESS = "SUCCESS",
    FAILED = "FAILED"
}
export declare class Transaction {
    id: string;
    user: User;
    userId: string;
    worker: Worker;
    workerId: string;
    amount: number;
    currency: string;
    type: TransactionType;
    status: TransactionStatus;
    providerRef: string;
    propertyId: string;
    metadata: any;
    payPeriod: PayPeriod;
    payPeriodId: string;
    createdAt: Date;
}
