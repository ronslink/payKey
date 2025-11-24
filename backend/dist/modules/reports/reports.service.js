"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const worker_entity_1 = require("../workers/entities/worker.entity");
const transaction_entity_1 = require("../payments/entities/transaction.entity");
const leave_request_entity_1 = require("../workers/entities/leave-request.entity");
const user_entity_1 = require("../users/entities/user.entity");
let ReportsService = class ReportsService {
    workersRepository;
    transactionsRepository;
    leaveRequestRepository;
    usersRepository;
    constructor(workersRepository, transactionsRepository, leaveRequestRepository, usersRepository) {
        this.workersRepository = workersRepository;
        this.transactionsRepository = transactionsRepository;
        this.leaveRequestRepository = leaveRequestRepository;
        this.usersRepository = usersRepository;
    }
    async getMonthlyPayrollReport(userId, year, month) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0, 23, 59, 59);
        const transactions = await this.transactionsRepository.find({
            where: {
                userId,
                type: 'SALARY_PAYOUT',
                createdAt: startDate,
            },
        });
        const totalGross = transactions.reduce((sum, t) => sum + t.amount, 0);
        const transactionCount = transactions.length;
        return {
            period: `${year}-${month.toString().padStart(2, '0')}`,
            totalGross: Math.round(totalGross * 100) / 100,
            transactionCount,
            averageAmount: transactionCount > 0
                ? Math.round((totalGross / transactionCount) * 100) / 100
                : 0,
            transactions: transactions.map((t) => ({
                id: t.id,
                amount: t.amount,
                status: t.status,
                createdAt: t.createdAt,
                metadata: t.metadata,
            })),
        };
    }
    async getWorkersSummary(userId) {
        const workers = await this.workersRepository.find({
            where: { userId },
        });
        const activeWorkers = workers.filter((w) => w.isActive).length;
        const inactiveWorkers = workers.filter((w) => !w.isActive).length;
        const totalMonthlySalary = workers
            .filter((w) => w.isActive)
            .reduce((sum, w) => sum + w.salaryGross, 0);
        return {
            totalWorkers: workers.length,
            activeWorkers,
            inactiveWorkers,
            totalMonthlySalary: Math.round(totalMonthlySalary * 100) / 100,
            workers: workers.map((w) => ({
                id: w.id,
                name: w.name,
                salaryGross: w.salaryGross,
                isActive: w.isActive,
                startDate: w.startDate,
            })),
        };
    }
    async getLeaveReport(userId, year) {
        const workers = await this.workersRepository.find({
            where: { userId },
        });
        const workerIds = workers.map((w) => w.id);
        const leaveRequests = await this.leaveRequestRepository.find({
            where: { workerId: workerIds },
            relations: ['worker'],
        });
        const approvedLeaves = leaveRequests.filter((l) => l.status === 'APPROVED');
        const pendingLeaves = leaveRequests.filter((l) => l.status === 'PENDING');
        const rejectedLeaves = leaveRequests.filter((l) => l.status === 'REJECTED');
        const totalLeaveDays = approvedLeaves.reduce((sum, l) => sum + l.totalDays, 0);
        return {
            year,
            totalLeaveRequests: leaveRequests.length,
            approvedLeaves: approvedLeaves.length,
            pendingLeaves: pendingLeaves.length,
            rejectedLeaves: rejectedLeaves.length,
            totalLeaveDays,
            leaveTypeBreakdown: {
                annual: approvedLeaves.filter((l) => l.leaveType === 'ANNUAL').length,
                sick: approvedLeaves.filter((l) => l.leaveType === 'SICK').length,
                maternity: approvedLeaves.filter((l) => l.leaveType === 'MATERNITY')
                    .length,
                other: approvedLeaves.filter((l) => !['ANNUAL', 'SICK', 'MATERNITY'].includes(l.leaveType)).length,
            },
        };
    }
    async getTaxSummary(userId, year) {
        return {
            year,
            totalGrossSalary: 0,
            totalPaye: 0,
            totalNssf: 0,
            totalNhif: 0,
            totalHousingLevy: 0,
            note: 'Tax summary integration pending',
        };
    }
    async getDashboardMetrics(userId) {
        const workers = await this.workersRepository.find({
            where: { userId },
        });
        const transactions = await this.transactionsRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: 10,
        });
        const leaveRequests = await this.leaveRequestRepository.find({
            where: { workerId: workers.map((w) => w.id) },
            order: { createdAt: 'DESC' },
            take: 5,
        });
        const currentMonth = new Date();
        const currentMonthTransactions = await this.transactionsRepository
            .createQueryBuilder('transaction')
            .where('transaction.userId = :userId', { userId })
            .andWhere('transaction.type = :type', { type: 'SALARY_PAYOUT' })
            .andWhere('transaction.createdAt >= :startOfMonth', {
            startOfMonth: new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1),
        })
            .getCount();
        return {
            workersSummary: {
                total: workers.length,
                active: workers.filter((w) => w.isActive).length,
            },
            currentMonthPayrollTransactions: currentMonthTransactions,
            recentTransactions: transactions.slice(0, 5).map((t) => ({
                id: t.id,
                amount: t.amount,
                status: t.status,
                createdAt: t.createdAt,
            })),
            recentLeaveRequests: leaveRequests.map((l) => ({
                id: l.id,
                workerName: l.worker.name,
                leaveType: l.leaveType,
                status: l.status,
                totalDays: l.totalDays,
                startDate: l.startDate,
            })),
            pendingActions: {
                pendingLeaveRequests: leaveRequests.filter((l) => l.status === 'PENDING').length,
            },
        };
    }
};
exports.ReportsService = ReportsService;
exports.ReportsService = ReportsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __param(1, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __param(2, (0, typeorm_1.InjectRepository)(leave_request_entity_1.LeaveRequest)),
    __param(3, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], ReportsService);
//# sourceMappingURL=reports.service.js.map