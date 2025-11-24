import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    @InjectRepository(LeaveRequest)
    private leaveRequestRepository: Repository<LeaveRequest>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async getMonthlyPayrollReport(userId: string, year: number, month: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const transactions = await this.transactionsRepository.find({
      where: {
        userId,
        type: 'SALARY_PAYOUT' as any,
        createdAt: startDate as any,
      },
    });

    const totalGross = transactions.reduce((sum, t) => sum + t.amount, 0);
    const transactionCount = transactions.length;

    return {
      period: `${year}-${month.toString().padStart(2, '0')}`,
      totalGross: Math.round(totalGross * 100) / 100,
      transactionCount,
      averageAmount:
        transactionCount > 0
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

  async getWorkersSummary(userId: string) {
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

  async getLeaveReport(userId: string, year: number) {
    const workers = await this.workersRepository.find({
      where: { userId },
    });

    const workerIds = workers.map((w) => w.id);

    const leaveRequests = await this.leaveRequestRepository.find({
      where: { workerId: workerIds as any },
      relations: ['worker'],
    });

    const approvedLeaves = leaveRequests.filter((l) => l.status === 'APPROVED');
    const pendingLeaves = leaveRequests.filter((l) => l.status === 'PENDING');
    const rejectedLeaves = leaveRequests.filter((l) => l.status === 'REJECTED');

    const totalLeaveDays = approvedLeaves.reduce(
      (sum, l) => sum + l.totalDays,
      0,
    );

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
        other: approvedLeaves.filter(
          (l) => !['ANNUAL', 'SICK', 'MATERNITY'].includes(l.leaveType),
        ).length,
      },
    };
  }

  async getTaxSummary(userId: string, year: number) {
    // This would integrate with the tax service to get annual tax summaries
    // For now, we'll return a placeholder structure
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

  async getDashboardMetrics(userId: string) {
    const workers = await this.workersRepository.find({
      where: { userId },
    });

    const transactions = await this.transactionsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 10,
    });

    const leaveRequests = await this.leaveRequestRepository.find({
      where: { workerId: workers.map((w) => w.id) as any },
      order: { createdAt: 'DESC' },
      take: 5,
    });

    const currentMonth = new Date();
    const currentMonthTransactions = await this.transactionsRepository
      .createQueryBuilder('transaction')
      .where('transaction.userId = :userId', { userId })
      .andWhere('transaction.type = :type', { type: 'SALARY_PAYOUT' })
      .andWhere('transaction.createdAt >= :startOfMonth', {
        startOfMonth: new Date(
          currentMonth.getFullYear(),
          currentMonth.getMonth(),
          1,
        ),
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
        pendingLeaveRequests: leaveRequests.filter(
          (l) => l.status === 'PENDING',
        ).length,
      },
    };
  }
}
