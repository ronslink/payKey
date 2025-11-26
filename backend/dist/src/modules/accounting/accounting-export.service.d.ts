import { Repository } from 'typeorm';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { AccountMapping, AccountCategory } from './entities/account-mapping.entity';
import { AccountingExport } from './entities/accounting-export.entity';
export interface JournalEntry {
    date: Date;
    account: string;
    accountName: string;
    debit: number;
    credit: number;
    description: string;
}
export interface JournalEntrySet {
    entries: JournalEntry[];
    totalDebits: number;
    totalCredits: number;
    isBalanced: boolean;
}
export declare class AccountingExportService {
    private payrollRecordRepository;
    private accountMappingRepository;
    private accountingExportRepository;
    constructor(payrollRecordRepository: Repository<PayrollRecord>, accountMappingRepository: Repository<AccountMapping>, accountingExportRepository: Repository<AccountingExport>);
    generateJournalEntries(payPeriodId: string, userId: string): Promise<JournalEntrySet>;
    exportToCSV(payPeriodId: string, userId: string): Promise<string>;
    getAccountMappings(userId: string): Promise<Record<AccountCategory, {
        accountCode: string;
        accountName: string;
    }>>;
    getDefaultAccountMappings(): Record<AccountCategory, {
        accountCode: string;
        accountName: string;
    }>;
    saveAccountMappings(userId: string, mappings: Array<{
        category: AccountCategory;
        accountCode: string;
        accountName: string;
    }>): Promise<AccountMapping[]>;
    private aggregatePayrollTotals;
}
