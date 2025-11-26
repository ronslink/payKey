import { User } from '../../users/entities/user.entity';
export declare enum ExportType {
    QUICKBOOKS_IIF = "QUICKBOOKS_IIF",
    XERO_CSV = "XERO_CSV",
    GENERIC_CSV = "GENERIC_CSV",
    EXCEL = "EXCEL"
}
export declare class Export {
    id: string;
    user: User;
    userId: string;
    exportType: ExportType;
    startDate: Date;
    endDate: Date;
    fileName: string;
    filePath: string;
    recordCount: number;
    createdAt: Date;
}
