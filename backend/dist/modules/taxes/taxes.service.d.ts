import { Repository } from 'typeorm';
import { TaxTable } from './entities/tax-table.entity';
import { TaxSubmission } from './entities/tax-submission.entity';
import { TaxBreakdown, PayrollCalculation } from './interfaces/tax.interface';
import { UsersService } from '../users/users.service';
export declare class TaxesService {
    private taxTableRepository;
    private taxSubmissionRepository;
    private usersService;
    constructor(taxTableRepository: Repository<TaxTable>, taxSubmissionRepository: Repository<TaxSubmission>, usersService: UsersService);
    createTaxTable(data: Partial<TaxTable>): Promise<TaxTable>;
    getTaxTables(): Promise<TaxTable[]>;
    getTaxTable(date: Date): Promise<TaxTable>;
    private getDefaultTaxTable;
    private calculateNSSF;
    private calculateNHIF;
    private calculateHousingLevy;
    private calculatePAYE;
    calculateTaxes(grossSalary: number, date?: Date): Promise<TaxBreakdown>;
    calculateNetPay(grossSalary: number): Promise<number>;
    calculatePayroll(workerId: string, workerName: string, grossSalary: number): Promise<PayrollCalculation>;
    getMonthlyPayrollSummary(userId?: string, year?: number, month?: number): Promise<{
        totalGross: number;
        totalPaye: number;
        totalNssf: number;
        totalShif: number;
        totalHousingLevy: number;
    }>;
    getSubmissions(userId: string): Promise<TaxSubmission[]>;
    markAsFiled(id: string, userId: string): Promise<TaxSubmission>;
    getComplianceStatus(userId: string): Promise<{
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
}
