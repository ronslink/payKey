import { Repository } from 'typeorm';
import { Export, ExportType } from '../entities/export.entity';
import { Transaction } from '../../payments/entities/transaction.entity';
export declare class ExportService {
    private exportRepository;
    private transactionRepository;
    private readonly exportsDir;
    constructor(exportRepository: Repository<Export>, transactionRepository: Repository<Transaction>);
    private getPayrollData;
    generateQuickBooksIIF(userId: string, startDate: Date, endDate: Date): Promise<string>;
    generateXeroCSV(userId: string, startDate: Date, endDate: Date): Promise<string>;
    generateGenericCSV(userId: string, startDate: Date, endDate: Date): Promise<string>;
    createExport(userId: string, exportType: ExportType, startDate: Date, endDate: Date): Promise<Export>;
    getExportHistory(userId: string): Promise<Export[]>;
    getExportFile(id: string, userId: string): Promise<Buffer>;
}
