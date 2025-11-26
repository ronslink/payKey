import { Worker } from './worker.entity';
import { User } from '../../users/entities/user.entity';
export declare enum TerminationReason {
    RESIGNATION = "RESIGNATION",
    DISMISSAL = "DISMISSAL",
    CONTRACT_END = "CONTRACT_END",
    ILLNESS = "ILLNESS",
    DEATH = "DEATH",
    RETIREMENT = "RETIREMENT",
    REDUNDANCY = "REDUNDANCY",
    OTHER = "OTHER"
}
export declare class Termination {
    id: string;
    worker: Worker;
    workerId: string;
    user: User;
    userId: string;
    reason: TerminationReason;
    terminationDate: Date;
    lastWorkingDate: Date;
    noticePeriodDays: number;
    notes: string;
    proratedSalary: number;
    unusedLeavePayout: number;
    severancePay: number;
    totalFinalPayment: number;
    paymentBreakdown: {
        daysWorked: number;
        dailyRate: number;
        unusedLeaveDays: number;
        taxDeductions: any;
        severancePay?: number;
        outstandingPayments?: number;
    };
    createdAt: Date;
}
