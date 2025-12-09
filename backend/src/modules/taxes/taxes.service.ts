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
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';
import { ActivitiesService } from '../activities/activities.service';
import { ActivityType } from '../activities/entities/activity.entity';

@Injectable()
export class TaxesService {
  constructor(
    @InjectRepository(TaxTable)
    private taxTableRepository: Repository<TaxTable>,
    @InjectRepository(TaxSubmission)
    private taxSubmissionRepository: Repository<TaxSubmission>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    private taxConfigService: TaxConfigService,
    private usersService: UsersService,
    private activitiesService: ActivitiesService,
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
   * Using TaxConfigService for current rates
   */
  private async calculateNSSF(
    grossSalary: number,
    date: Date,
  ): Promise<number> {
    // Get current NSSF configurations
    const tier1Config = await this.taxConfigService.getActiveTaxConfig(
      TaxType.NSSF_TIER1,
      date,
    );
    const tier2Config = await this.taxConfigService.getActiveTaxConfig(
      TaxType.NSSF_TIER2,
      date,
    );

    let totalNssf = 0;

    // Calculate Tier 1
    if (tier1Config && tier1Config.configuration.tiers) {
      const tier1 = tier1Config.configuration.tiers[0];
      const tier1Limit = tier1.salaryTo || 8000; // Handle null case
      totalNssf += Math.min(grossSalary, tier1Limit) * tier1.rate;
    }

    // Calculate Tier 2
    if (tier2Config && tier2Config.configuration.tiers) {
      const tier2 = tier2Config.configuration.tiers[0];
      if (grossSalary > 8000) {
        const tier2Limit = tier2.salaryTo || 72000; // Handle null case
        const tier2From = tier2.salaryFrom || 8001; // Handle null case
        totalNssf +=
          Math.min(grossSalary - 8000, tier2Limit - tier2From) * tier2.rate;
      }
    }

    return Math.round(totalNssf * 100) / 100;
  }

  /**
   * Calculate PAYE using TaxConfigService
   * Using current graduated tax brackets
   */
  private async calculatePAYEFromConfig(
    grossSalary: number,
    nssf: number,
    date: Date,
  ): Promise<number> {
    const payeConfig = await this.taxConfigService.getActiveTaxConfig(
      TaxType.PAYE,
      date,
    );

    if (payeConfig && payeConfig.configuration.brackets) {
      const taxableIncome = grossSalary - nssf;
      let tax = 0;
      let remainingIncome = taxableIncome;
      let previousLimit = 0;

      for (const bracket of payeConfig.configuration.brackets) {
        if (remainingIncome <= 0) break;

        const taxableAmount =
          bracket.to === null
            ? remainingIncome
            : Math.min(remainingIncome, bracket.to - previousLimit);

        tax += taxableAmount * bracket.rate;
        remainingIncome -= taxableAmount;
        previousLimit = bracket.to || previousLimit;
      }

      const personalRelief = payeConfig.configuration.personalRelief || 2400;
      const paye = Math.max(0, tax - personalRelief);
      return Math.round(paye * 100) / 100;
    }

    // Fallback calculation using existing method
    const table = await this.getTaxTable(date);
    return this.calculatePAYE(grossSalary, nssf, table);
  }

  /**
   * Calculate SHIF (Social Health Insurance Fund)
   * Using TaxConfigService for current rates
   */
  private async calculateSHIF(
    grossSalary: number,
    date: Date,
  ): Promise<number> {
    const shifConfig = await this.taxConfigService.getActiveTaxConfig(
      TaxType.SHIF,
      date,
    );

    if (shifConfig && shifConfig.configuration.percentage !== undefined) {
      // Percentage is stored as whole number (e.g., 2.75 for 2.75%), so divide by 100
      const shifAmount = grossSalary * (shifConfig.configuration.percentage / 100);
      const minAmount = shifConfig.configuration.minAmount || 0;
      return Math.round(Math.max(shifAmount, minAmount) * 100) / 100;
    }

    // Fallback calculation
    const shifAmount = grossSalary * 0.0275; // 2.75%
    return Math.round(Math.max(shifAmount, 300) * 100) / 100; // Min KES 300
  }

  /**
   * Calculate Housing Levy (Employee portion)
   * Using TaxConfigService for current rates
   */
  private async calculateHousingLevy(
    grossSalary: number,
    date: Date,
  ): Promise<number> {
    const housingConfig = await this.taxConfigService.getActiveTaxConfig(
      TaxType.HOUSING_LEVY,
      date,
    );

    if (housingConfig && housingConfig.configuration.percentage !== undefined) {
      // Percentage is stored as whole number (e.g., 1.5 for 1.5%), so divide by 100
      return (
        Math.round(grossSalary * (housingConfig.configuration.percentage / 100) * 100) /
        100
      );
    }

    // Fallback calculation
    return Math.round(grossSalary * 0.015 * 100) / 100; // 1.5%
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
   * Using TaxConfigService for current Kenya tax rates
   */
  async calculateTaxes(
    grossSalary: number,
    date: Date = new Date(),
  ): Promise<TaxBreakdown> {
    // Calculate NSSF first (needed for PAYE calculation)
    const nssf = await this.calculateNSSF(grossSalary, date);

    // Calculate remaining components
    const [shif, housingLevy, payeConfig] = await Promise.all([
      this.calculateSHIF(grossSalary, date),
      this.calculateHousingLevy(grossSalary, date),
      this.calculatePAYEFromConfig(grossSalary, nssf, date),
    ]);

    const totalDeductions = nssf + shif + housingLevy + payeConfig;

    return {
      nssf,
      nhif: shif,
      housingLevy,
      paye: payeConfig,
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
    try {
      return await this.taxSubmissionRepository.find({
        where: { userId },
        order: { createdAt: 'DESC' },
        relations: ['payPeriod'],
      });
    } catch (error) {
      // If relation fails, return without it
      console.warn('Failed to load payPeriod relation:', error.message);
      try {
        return await this.taxSubmissionRepository.find({
          where: { userId },
          order: { createdAt: 'DESC' },
        });
      } catch (fallbackError) {
        console.error('Failed to load tax submissions:', fallbackError.message);
        return [];
      }
    }
  }

  async generateTaxSubmission(
    payPeriodId: string,
    userId: string,
  ): Promise<TaxSubmission> {
    // Get all finalized payroll records for this period
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        payPeriodId,
        userId,
        status: 'finalized' as any, // PayrollStatus.FINALIZED
      },
    });

    if (payrollRecords.length === 0) {
      throw new NotFoundException(
        'No finalized payroll records found for this period',
      );
    }

    // Aggregate tax amounts
    const totalPaye = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxAmount),
      0,
    );
    const totalNssf = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown.nssf),
      0,
    );
    const totalNhif = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown.nhif),
      0,
    );
    const totalHousingLevy = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown.housingLevy),
      0,
    );

    // Check if submission already exists
    let submission = await this.taxSubmissionRepository.findOne({
      where: { payPeriodId, userId },
    });

    if (submission) {
      // Update existing submission
      submission.totalPaye = totalPaye;
      submission.totalNssf = totalNssf;
      submission.totalNhif = totalNhif;
      submission.totalHousingLevy = totalHousingLevy;
    } else {
      // Create new submission
      submission = this.taxSubmissionRepository.create({
        userId,
        payPeriodId,
        totalPaye,
        totalNssf,
        totalNhif,
        totalHousingLevy,
        status: TaxSubmissionStatus.PENDING,
      });
    }

    const savedSubmission = await this.taxSubmissionRepository.save(submission);

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.TAX,
        'Tax Submission Generated',
        `Generated tax submission for pay period`,
        {
          submissionId: savedSubmission.id,
          payPeriodId,
          totalPaye,
          totalNssf,
          totalNhif,
          totalHousingLevy,
        },
      );
    } catch (e) {
      console.error('Failed to log activity:', e);
    }

    return savedSubmission;
  }

  async getTaxSubmissionByPeriod(
    payPeriodId: string,
    userId: string,
  ): Promise<TaxSubmission | null> {
    return this.taxSubmissionRepository.findOne({
      where: { payPeriodId, userId },
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
    const savedSubmission = await this.taxSubmissionRepository.save(submission);

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.TAX,
        'Tax Returns Filed',
        `Marked tax submission as filed`,
        {
          submissionId: savedSubmission.id,
          filingDate: savedSubmission.filingDate,
        },
      );
    } catch (e) {
      console.error('Failed to log activity:', e);
    }

    return savedSubmission;
  }

  async getComplianceStatus(userId: string) {
    const user = await this.usersService.findOneById(userId);
    return {
      kraPin: !!user?.kraPin,
      nssf: !!user?.nssfNumber,
      shif: !!user?.shifNumber,
      isCompliant: !!user?.kraPin && !!user?.nssfNumber && !!user?.shifNumber,
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
