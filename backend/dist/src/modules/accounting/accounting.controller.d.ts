import { AccountingExportService } from './accounting-export.service';
import { AccountCategory } from './entities/account-mapping.entity';
declare class SaveMappingsDto {
    mappings: Array<{
        category: AccountCategory;
        accountCode: string;
        accountName: string;
    }>;
}
export declare class AccountingController {
    private readonly accountingExportService;
    constructor(accountingExportService: AccountingExportService);
    exportPayroll(req: any, payPeriodId: string, format?: string): Promise<{
        format: string;
        data: string;
        filename: string;
    }>;
    getAvailableFormats(): {
        formats: ({
            id: string;
            name: string;
            description: string;
            disabled?: undefined;
        } | {
            id: string;
            name: string;
            description: string;
            disabled: boolean;
        })[];
    };
    saveAccountMappings(req: any, dto: SaveMappingsDto): Promise<{
        success: boolean;
        mappings: import("./entities/account-mapping.entity").AccountMapping[];
    }>;
    getAccountMappings(req: any): Promise<{
        mappings: Record<AccountCategory, {
            accountCode: string;
            accountName: string;
        }>;
    }>;
    getDefaultMappings(): {
        defaults: Record<AccountCategory, {
            accountCode: string;
            accountName: string;
        }>;
    };
    generateJournalEntries(req: any, payPeriodId: string): Promise<import("./accounting-export.service").JournalEntrySet>;
}
export {};
