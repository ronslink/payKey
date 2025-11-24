import { Worker } from '../../workers/entities/worker.entity';
export declare enum PayrollStatus {
    DRAFT = "draft",
    FINALIZED = "finalized",
    PAID = "paid"
}
export declare class PayrollRecord {
    id: string;
    userId: string;
    workerId: string;
    payPeriodId: string;
    worker: Worker;
    periodStart: Date;
    periodEnd: Date;
    grossSalary: number;
    bonuses: number;
    otherEarnings: number;
    otherDeductions: number;
    netSalary: number;
    taxAmount: number;
    status: PayrollStatus;
    paymentStatus: string;
    paymentMethod: string;
    paymentDate: Date;
    finalizedAt: Date;
    taxBreakdown: Record<string, any>;
    deductions: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}
