import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { PayrollService } from './payroll.service';
export declare class PayrollController {
    private readonly payrollService;
    constructor(payrollService: PayrollService);
    calculatePayroll(req: AuthenticatedRequest): Promise<{
        payrollItems: {
            workerId: string;
            workerName: string;
            grossSalary: number;
            taxBreakdown: import("../taxes/interfaces/tax.interface").TaxBreakdown;
            netPay: number;
            phoneNumber: string;
        }[];
        summary: {
            totalGross: number;
            totalDeductions: number;
            totalNetPay: number;
            workerCount: number;
        };
    }>;
    calculatePayrollForWorkers(req: AuthenticatedRequest, body: {
        workerIds: string[];
        startDate?: string;
        endDate?: string;
    }): Promise<{
        payrollItems: {
            workerId: string;
            workerName: string;
            grossSalary: number;
            taxBreakdown: import("../taxes/interfaces/tax.interface").TaxBreakdown;
            netPay: number;
            phoneNumber: string;
        }[];
        summary: {
            totalGross: number;
            totalDeductions: number;
            totalNetPay: number;
            workerCount: number;
        };
    }>;
    calculateSingleWorkerPayroll(req: AuthenticatedRequest, workerId: string): Promise<{
        worker: import("../workers/entities/worker.entity").Worker;
        payrollCalculation: {
            grossSalary: number;
            taxBreakdown: import("../taxes/interfaces/tax.interface").TaxBreakdown;
            netPay: number;
        };
    }>;
    processPayroll(req: AuthenticatedRequest, body: {
        workerIds: string[];
    }): Promise<{
        payrollItems: {
            workerId: string;
            workerName: string;
            grossSalary: number;
            taxBreakdown: import("../taxes/interfaces/tax.interface").TaxBreakdown;
            netPay: number;
            phoneNumber: string;
        }[];
        message: string;
        summary: {
            totalGross: number;
            totalDeductions: number;
            totalNetPay: number;
            workerCount: number;
        };
    }>;
    saveDraftPayroll(req: AuthenticatedRequest, body: {
        payPeriodId: string;
        payrollItems: Array<{
            workerId: string;
            grossSalary: number;
            bonuses?: number;
            otherEarnings?: number;
            otherDeductions?: number;
        }>;
    }): Promise<import("./entities/payroll-record.entity").PayrollRecord[]>;
    updateDraftPayrollItem(req: AuthenticatedRequest, payrollRecordId: string, body: {
        grossSalary?: number;
        bonuses?: number;
        otherEarnings?: number;
        otherDeductions?: number;
    }): Promise<import("./entities/payroll-record.entity").PayrollRecord>;
    getDraftPayroll(req: AuthenticatedRequest, payPeriodId: string): Promise<{
        id: string;
        workerId: string;
        workerName: string;
        grossSalary: number;
        bonuses: number;
        otherEarnings: number;
        otherDeductions: number;
        taxBreakdown: Record<string, any>;
        netPay: number;
        status: import("./entities/payroll-record.entity").PayrollStatus;
    }[]>;
    finalizePayroll(req: AuthenticatedRequest, payPeriodId: string): Promise<import("./entities/payroll-record.entity").PayrollRecord[]>;
}
