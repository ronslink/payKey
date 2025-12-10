import { Injectable, NotFoundException, StreamableFile } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Worker } from '../workers/entities/worker.entity';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const PDFDocument = require('pdfkit');
import archiver from 'archiver';
import { Readable } from 'stream';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { User } from '../users/entities/user.entity';
import { PayrollRecord, PayrollStatus } from '../payroll/entities/payroll-record.entity';
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
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
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
  async getP9Report(userId: string, year: number, workerId?: string) {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);

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

    // Default tax relief (Should ideally come from config snapshot)
    const PERSONAL_RELIEF = 2400;

    for (const record of records) {
      if (!workerReports[record.workerId]) {
        workerReports[record.workerId] = {
          workerId: record.workerId,
          workerName: record.worker?.name || 'Unknown',
          kraPin: record.worker?.kraPin || '',
          months: Array(12).fill(null).map((_, i) => ({
            month: i + 1,
            basicSalary: 0,
            benefits: 0,
            grossPay: 0,
            contribution: 0, // NSSF
            taxablePay: 0,
            taxCharged: 0,
            relief: 0,
            paye: 0,
            valueOfQuarters: 0,
            ownerOccupiedInterest: 0,
            retirementContribution: 0,
          })),
          totals: {
            basicSalary: 0,
            grossPay: 0,
            paye: 0,
          },
        };
      }

      const monthIndex = record.periodStart.getMonth(); // 0-11
      const report = workerReports[record.workerId];

      const basicSalary = Number(record.grossSalary || 0);
      const benefits = Number(record.bonuses || 0) + Number(record.otherEarnings || 0);
      const gross = basicSalary + benefits;
      const nssf = Number(record.taxBreakdown?.nssf || 0);
      const paye = Number(record.taxBreakdown?.paye || 0);
      const taxable = Math.max(0, gross - nssf);

      // Back-calculate Tax Charged (PAYE + Relief) only if PAYE > 0
      const taxCharged = paye > 0 ? paye + PERSONAL_RELIEF : 0;

      if (report.months[monthIndex]) {
        report.months[monthIndex] = {
          month: monthIndex + 1,
          basicSalary: basicSalary,
          benefits: benefits,
          valueOfQuarters: 0,
          grossPay: gross,
          contribution: nssf, // Defined Contribution
          ownerOccupiedInterest: 0,
          retirementContribution: 0,
          taxablePay: taxable,
          taxCharged: taxCharged,
          relief: paye > 0 ? PERSONAL_RELIEF : 0,
          paye: paye,
        };
      }

      report.totals.basicSalary += basicSalary;
      report.totals.grossPay += gross;
      report.totals.paye += paye;
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

    return {
      year,
      employerName: 'My Company', // Configurable
      monthlyReturns,
      annualTotals,
    };
  }

  async getEmployeeP9Report(userId: string, year: number) {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31, 23, 59, 59);

    const worker = await this.workersRepository.findOne({
      where: { linkedUserId: userId },
    });

    if (!worker) {
      throw new NotFoundException('No worker profile linked to this account');
    }

    const records = await this.payrollRecordRepository.find({
      where: {
        workerId: worker.id,
        periodStart: Between(startDate, endDate),
        status: PayrollStatus.FINALIZED,
      },
      relations: ['worker'],
      order: { periodStart: 'ASC' },
    });

    // Reuse similar logic to getP9Report but specific to this worker
    // Default tax relief
    const PERSONAL_RELIEF = 2400;

    // Initialize standard P9 Report Structure
    const report = {
      workerId: worker.id,
      workerName: worker.name,
      kraPin: worker.kraPin || '',
      months: Array(12).fill(null).map((_, i) => ({
        month: i + 1,
        basicSalary: 0,
        benefits: 0,
        grossPay: 0,
        contribution: 0,
        taxablePay: 0,
        taxCharged: 0,
        relief: 0,
        paye: 0,
        valueOfQuarters: 0,
        ownerOccupiedInterest: 0,
        retirementContribution: 0,
      })),
      totals: {
        basicSalary: 0,
        grossPay: 0,
        paye: 0,
      },
    };

    for (const record of records) {
      const monthIndex = record.periodStart.getMonth(); // 0-11

      const basicSalary = Number(record.grossSalary);
      const benefits = Number(record.bonuses) + Number(record.otherEarnings);
      const gross = basicSalary + benefits;
      const nssf = Number(record.taxBreakdown?.nssf || 0);
      const paye = Number(record.taxBreakdown?.paye || 0);
      const taxable = Math.max(0, gross - nssf);
      const taxCharged = paye > 0 ? paye + PERSONAL_RELIEF : 0;

      report.months[monthIndex] = {
        month: monthIndex + 1,
        basicSalary: basicSalary,
        benefits: benefits,
        valueOfQuarters: 0,
        grossPay: gross,
        contribution: nssf,
        ownerOccupiedInterest: 0,
        retirementContribution: 0,
        taxablePay: taxable,
        taxCharged: taxCharged,
        relief: paye > 0 ? PERSONAL_RELIEF : 0,
        paye: paye,
      };

      report.totals.basicSalary += basicSalary;
      report.totals.grossPay += gross;
      report.totals.paye += paye;
    }

    return [report]; // Return as list for consistency
  }

  /**
   * Generate P9 PDF for a single worker report
   */
  async generateP9Pdf(report: any): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ layout: 'landscape', margin: 30 });
      const buffers: Buffer[] = [];

      doc.on('data', (buffer: any) => buffers.push(buffer));
      doc.on('end', () => resolve(Buffer.concat(buffers)));
      doc.on('error', (err: any) => reject(err));

      // Header
      doc.fontSize(14).font('Helvetica-Bold').text('KENYA REVENUE AUTHORITY', { align: 'center' });
      doc.fontSize(12).text('INCOME TAX DEPARTMENT', { align: 'center' });
      doc.fontSize(16).text('P9A', { align: 'left' });
      doc.fontSize(12).text('TAX DEDUCTION CARD YEAR ' + new Date().getFullYear(), { align: 'center' });
      doc.moveDown();

      // Details Grid
      const startX = 30;
      let y = doc.y;

      doc.fontSize(10).font('Helvetica');
      doc.text(`Employer's Name: ${report.employerName || 'My Company'}`, startX, y); // TODO: Fetch from config
      doc.text(`Employee's Main Name: ${report.workerName}`, startX + 300, y);
      y += 20;
      doc.text(`Employer's PIN: ${report.employerPin || 'P000000000A'}`, startX, y); // TODO: Fetch from config
      doc.text(`Employee's PIN: ${report.kraPin}`, startX + 300, y);

      doc.moveDown(2);

      // Table Headers
      const colWidths = [40, 60, 60, 60, 70, 70, 60, 70, 70, 70, 70, 70];
      const headers = [
        'Month', 'Basic\nSalary', 'Benefits\nNon-Cash', 'Value of\nQuarters', 'Total\nGross Pay',
        'Defined\nContrib.', 'Owner\nOcc Int.', 'Retirement\nContrib.', 'Chargeable\nPay',
        'Tax\nCharged', 'Personal\nRelief', 'PAYE Tax'
      ]; // A to L

      // Draw Header Row
      let x = startX;
      y = doc.y;
      const headerHeight = 30;

      doc.font('Helvetica-Bold').fontSize(8);

      headers.forEach((header, i) => {
        doc.text(header, x, y, { width: colWidths[i], align: 'center' });
        x += colWidths[i];
      });

      // Draw Lines
      doc.moveTo(startX, y - 5).lineTo(x, y - 5).stroke(); // Top
      doc.moveTo(startX, y + headerHeight).lineTo(x, y + headerHeight).stroke(); // Bottom

      y += headerHeight + 5;

      // Draw Data Rows
      doc.font('Helvetica').fontSize(9);

      report.months.forEach((monthData: any) => {
        let rowX = startX;
        // Month Name
        const monthName = new Date(0, monthData.month - 1).toLocaleString('default', { month: 'short' });

        doc.text(monthName, rowX, y, { width: colWidths[0], align: 'center' }); rowX += colWidths[0];
        doc.text(this.formatMoney(monthData.basicSalary), rowX, y, { width: colWidths[1], align: 'right' }); rowX += colWidths[1];
        doc.text(this.formatMoney(monthData.benefits), rowX, y, { width: colWidths[2], align: 'right' }); rowX += colWidths[2];
        doc.text(this.formatMoney(monthData.valueOfQuarters), rowX, y, { width: colWidths[3], align: 'right' }); rowX += colWidths[3];
        doc.text(this.formatMoney(monthData.grossPay), rowX, y, { width: colWidths[4], align: 'right' }); rowX += colWidths[4];

        // Defined Contribution (E1) = 30% of A etc.. usually just NSSF here
        doc.text(this.formatMoney(monthData.contribution), rowX, y, { width: colWidths[5], align: 'right' }); rowX += colWidths[5];
        doc.text(this.formatMoney(monthData.ownerOccupiedInterest), rowX, y, { width: colWidths[6], align: 'right' }); rowX += colWidths[6];
        doc.text(this.formatMoney(monthData.retirementContribution), rowX, y, { width: colWidths[7], align: 'right' }); rowX += colWidths[7];

        doc.text(this.formatMoney(monthData.taxablePay), rowX, y, { width: colWidths[8], align: 'right' }); rowX += colWidths[8];
        doc.text(this.formatMoney(monthData.taxCharged), rowX, y, { width: colWidths[9], align: 'right' }); rowX += colWidths[9]; // J
        doc.text(this.formatMoney(monthData.relief), rowX, y, { width: colWidths[10], align: 'right' }); rowX += colWidths[10]; // K
        doc.text(this.formatMoney(monthData.paye), rowX, y, { width: colWidths[11], align: 'right' }); rowX += colWidths[11]; // L

        y += 20;
      });

      // Draw Totals Line
      doc.moveTo(startX, y).lineTo(x, y).stroke();
      y += 5;

      // Totals Row
      doc.font('Helvetica-Bold');
      doc.text('TOTALS', startX, y, { width: colWidths[0], align: 'center' });
      let totalX = startX + colWidths[0];

      doc.text(this.formatMoney(report.totals.basicSalary), totalX, y, { width: colWidths[1], align: 'right' }); totalX += colWidths[1];
      // Skip breakdown totals if not calculated, just show key ones
      totalX += colWidths[2]; // Benefits
      totalX += colWidths[3]; // Quarters
      doc.text(this.formatMoney(report.totals.grossPay), totalX, y, { width: colWidths[4], align: 'right' }); totalX += colWidths[4];

      // Skip to PAYE
      totalX = startX + colWidths[0] + colWidths[1] + colWidths[2] + colWidths[3] + colWidths[4] + colWidths[5] + colWidths[6] + colWidths[7] + colWidths[8] + colWidths[9] + colWidths[10];
      doc.text(this.formatMoney(report.totals.paye), totalX, y, { width: colWidths[11], align: 'right' });


      doc.end();
    });
  }

  async generateP9Zip(userId: string, year: number): Promise<{ stream: Readable; filename: string }> {
    const reports = await this.getP9Report(userId, year);
    const archive = archiver('zip', { zlib: { level: 9 } });

    for (const report of (reports as any[])) {
      const buffer = await this.generateP9Pdf(report);
      const filename = `P9_${year}_${report.workerName.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
      archive.append(buffer, { name: filename });
    }

    archive.finalize();
    return { stream: archive, filename: `P9_Returns_${year}.zip` };
  }

  private formatMoney(amount: number): string {
    return (amount || 0).toFixed(2);
  }
}
