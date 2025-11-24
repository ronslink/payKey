import { ReportsService } from './reports.service';
export declare class ReportsController {
    private readonly reportsService;
    constructor(reportsService: ReportsService);
    getMonthlyPayrollReport(req: any, year: string, month: string): Promise<{
        period: string;
        totalGross: number;
        transactionCount: number;
        averageAmount: number;
        transactions: {
            id: string;
            amount: number;
            status: import("../payments/entities/transaction.entity").TransactionStatus;
            createdAt: Date;
            metadata: any;
        }[];
    }>;
    getWorkersSummary(req: any): Promise<{
        totalWorkers: number;
        activeWorkers: number;
        inactiveWorkers: number;
        totalMonthlySalary: number;
        workers: {
            id: string;
            name: string;
            salaryGross: number;
            isActive: boolean;
            startDate: Date;
        }[];
    }>;
    getLeaveReport(req: any, year: string): Promise<{
        year: number;
        totalLeaveRequests: number;
        approvedLeaves: number;
        pendingLeaves: number;
        rejectedLeaves: number;
        totalLeaveDays: number;
        leaveTypeBreakdown: {
            annual: number;
            sick: number;
            maternity: number;
            other: number;
        };
    }>;
    getTaxSummary(req: any, year: string): Promise<{
        year: number;
        totalGrossSalary: number;
        totalPaye: number;
        totalNssf: number;
        totalNhif: number;
        totalHousingLevy: number;
        note: string;
    }>;
    getDashboardMetrics(req: any): Promise<{
        workersSummary: {
            total: number;
            active: number;
        };
        currentMonthPayrollTransactions: number;
        recentTransactions: {
            id: string;
            amount: number;
            status: import("../payments/entities/transaction.entity").TransactionStatus;
            createdAt: Date;
        }[];
        recentLeaveRequests: {
            id: string;
            workerName: string;
            leaveType: import("../workers/entities/leave-request.entity").LeaveType;
            status: import("../workers/entities/leave-request.entity").LeaveStatus;
            totalDays: number;
            startDate: Date;
        }[];
        pendingActions: {
            pendingLeaveRequests: number;
        };
    }>;
}
