import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollRecord, PayrollStatus } from './entities/payroll-record.entity';
import { PayrollPaymentService } from '../payments/payroll-payment.service';
import { ActivitiesService } from '../activities/activities.service';
export declare class PayrollService {
    private workersRepository;
    private payrollRepository;
    private taxesService;
    private payrollPaymentService;
    private activitiesService;
    constructor(workersRepository: Repository<Worker>, payrollRepository: Repository<PayrollRecord>, taxesService: TaxesService, payrollPaymentService: PayrollPaymentService, activitiesService: ActivitiesService);
    calculatePayrollForUser(userId: string): Promise<{
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
    calculateSingleWorkerPayroll(workerId: string, userId: string): Promise<{
        worker: Worker;
        payrollCalculation: {
            grossSalary: number;
            taxBreakdown: import("../taxes/interfaces/tax.interface").TaxBreakdown;
            netPay: number;
        };
    }>;
    saveDraftPayroll(userId: string, payPeriodId: string, items: Array<{
        workerId: string;
        grossSalary: number;
        bonuses?: number;
        otherEarnings?: number;
        otherDeductions?: number;
    }>): Promise<PayrollRecord[]>;
    updateDraftPayrollItem(userId: string, recordId: string, updates: {
        grossSalary?: number;
        bonuses?: number;
        otherEarnings?: number;
        otherDeductions?: number;
    }): Promise<PayrollRecord>;
    getDraftPayroll(userId: string, payPeriodId: string): Promise<{
        id: string;
        workerId: string;
        workerName: string;
        grossSalary: number;
        bonuses: number;
        otherEarnings: number;
        otherDeductions: number;
        taxBreakdown: Record<string, any>;
        netPay: number;
        status: PayrollStatus;
    }[]>;
    finalizePayroll(userId: string, payPeriodId: string): Promise<{
        finalizedRecords: PayrollRecord[];
        payoutResults: {
            successCount: number;
            failureCount: number;
            results: any[];
        };
    }>;
}
