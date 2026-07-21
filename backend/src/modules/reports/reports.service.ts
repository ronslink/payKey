import {
  Injectable,
  NotFoundException,
  StreamableFile,
  Inject,
  Optional,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, In } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { Worker } from '../workers/entities/worker.entity';

const PDFDocument = require('pdfkit');
import archiver from 'archiver';
import { Readable } from 'stream';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { User } from '../users/entities/user.entity';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';

// Cache TTLs
const DASHBOARD_CACHE_TTL = 5 * 60 * 1000; // 5 minutes for dashboard
const P9_CACHE_TTL = 60 * 60 * 1000; // 1 hour for P9 reports (rarely change)
const STATUTORY_CACHE_TTL = 15 * 60 * 1000; // 15 minutes for statutory reports

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(
    @InjectRepository(Worker)
    private readonly workersRepository: Repository<Worker>,
    @InjectRepository(Transaction)
    private readonly transactionsRepository: Repository<Transaction>,
    @InjectRepository(LeaveRequest)
    private readonly leaveRequestRepository: Repository<LeaveRequest>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private readonly payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(TaxSubmission)
    private readonly taxSubmissionRepository: Repository<TaxSubmission>,
    @Optional() @Inject(CACHE_MANAGER) private readonly cacheManager?: Cache,
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

    // Handle empty workers array to avoid invalid UUID query
    if (workerIds.length === 0) {
      return {
        year,
        totalLeaveRequests: 0,
        approvedLeaves: 0,
        pendingLeaves: 0,
        rejectedLeaves: 0,
        totalLeaveDays: 0,
        leaveTypeBreakdown: {
          annual: 0,
          sick: 0,
          maternity: 0,
          other: 0,
        },
      };
    }

    const leaveRequests = await this.leaveRequestRepository.find({
      where: { workerId: In(workerIds) },
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
    console.log(
      `Getting payroll summary for user ${userId} and period ${payPeriodId}`,
    );
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

    const totals = {
      grossPay: 0,
      netPay: 0,
      paye: 0,
      nssf: 0,
      nhif: 0,
      housingLevy: 0,
      totalDeductions: 0,
      workerCount: records.length,
    };

    const mappedRecords = records.map((record) => {
      const gross = Number(record.grossSalary);
      const net = Number(record.netSalary);
      const paye = Number(record.taxBreakdown?.paye || 0);
      const nssf = Number(record.taxBreakdown?.nssf || 0);
      const nhif = Number(record.taxBreakdown?.nhif || 0);
      const housingLevy = Number(record.taxBreakdown?.housingLevy || 0);
      const totalDeductions = Number(record.taxBreakdown?.totalDeductions || 0);

      totals.grossPay += gross;
      totals.netPay += net;
      totals.paye += paye;
      totals.nssf += nssf;
      totals.nhif += nhif;
      totals.housingLevy += housingLevy;
      totals.totalDeductions += totalDeductions;

      return {
        id: record.id,
        workerName: record.worker?.name || 'Unknown',
        workerId: record.workerId,
        grossPay: gross,
        netPay: net,
        taxBreakdown: {
          paye,
          nssf,
          nhif,
          housingLevy,
          total: totalDeductions,
        },
      };
    });

    const summary = {
      payPeriod: {
        id: payPeriod.id,
        startDate: payPeriod.startDate,
        endDate: payPeriod.endDate,
      },
      totals: totals,
      records: mappedRecords,
    };

    // Round totals
    summary.totals.grossPay = Math.round(summary.totals.grossPay * 100) / 100;
    summary.totals.netPay = Math.round(summary.totals.netPay * 100) / 100;
    summary.totals.paye = Math.round(summary.totals.paye * 100) / 100;
    summary.totals.nssf = Math.round(summary.totals.nssf * 100) / 100;
    summary.totals.nhif = Math.round(summary.totals.nhif * 100) / 100;
    summary.totals.housingLevy =
      Math.round(summary.totals.housingLevy * 100) / 100;
    summary.totals.totalDeductions =
      Math.round(summary.totals.totalDeductions * 100) / 100;

    return summary;
  }

  async getPropertyTimeReport(
    userId: string,
    startDateStr: string,
    endDateStr: string,
  ) {
    const startDate = new Date(startDateStr);
    const endDate = new Date(endDateStr);

    const timeEntries = await this.workersRepository.manager.query(
      `
      SELECT p.id as "propertyId", p.name as "propertyName", SUM(t."totalHours") as "totalHours"
      FROM time_entries t
      JOIN properties p on t."propertyId" = p.id
      WHERE t."userId" = $1 AND t."clockIn" BETWEEN $2 AND $3 AND t.status = 'COMPLETED'
      GROUP BY p.id, p.name
      ORDER BY p.name ASC
    `,
      [userId, startDate, endDate],
    );

    return timeEntries.map((e: any) => ({
      propertyId: e.propertyId,
      propertyName: e.propertyName,
      totalHours: Math.round((Number(e.totalHours) || 0) * 100) / 100,
    }));
  }

  async getStatutoryReport(userId: string, payPeriodId: string) {
    const summary = await this.getPayrollSummaryByPeriod(userId, payPeriodId);

    // Transform summary into Statutory format (P10 style)
    return {
      payPeriod: summary.payPeriod,
      totals: {
        grossPay: summary.totals.grossPay,
        netPay: summary.totals.netPay,
        paye: summary.totals.paye,
        nssf: summary.totals.nssf,
        nhif: summary.totals.nhif,
        housingLevy: summary.totals.housingLevy,
        totalDeductions: summary.totals.totalDeductions,
        workerCount: summary.totals.workerCount,
      },
      employees: summary.records.map((r) => ({
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

    // Handle empty workers array to avoid invalid UUID query
    const workerIds = workers.map((w) => w.id);
    const leaveRequests =
      workerIds.length > 0
        ? await this.leaveRequestRepository.find({
            where: { workerId: In(workerIds) },
            order: { createdAt: 'DESC' },
            take: 5,
            relations: ['worker'],
          })
        : [];

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

  private emptyP9Month(month: number) {
    return {
      month,
      basicSalary: 0,
      benefits: 0,
      valueOfQuarters: 0,
      grossPay: 0,
      contribution: 0,
      housingLevy: 0,
      shif: 0,
      postRetirementMedical: 0,
      ownerOccupiedInterest: 0,
      taxablePay: 0,
      taxCharged: 0,
      relief: 0,
      insuranceRelief: 0,
      paye: 0,
    };
  }

  private buildP9Month(record: PayrollRecord) {
    const tax = record.taxBreakdown || {};
    const cashPay =
      Number(record.grossSalary || 0) +
      Number(record.bonuses || 0) +
      Number(record.otherEarnings || 0) +
      Number(record.overtimePay || 0);
    const benefits = Number(record.nonCashBenefits || 0);
    const grossPay = cashPay + benefits;
    const nssf = Number(tax.nssf || 0);
    const shif = Number(tax.nhif || tax.shif || 0);
    const housingLevy = Number(tax.housingLevy || 0);
    const contribution = Number(
      tax.allowablePensionDeduction ??
        Math.min(30000, nssf + Number(record.worker?.pensionContribution || 0)),
    );
    const postRetirementMedical = Number(
      tax.allowablePostRetirementMedicalContribution ??
        Math.min(
          15000,
          Number(record.worker?.postRetirementMedicalContribution || 0),
        ),
    );
    const ownerOccupiedInterest = Number(
      tax.allowableMortgageInterest ??
        Math.min(30000, Number(record.worker?.mortgageInterest || 0)),
    );
    const paye = Number(tax.paye || 0);
    const relief = Number(tax.personalReliefApplied ?? (paye > 0 ? 2400 : 0));
    const insuranceRelief = Number(
      tax.insuranceReliefApplied ??
        (paye > 0
          ? Math.min(
              5000,
              Number(record.worker?.lifeInsurancePremium || 0) * 0.15,
            )
          : 0),
    );
    const taxablePay = Number(
      tax.taxablePay ??
        Math.max(
          0,
          grossPay -
            contribution -
            housingLevy -
            shif -
            postRetirementMedical -
            ownerOccupiedInterest,
        ),
    );

    return {
      month: new Date(record.periodStart).getMonth() + 1,
      basicSalary: cashPay,
      benefits,
      valueOfQuarters: 0,
      grossPay,
      contribution,
      housingLevy,
      shif,
      postRetirementMedical,
      ownerOccupiedInterest,
      taxablePay,
      taxCharged: Number(tax.taxCharged ?? paye + relief + insuranceRelief),
      relief,
      insuranceRelief,
      paye,
    };
  }

  async getP9Report(userId: string, year: number, workerId?: string) {
    console.log(
      `Getting P9 report for user ${userId}, year ${year}, worker ${workerId || 'ALL'}`,
    );
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);
    const employer = await this.usersRepository.findOne({
      where: { id: userId },
    });
    const employerName =
      employer?.businessName ||
      [employer?.firstName, employer?.lastName].filter(Boolean).join(' ') ||
      '';

    const whereClause: any = {
      userId,
      periodStart: Between(startDate, endDate),
      status: PayrollStatus.FINALIZED,
    };

    if (workerId) {
      whereClause.workerId = workerId;
    }

    const records = await this.payrollRecordRepository.find({
      where: whereClause,
      relations: ['worker'],
      order: { periodStart: 'ASC' },
    });

    if (!records.length) {
      return [];
    }

    // Group by worker
    const workerReports: Record<string, any> = {};

    for (const record of records) {
      if (!workerReports[record.workerId]) {
        workerReports[record.workerId] = {
          year,
          workerId: record.workerId,
          workerName: record.worker?.name || 'Unknown',
          kraPin: record.worker?.kraPin || '',
          employerName,
          employerPin: employer?.kraPin || '',
          months: Array(12)
            .fill(null)
            .map((_, i) => this.emptyP9Month(i + 1)),
          totals: {
            basicSalary: 0,
            grossPay: 0,
            paye: 0,
          },
        };
      }

      const monthIndex = new Date(record.periodStart).getMonth();
      const report = workerReports[record.workerId];
      const monthData = this.buildP9Month(record);

      if (report.months[monthIndex]) {
        report.months[monthIndex] = monthData;
      }

      report.totals.basicSalary += monthData.basicSalary;
      report.totals.grossPay += monthData.grossPay;
      report.totals.paye += monthData.paye;
    }

    return Object.values(workerReports);
  }

  async getP10Report(userId: string, year: number) {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);

    const submissions = await this.taxSubmissionRepository.find({
      where: {
        userId,
        payPeriod: {
          startDate: Between(startDate, endDate),
        },
      },
      relations: ['payPeriod'],
      order: { payPeriod: { startDate: 'ASC' } } as any,
    });

    const monthlyReturns = submissions.map((sub) => {
      const paye = Number(sub.totalPaye);
      const nssf = Number(sub.totalNssf);
      const nhif = Number(sub.totalNhif);
      const housing = Number(sub.totalHousingLevy);

      return {
        month: sub.payPeriod.startDate.getMonth() + 1,
        periodName: sub.payPeriod.name,
        paye,
        nssf,
        nhif,
        housingLevy: housing,
        totalTax: paye + nssf + nhif + housing,
        status: sub.status,
      };
    });

    const annualTotals = monthlyReturns.reduce(
      (acc, m) => ({
        paye: acc.paye + m.paye,
        nssf: acc.nssf + m.nssf,
        nhif: acc.nhif + m.nhif,
        housingLevy: acc.housingLevy + m.housingLevy,
        totalTax: acc.totalTax + m.totalTax,
      }),
      { paye: 0, nssf: 0, nhif: 0, housingLevy: 0, totalTax: 0 },
    );

    const employer = await this.usersRepository.findOne({
      where: { id: userId },
    });

    return {
      year,
      employerName:
        employer?.businessName ||
        [employer?.firstName, employer?.lastName].filter(Boolean).join(' ') ||
        '',
      monthlyReturns,
      annualTotals,
    };
  }

  async getEmployeeP9Report(userId: string, year: number, workerId?: string) {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);

    let worker;
    if (workerId) {
      worker = await this.workersRepository.findOne({
        where: { id: workerId },
      }); // Need full object here for name etc
    } else {
      worker = await this.workersRepository.findOne({
        where: { linkedUserId: userId },
      });
    }

    if (!worker) {
      throw new NotFoundException('No worker profile linked to this account');
    }

    const employer = await this.usersRepository.findOne({
      where: { id: worker.userId },
    });
    const employerName =
      employer?.businessName ||
      [employer?.firstName, employer?.lastName].filter(Boolean).join(' ') ||
      '';

    const records = await this.payrollRecordRepository.find({
      where: {
        workerId: worker.id,
        periodStart: Between(startDate, endDate),
        status: PayrollStatus.FINALIZED,
      },
      relations: ['worker'],
      order: { periodStart: 'ASC' },
    });

    const report = {
      year,
      workerId: worker.id,
      workerName: worker.name,
      kraPin: worker.kraPin || '',
      employerName,
      employerPin: employer?.kraPin || '',
      months: Array(12)
        .fill(null)
        .map((_, i) => this.emptyP9Month(i + 1)),
      totals: {
        basicSalary: 0,
        grossPay: 0,
        paye: 0,
      },
    };

    for (const record of records) {
      const monthIndex = new Date(record.periodStart).getMonth();
      const monthData = this.buildP9Month(record);

      report.months[monthIndex] = monthData;

      report.totals.basicSalary += monthData.basicSalary;
      report.totals.grossPay += monthData.grossPay;
      report.totals.paye += monthData.paye;
    }

    return [report]; // Return as list for consistency
  }

  /**
   * Generate P9 PDF for a single worker report
   */
  async generateP9Pdf(report: any): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({
        layout: 'landscape',
        size: 'A4',
        margin: 24,
      });
      const buffers: Buffer[] = [];

      doc.on('data', (buffer: any) => buffers.push(buffer));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', (err: any) => reject(err));

      doc
        .fontSize(14)
        .font('Helvetica-Bold')
        .text('PAYROLL TAX DEDUCTION SUMMARY', { align: 'center' });
      doc.fontSize(11).text(`P9 supporting schedule — ${report.year || ''}`, {
        align: 'center',
      });
      doc
        .font('Helvetica')
        .fontSize(8)
        .text(
          'Supporting record only. Use the current official KRA form and iTax process for filing.',
          { align: 'center' },
        );
      doc.moveDown();

      const startX = 24;
      let y = doc.y;
      doc.fontSize(9);
      doc.text(`Employer: ${report.employerName || 'Not provided'}`, startX, y);
      doc.text(`Employee: ${report.workerName || ''}`, startX + 390, y);
      y += 16;
      doc.text(
        `Employer PIN: ${report.employerPin || 'Not provided'}`,
        startX,
        y,
      );
      doc.text(
        `Employee PIN: ${report.kraPin || 'Not provided'}`,
        startX + 390,
        y,
      );
      y += 24;

      const columns = [
        { label: 'Month', key: 'month', width: 35 },
        { label: 'Cash Pay', key: 'basicSalary', width: 55 },
        { label: 'Non-Cash', key: 'benefits', width: 50 },
        { label: 'Gross', key: 'grossPay', width: 55 },
        { label: 'Pension', key: 'contribution', width: 50 },
        { label: 'AHL', key: 'housingLevy', width: 45 },
        { label: 'SHIF', key: 'shif', width: 45 },
        { label: 'PRMF', key: 'postRetirementMedical', width: 50 },
        { label: 'Mortgage', key: 'ownerOccupiedInterest', width: 50 },
        { label: 'Chargeable', key: 'taxablePay', width: 60 },
        { label: 'Tax', key: 'taxCharged', width: 50 },
        { label: 'Personal', key: 'relief', width: 50 },
        { label: 'Insurance', key: 'insuranceRelief', width: 50 },
        { label: 'PAYE', key: 'paye', width: 50 },
      ];
      const tableWidth = columns.reduce((sum, column) => sum + column.width, 0);

      let x = startX;
      doc.font('Helvetica-Bold').fontSize(7);
      columns.forEach((column) => {
        doc.text(column.label, x, y, {
          width: column.width,
          align: 'center',
        });
        x += column.width;
      });
      doc
        .moveTo(startX, y - 4)
        .lineTo(startX + tableWidth, y - 4)
        .stroke();
      doc
        .moveTo(startX, y + 16)
        .lineTo(startX + tableWidth, y + 16)
        .stroke();
      y += 22;

      const drawRow = (monthData: any, isTotal = false) => {
        let rowX = startX;
        doc.font(isTotal ? 'Helvetica-Bold' : 'Helvetica').fontSize(7);
        columns.forEach((column, index) => {
          const rawValue = monthData[column.key];
          const value =
            index === 0 ? rawValue : this.formatMoney(Number(rawValue || 0));
          doc.text(String(value), rowX, y, {
            width: column.width,
            align: index === 0 ? 'center' : 'right',
          });
          rowX += column.width;
        });
        y += 16;
      };

      report.months.forEach((monthData: any) => {
        drawRow({
          ...monthData,
          month: new Date(0, monthData.month - 1).toLocaleString('en', {
            month: 'short',
          }),
        });
      });

      doc
        .moveTo(startX, y)
        .lineTo(startX + tableWidth, y)
        .stroke();
      y += 5;
      const totals = report.months.reduce(
        (sum: Record<string, number>, monthData: any) => {
          columns.slice(1).forEach((column) => {
            sum[column.key] =
              (sum[column.key] || 0) + Number(monthData[column.key] || 0);
          });
          return sum;
        },
        { month: 0 },
      );
      drawRow({ ...totals, month: 'TOTAL' }, true);

      doc.end();
    });
  }

  async generateP9Zip(
    userId: string,
    year: number,
  ): Promise<{ stream: Readable; filename: string }> {
    const reports = await this.getP9Report(userId, year);
    const archive = archiver('zip', { zlib: { level: 9 } });

    for (const report of reports) {
      const buffer = await this.generateP9Pdf(report);
      const filename = `P9_SUPPORT_${year}_${report.workerName.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
      archive.append(buffer, { name: filename });
    }

    archive.finalize();
    return { stream: archive, filename: `P9_Supporting_Summaries_${year}.zip` };
  }

  /**
   * Generate Payslip PDF for a single payroll record
   */
  async generatePayslipPdf(payrollRecordId: string): Promise<Buffer> {
    const record = await this.payrollRecordRepository.findOne({
      where: { id: payrollRecordId },
      relations: ['worker', 'payPeriod'],
    });

    if (!record) {
      throw new NotFoundException('Payroll record not found');
    }

    const employer = await this.usersRepository.findOne({
      where: { id: record.userId },
    });
    const employerName =
      employer?.businessName ||
      [employer?.firstName, employer?.lastName].filter(Boolean).join(' ') ||
      'Employer';

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50 });
      const buffers: Buffer[] = [];

      doc.on('data', (buffer: any) => buffers.push(buffer));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', (err: any) => reject(err));

      // Header
      doc
        .fontSize(20)
        .font('Helvetica-Bold')
        .text('PAYSLIP', { align: 'center' });
      doc.moveDown();

      doc.fontSize(12).font('Helvetica-Bold').text(employerName);
      doc.font('Helvetica').fontSize(10);
      if (employer?.address) doc.text(employer.address);
      if (employer?.kraPin) doc.text(`PIN: ${employer.kraPin}`);
      doc.moveDown();

      const y = doc.y;

      // Period & Employee Info
      doc.font('Helvetica-Bold').text('Pay Period:', 50, y);
      doc.font('Helvetica').text(record.payPeriod.name, 150, y);

      doc.font('Helvetica-Bold').text('Date:', 300, y);
      doc.font('Helvetica').text(new Date().toLocaleDateString(), 380, y);
      doc.moveDown();

      doc.font('Helvetica-Bold').text('Employee:', 50);
      doc.font('Helvetica').text(record.worker.name, 150);

      doc.font('Helvetica-Bold').text('ID / PIN:', 50);
      doc
        .font('Helvetica')
        .text(
          `${record.worker.idNumber || 'N/A'} / ${record.worker.kraPin || 'N/A'}`,
          150,
        );

      doc.moveDown(2);

      // Earnings Section
      const startX = 50;
      let currentY = doc.y;

      // Draw Box
      doc.rect(startX, currentY, 500, 25).fillAndStroke('#f0f0f0', '#cccccc');
      doc
        .fillColor('black')
        .font('Helvetica-Bold')
        .text('Description', startX + 10, currentY + 7);
      doc.text('Amount (KES)', 400, currentY + 7, {
        align: 'right',
        width: 140,
      });

      currentY += 35;

      const addRow = (label: string, amount: number, isBold = false) => {
        if (isBold) doc.font('Helvetica-Bold');
        else doc.font('Helvetica');

        doc.text(label, startX + 10, currentY);
        doc.text(this.formatMoney(amount), 400, currentY, {
          align: 'right',
          width: 140,
        });
        currentY += 20;
      };

      addRow('Basic Salary', Number(record.grossSalary));

      // Note: Using current worker allowances as historical data is not on record
      if (Number(record.worker?.housingAllowance) > 0)
        addRow('Housing Allowance', Number(record.worker.housingAllowance));
      if (Number(record.worker?.transportAllowance) > 0)
        addRow('Transport Allowance', Number(record.worker.transportAllowance));

      if (Number(record.bonuses) > 0) addRow('Bonuses', Number(record.bonuses));
      if (Number(record.otherEarnings) > 0)
        addRow('Other Earnings', Number(record.otherEarnings));

      doc.moveTo(startX, currentY).lineTo(550, currentY).stroke();
      currentY += 5;

      // Calculate Total Gross for display (may differ slightly if allowances changed, but best effort)
      const calculatedGross =
        Number(record.grossSalary) +
        Number(record.bonuses) +
        Number(record.otherEarnings);
      addRow('GROSS PAY', calculatedGross, true);

      currentY += 20;

      // Deductions Section
      doc.rect(startX, currentY, 500, 25).fillAndStroke('#f0f0f0', '#cccccc');
      doc
        .fillColor('black')
        .font('Helvetica-Bold')
        .text('Deductions', startX + 10, currentY + 7);
      currentY += 35;

      const tax = record.taxBreakdown || {};
      addRow('PAYE (Tax)', Number(tax.paye || 0));
      addRow('NSSF', Number(tax.nssf || 0));
      addRow('SHIF', Number(tax.nhif || 0)); // SHIF (replaced NHIF Oct 2024)
      addRow('Housing Levy', Number(tax.housingLevy || 0));

      doc.moveTo(startX, currentY).lineTo(550, currentY).stroke();
      currentY += 5;
      addRow('TOTAL DEDUCTIONS', Number(tax.totalDeductions || 0), true);

      currentY += 30;

      // Net Pay
      doc.rect(startX, currentY, 500, 40).fillAndStroke('#e8f5e9', '#4caf50');
      doc.fillColor('black').fontSize(14).font('Helvetica-Bold');
      doc.text('NET PAY', startX + 20, currentY + 12);
      doc.text(
        `KES ${this.formatMoney(Number(record.netSalary))}`,
        300,
        currentY + 12,
        { align: 'right', width: 240 },
      );

      doc.end();
    });
  }

  /**
   * Generate Statutory (P10) PDF Report
   */
  async generateStatutoryPdf(report: any): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 30 });
      const buffers: Buffer[] = [];

      doc.on('data', (buffer: any) => buffers.push(buffer));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', (err: any) => reject(err));

      // Header
      doc
        .fontSize(16)
        .font('Helvetica-Bold')
        .text('STATUTORY DEDUCTIONS REPORT', { align: 'center' });
      doc.fontSize(12).text(report.payPeriod.name, { align: 'center' });
      doc.moveDown(2);

      // Totals Summary
      doc.fontSize(12).font('Helvetica-Bold').text('Summary');
      doc.rect(30, doc.y, 550, 60).stroke();

      let y = doc.y + 10;
      const col1 = 50;
      const col2 = 200;
      const col3 = 350;

      doc.font('Helvetica-Bold').fontSize(10);
      doc.text('PAYE:', col1, y);
      doc.text(`KES ${this.formatMoney(report.totals.paye)}`, col1 + 50, y);

      doc.text('NSSF:', col2, y);
      doc.text(`KES ${this.formatMoney(report.totals.nssf)}`, col2 + 50, y);

      y += 20;

      doc.text('SHIF:', col1, y);
      doc.text(`KES ${this.formatMoney(report.totals.nhif)}`, col1 + 50, y);

      doc.text('Housing Levy:', col2, y);
      doc.text(
        `KES ${this.formatMoney(report.totals.housingLevy)}`,
        col2 + 80,
        y,
      );

      doc.moveDown(4);

      // Employee Table
      const headers = ['Name', 'Gross Pay', 'NSSF', 'SHIF', 'Housing', 'PAYE'];
      const colWidths = [150, 80, 80, 80, 80, 80];
      const startX = 30;
      let x = startX;
      y = doc.y;

      // Draw Headers
      doc.rect(startX, y, 550, 20).fill('#eeeeee');
      doc.fillColor('black');
      headers.forEach((h, i) => {
        doc.text(h, x + 5, y + 5, {
          width: colWidths[i],
          align: i === 0 ? 'left' : 'right',
        });
        x += colWidths[i];
      });

      y += 25;
      doc.font('Helvetica').fontSize(9);

      // Draw Rows
      report.employees.forEach((emp: any, index: number) => {
        if (y > 700) {
          // New Page
          doc.addPage();
          y = 30;
          // Redraw headers... (simplified for brevity)
        }

        x = startX;
        // Background striping
        if (index % 2 === 1) doc.rect(startX, y - 2, 550, 15).fill('#f9f9f9');
        doc.fillColor('black');

        doc.text(emp.name, x + 5, y, { width: colWidths[0] });
        x += colWidths[0];
        doc.text(this.formatMoney(emp.grossPay), x + 5, y, {
          width: colWidths[1],
          align: 'right',
        });
        x += colWidths[1];
        doc.text(this.formatMoney(emp.nssf), x + 5, y, {
          width: colWidths[2],
          align: 'right',
        });
        x += colWidths[2];
        doc.text(this.formatMoney(emp.nhif), x + 5, y, {
          width: colWidths[3],
          align: 'right',
        });
        x += colWidths[3];
        doc.text(this.formatMoney(emp.housingLevy), x + 5, y, {
          width: colWidths[4],
          align: 'right',
        });
        x += colWidths[4];
        doc.text(this.formatMoney(emp.paye), x + 5, y, {
          width: colWidths[5],
          align: 'right',
        });

        y += 15;
      });

      doc.end();
    });
  }

  private formatMoney(amount: number): string {
    return (amount || 0).toLocaleString('en-KE', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
  }
}
