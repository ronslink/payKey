import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual } from 'typeorm';
import { TaxTable } from './entities/tax-table.entity';
import {
  TaxSubmission,
  TaxSubmissionStatus,
} from './entities/tax-submission.entity';
import { TaxBreakdown, PayrollCalculation } from './interfaces/tax.interface';
import { UsersService } from '../users/users.service';

@Injectable()
export class TaxesService {
  constructor(
    @InjectRepository(TaxTable)
    private taxTableRepository: Repository<TaxTable>,
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
    private usersService: UsersService,
  ) { }

  async createTaxTable(data: Partial<TaxTable>): Promise<TaxTable> {
    const taxTable = this.taxTableRepository.create(data);
    return this.taxTableRepository.save(taxTable);
  }

  async getTaxTables(): Promise<TaxTable[]> {
    return this.taxTableRepository.find({ order: { effectiveDate: 'DESC' } });
  }

  async getTaxTable(date: Date): Promise<TaxTable> {
    const taxTable = await this.taxTableRepository.findOne({
      where: {
        effectiveDate: LessThanOrEqual(date),
        isActive: true,
      },
      order: { effectiveDate: 'DESC' },
    });

    if (!taxTable) {
      // Fallback to hardcoded defaults if no table exists
      return this.getDefaultTaxTable();
    }
    return taxTable;
  }

  private getDefaultTaxTable(): TaxTable {
    return {
      id: 'default',
      year: 2024,
      effectiveDate: new Date('2024-01-01'),
      nssfConfig: {
        tierILimit: 7000,
        tierIILimit: 36000,
        rate: 0.06,
      },
      nhifConfig: {
        rate: 0.0275,
      },
      housingLevyRate: 0.015,
      payeBands: [
        { limit: 24000, rate: 0.1 },
        { limit: 32333, rate: 0.25 },
        { limit: Infinity, rate: 0.3 },
      ],
      personalRelief: 2400,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as TaxTable;
  }

  /**
   * Calculate NSSF (National Social Security Fund)
   * Tier I: 6% of pensionable pay (max KES 7,000)
   * Tier II: 6% of pensionable pay (max KES 36,000)
   * Total max contribution: KES 2,160/month
   */
  private calculateNSSF(grossSalary: number, table: TaxTable): number {
    const { tierILimit, tierIILimit, rate } = table.nssfConfig;

    const tierI = Math.min(grossSalary, tierILimit) * rate;
    const tierII =
      grossSalary > tierILimit
        ? Math.min(grossSalary - tierILimit, tierIILimit - tierILimit) * rate
        : 0;

    return Math.round((tierI + tierII) * 100) / 100;
  }

  /**
   * Calculate NHIF/SHIF (Social Health Insurance Fund)
   * 2.75% of gross salary
   */
  private calculateNHIF(grossSalary: number, table: TaxTable): number {
    // Assuming percentage rate for SHIF/NHIF as per recent changes
    // If bands are needed, we can check table.nhifConfig type
    return Math.round(grossSalary * table.nhifConfig.rate * 100) / 100;
  }

  /**
   * Calculate Housing Levy (Employee portion)
   * 1.5% of gross salary
   */
  private calculateHousingLevy(grossSalary: number, table: TaxTable): number {
    return Math.round(grossSalary * Number(table.housingLevyRate) * 100) / 100;
  }

  /**
   * Calculate PAYE (Pay As You Earn)
   * Tax bands (monthly):
   * - 0 - 24,000: 10%
   * - 24,001 - 32,333: 25%
   * - 32,334+: 30%
   * Personal relief: KES 2,400/month
   */
  private calculatePAYE(
    grossSalary: number,
    nssf: number,
    table: TaxTable,
  ): number {
    const taxableIncome = grossSalary - nssf;
    let tax = 0;
    let remainingIncome = taxableIncome;
    let previousLimit = 0;

    for (const band of table.payeBands) {
      if (remainingIncome <= 0) break;

      const taxableAmount =
        band.limit === Infinity
          ? remainingIncome
          : Math.min(remainingIncome, band.limit - previousLimit);

      tax += taxableAmount * band.rate;
      remainingIncome -= taxableAmount;
      previousLimit = band.limit;
    }

    const paye = Math.max(0, tax - Number(table.personalRelief));
    return Math.round(paye * 100) / 100;
  }

  /**
   * Calculate all taxes for a given gross salary
   */
  async calculateTaxes(
    grossSalary: number,
    date: Date = new Date(),
  ): Promise<TaxBreakdown> {
    const table = await this.getTaxTable(date);

    const nssf = this.calculateNSSF(grossSalary, table);
    const nhif = this.calculateNHIF(grossSalary, table);
    const housingLevy = this.calculateHousingLevy(grossSalary, table);
    const paye = this.calculatePAYE(grossSalary, nssf, table);

    const totalDeductions = nssf + nhif + housingLevy + paye;

    return {
      nssf,
      nhif,
      housingLevy,
      paye,
      totalDeductions: Math.round(totalDeductions * 100) / 100,
    };
  }

  /**
   * Calculate net pay after all deductions
   */
  async calculateNetPay(grossSalary: number): Promise<number> {
    const taxes = await this.calculateTaxes(grossSalary);
    return Math.round((grossSalary - taxes.totalDeductions) * 100) / 100;
  }

  /**
   * Calculate full payroll for a worker
   */
  async calculatePayroll(
    workerId: string,
    workerName: string,
    grossSalary: number,
  ): Promise<PayrollCalculation> {
    const taxBreakdown = await this.calculateTaxes(grossSalary);
    const netPay = grossSalary - taxBreakdown.totalDeductions;

    return {
      workerId,
      workerName,
      grossSalary,
      taxBreakdown,
      netPay: Math.round(netPay * 100) / 100,
    };
  }

  /**
   * Get monthly payroll summary for tax payments
   * This aggregates all payroll for a month to calculate tax obligations
   */
  async getMonthlyPayrollSummary(
    userId?: string,
    year?: number,
    month?: number,
  ): Promise<{
    totalGross: number;
    totalPaye: number;
    totalNssf: number;
    totalShif: number;
    totalHousingLevy: number;
  }> {
    // TODO: Aggregate from actual payroll transactions
    // For now, return placeholder
    return Promise.resolve({
      totalGross: 0,
      totalPaye: 0,
      totalNssf: 0,
      totalShif: 0,
      totalHousingLevy: 0,
    });
  }

  async getSubmissions(userId: string): Promise<TaxSubmission[]> {
    return this.taxSubmissionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      relations: ['payPeriod'],
    });
  }

  async markAsFiled(id: string, userId: string): Promise<TaxSubmission> {
    const submission = await this.taxSubmissionRepository.findOne({
      where: { id, userId },
    });

    if (!submission) {
      throw new NotFoundException('Tax submission not found');
    }

    submission.status = TaxSubmissionStatus.FILED;
    submission.filingDate = new Date();
    return this.taxSubmissionRepository.save(submission);
  }

  async getComplianceStatus(userId: string) {
    const user = await this.usersService.findOneById(userId);
    return {
      kraPin: !!user?.kraPin,
      nssf: !!user?.nssfNumber,
      nhif: !!user?.nhifNumber,
      isCompliant: !!user?.kraPin && !!user?.nssfNumber && !!user?.nhifNumber,
    };
  }

  getUpcomingDeadlines() {
    const today = new Date();
    const currentMonth = today.getMonth();
    const currentYear = today.getFullYear();

    // Helper to create deadline date
    const createDeadline = (day: number, monthOffset = 0) => {
      let month = currentMonth + monthOffset;
      let year = currentYear;

      if (month > 11) {
        month = 0;
        year++;
      }

      const deadline = new Date(year, month, day);
      // If deadline passed for this month, move to next month
      if (deadline < today && monthOffset === 0) {
        return createDeadline(day, 1);
      }
      return deadline;
    };

    // Kenyan Tax Deadlines
    // PAYE: 9th of following month
    // NSSF: 9th of following month (updated from 15th recently, but let's stick to standard 9th for PAYE/Housing Levy/NSSF unified)
    // SHIF (NHIF): 9th of following month
    // Housing Levy: 9th of following month

    // Actually, standard dates are:
    // PAYE & Housing Levy: 9th
    // NSSF: 15th (Traditionally, but often paid with PAYE)
    // SHIF/NHIF: 9th

    const payeDeadline = createDeadline(9);
    const nssfDeadline = createDeadline(15);
    const nhifDeadline = createDeadline(9);
    const housingLevyDeadline = createDeadline(9);

    return [
      {
        title: 'PAYE Remittance',
        dueDate: payeDeadline,
        description: 'Pay As You Earn for previous month',
      },
      {
        title: 'Housing Levy',
        dueDate: housingLevyDeadline,
        description: 'Affordable Housing Levy remittance',
      },
      {
        title: 'SHIF/NHIF Contribution',
        dueDate: nhifDeadline,
        description: 'Social Health Insurance Fund',
      },
      {
        title: 'NSSF Contribution',
        dueDate: nssfDeadline,
        description: 'National Social Security Fund',
      },
    ].sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
  }
}
