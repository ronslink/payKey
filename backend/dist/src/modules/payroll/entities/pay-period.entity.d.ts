import { TaxSubmission } from '../../taxes/entities/tax-submission.entity';
export declare enum PayPeriodFrequency {
    WEEKLY = "WEEKLY",
    BIWEEKLY = "BIWEEKLY",
    MONTHLY = "MONTHLY",
    QUARTERLY = "QUARTERLY"
}
export declare enum PayPeriodStatus {
    DRAFT = "DRAFT",
    ACTIVE = "ACTIVE",
    PROCESSING = "PROCESSING",
    COMPLETED = "COMPLETED",
    CLOSED = "CLOSED"
}
export declare class PayPeriod {
    id: string;
    name: string;
    startDate: Date;
    endDate: Date;
    userId: string;
    payDate: string;
    frequency: PayPeriodFrequency;
    status: PayPeriodStatus;
    totalGrossAmount: number;
    totalNetAmount: number;
    totalTaxAmount: number;
    totalWorkers: number;
    processedWorkers: number;
    notes: Record<string, any>;
    createdBy: string;
    approvedBy: string;
    approvedAt: Date;
    processedAt: Date;
    createdAt: Date;
    updatedAt: Date;
    taxSubmissions: TaxSubmission[];
    transactions: any[];
}
