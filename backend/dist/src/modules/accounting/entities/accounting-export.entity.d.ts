import { PayPeriod } from '../../payroll/entities/pay-period.entity';
export declare enum ExportFormat {
    CSV = "CSV",
    EXCEL = "EXCEL",
    QUICKBOOKS = "QUICKBOOKS",
    XERO = "XERO",
    SAGE = "SAGE"
}
export declare enum ExportStatus {
    PENDING = "PENDING",
    COMPLETED = "COMPLETED",
    FAILED = "FAILED"
}
export declare class AccountingExport {
    id: string;
    userId: string;
    payPeriod: PayPeriod;
    payPeriodId: string;
    format: ExportFormat;
    status: ExportStatus;
    filePath: string;
    externalId: string;
    errorMessage: string;
    createdAt: Date;
}
