import { PayPeriod } from '../../payroll/entities/pay-period.entity';
export declare enum TaxSubmissionStatus {
    PENDING = "PENDING",
    FILED = "FILED"
}
export declare class TaxSubmission {
    id: string;
    userId: string;
    payPeriod: PayPeriod;
    payPeriodId: string;
    totalPaye: number;
    totalNssf: number;
    totalNhif: number;
    totalHousingLevy: number;
    status: TaxSubmissionStatus;
    filingDate: Date;
    createdAt: Date;
    updatedAt: Date;
}
