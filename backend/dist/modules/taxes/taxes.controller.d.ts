import { TaxesService } from './taxes.service';
import { TaxTable } from './entities/tax-table.entity';
declare class CalculateTaxDto {
    grossSalary: number;
}
export declare class TaxesController {
    private readonly taxesService;
    constructor(taxesService: TaxesService);
    calculateTaxes(dto: CalculateTaxDto): Promise<import("./interfaces/tax.interface").TaxBreakdown>;
    createTaxTable(taxTableData: Partial<TaxTable>): Promise<TaxTable>;
    getComplianceStatus(req: any): Promise<{
        kraPin: boolean;
        nssf: boolean;
        nhif: boolean;
        isCompliant: boolean;
    }>;
    getUpcomingDeadlines(): {
        title: string;
        dueDate: Date;
        description: string;
    }[];
    getTaxTables(): Promise<TaxTable[]>;
    getSubmissions(req: any): Promise<import("./entities/tax-submission.entity").TaxSubmission[]>;
    markAsFiled(req: any, id: string): Promise<import("./entities/tax-submission.entity").TaxSubmission>;
    getCurrentTaxTable(): Promise<TaxTable>;
}
export {};
