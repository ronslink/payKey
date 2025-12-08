import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { User } from '../users/entities/user.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';

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
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
  ) { }

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

  async getPayrollSummaryByPeriod(userId: string, payPeriodId: string) {
    const payPeriod = await this.payPeriodRepository.findOne({
      where: { id: payPeriodId, userId },
    });

    if (!payPeriod) {
      throw new NotFoundException('Pay period not found');
    }

    const records = await this.payrollRecordRepository.find({
      where: { payPeriodId, userId, status: 'finalized' as any },
      relations: ['worker'],
    });

    const summary = {
      payPeriod: {
        id: payPeriod.id,
        startDate: payPeriod.startDate,
        endDate: payPeriod.endDate,
      },
      totals: {
        grossPay: 0,
        netPay: 0,
        paye: 0,
        nssf: 0,
        nhif: 0,
        housingLevy: 0,
        totalDeductions: 0,
        workerCount: records.length,
      },
      records: records.map(record => {
        const gross = Number(record.grossSalary);
        const net = Number(record.netSalary);
        const paye = Number(record.taxBreakdown?.paye || 0);
        const nssf = Number(record.taxBreakdown?.nssf || 0);
        const nhif = Number(record.taxBreakdown?.nhif || 0);
        const housingLevy = Number(record.taxBreakdown?.housingLevy || 0);
        const totalDeductions = Number(record.taxBreakdown?.totalDeductions || 0);

        summary.totals.grossPay += gross;
        summary.totals.netPay += net;
        summary.totals.paye += paye;
        summary.totals.nssf += nssf;
        summary.totals.nhif += nhif;
        summary.totals.housingLevy += housingLevy;
        summary.totals.totalDeductions += totalDeductions;

        return {
          workerName: record.worker?.name || 'Unknown',
          workerId: record.workerId,
          grossPay: gross,
          netPay: net,
          taxBreakdown: {
            paye,
            nssf,
            nhif,
            housingLevy,
            total: totalDeductions
          }
        };
      }),
    };

    // Round totals
    summary.totals.grossPay = Math.round(summary.totals.grossPay * 100) / 100;
    summary.totals.netPay = Math.round(summary.totals.netPay * 100) / 100;
    summary.totals.paye = Math.round(summary.totals.paye * 100) / 100;
    summary.totals.nssf = Math.round(summary.totals.nssf * 100) / 100;
    summary.totals.nhif = Math.round(summary.totals.nhif * 100) / 100;
    summary.totals.housingLevy = Math.round(summary.totals.housingLevy * 100) / 100;
    summary.totals.totalDeductions = Math.round(summary.totals.totalDeductions * 100) / 100;

    return summary;
  }

  async getStatutoryReport(userId: string, payPeriodId: string) {
    const summary = await this.getPayrollSummaryByPeriod(userId, payPeriodId);

    // Transform summary into Statutory format (P10 style)
    return {
      payPeriod: summary.payPeriod,
      totals: {
        paye: summary.totals.paye,
        nssf: summary.totals.nssf, // In reality, this should be Employer + Employee
        nhif: summary.totals.nhif,
        housingLevy: summary.totals.housingLevy, // Employer + Employee (1.5% * 2) usually
      },
      employees: summary.records.map(r => ({
        name: r.workerName,
        grossPay: r.grossPay,
        nssf: r.taxBreakdown.nssf,
        nhif: r.taxBreakdown.nhif,
        housingLevy: r.taxBreakdown.housingLevy,
        paye: r.taxBreakdown.paye,
      })),
    };
  }

  async getMasterRoll(userId: string, payPeriodId: string) {
    // Alias for Payroll Summary but could contain more attendance data later
    return this.getPayrollSummaryByPeriod(userId, payPeriodId);
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
