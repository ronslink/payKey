import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { User } from '../users/entities/user.entity';
export declare class ReportsService {
    private workersRepository;
    private transactionsRepository;
    private leaveRequestRepository;
    private usersRepository;
    constructor(workersRepository: Repository<Worker>, transactionsRepository: Repository<Transaction>, leaveRequestRepository: Repository<LeaveRequest>, usersRepository: Repository<User>);
    getMonthlyPayrollReport(userId: string, year: number, month: number): Promise<{
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
    getWorkersSummary(userId: string): Promise<{
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
    getLeaveReport(userId: string, year: number): Promise<{
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
    getTaxSummary(userId: string, year: number): Promise<{
        year: number;
        totalGrossSalary: number;
        totalPaye: number;
        totalNssf: number;
        totalNhif: number;
        totalHousingLevy: number;
        note: string;
    }>;
    getDashboardMetrics(userId: string): Promise<{
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
