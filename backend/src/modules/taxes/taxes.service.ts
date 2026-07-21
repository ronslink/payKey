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
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { TaxConfig, TaxType } from '../tax-config/entities/tax-config.entity';
import { ActivitiesService } from '../activities/activities.service';

interface PayeCalculation {
  paye: number;
  taxablePay: number;
  taxCharged: number;
  personalReliefApplied: number;
  insuranceReliefApplied: number;
  allowablePensionDeduction: number;
  allowableMortgageInterest: number;
  allowablePostRetirementMedicalContribution: number;
}
import { ActivityType } from '../activities/entities/activity.entity';

@Injectable()
export class TaxesService {
  constructor(
    @InjectRepository(TaxTable)
    private readonly taxTableRepository: Repository<TaxTable>,
    @InjectRepository(TaxSubmission)
    private readonly taxSubmissionRepository: Repository<TaxSubmission>,
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepository: Repository<PayrollRecord>,
    private readonly taxConfigService: TaxConfigService,
    private readonly usersService: UsersService,
    private readonly activitiesService: ActivitiesService,
  ) {}

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
      throw new NotFoundException(
        `No tax table found for date ${date.toISOString()}`,
      );
    }
    return taxTable;
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

    if (!tier1Config || !tier2Config) {
      throw new NotFoundException(
        `NSSF tax configuration not found for date ${date.toISOString()}`,
      );
    }

    return this.calculateNSSFWithConfigs(grossSalary, tier1Config, tier2Config);
  }

  /**
   * Calculate employee NSSF from the effective-dated Tier I and Tier II rows.
   * Tier II starts at the Tier I upper earnings limit. This also handles older
   * rows that represented the next shilling as salaryFrom (for example 8,001)
   * without introducing a one-shilling gap in the band width.
   */
  private calculateNSSFWithConfigs(
    grossSalary: number,
    tier1Config: TaxConfig | null,
    tier2Config: TaxConfig | null,
  ): number {
    if (grossSalary <= 0) return 0;

    const tier1 = tier1Config?.configuration?.tiers?.[0];
    const tier2 = tier2Config?.configuration?.tiers?.[0];
    let totalNssf = 0;

    if (tier1) {
      const lower = Number(tier1.salaryFrom ?? 0);
      const upper = Number(tier1.salaryTo ?? grossSalary);
      const pensionable = Math.max(0, Math.min(grossSalary, upper) - lower);
      totalNssf += pensionable * Number(tier1.rate);
    }

    if (tier2) {
      const lower = Number(tier1?.salaryTo ?? tier2.salaryFrom ?? 0);
      const upper = Number(tier2.salaryTo ?? grossSalary);
      const pensionable = Math.max(0, Math.min(grossSalary, upper) - lower);
      totalNssf += pensionable * Number(tier2.rate);
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
    shif: number,
    housingLevy: number,
    date: Date,
    options: {
      pensionContribution?: number;
      nonCashBenefits?: number;
      mortgageInterest?: number;
      postRetirementMedicalContribution?: number;
      lifeInsurancePremium?: number;
      hasDisabilityExemption?: boolean;
    } = {},
  ): Promise<PayeCalculation> {
    const payeConfig = await this.taxConfigService.getActiveTaxConfig(
      TaxType.PAYE,
      date,
    );

    const {
      pensionContribution = 0,
      nonCashBenefits = 0,
      mortgageInterest = 0,
      postRetirementMedicalContribution = 0,
      lifeInsurancePremium = 0,
      hasDisabilityExemption = false,
    } = options;

    if (payeConfig && payeConfig.configuration.brackets) {
      const maxPension =
        payeConfig.configuration.maxAllowablePension ??
        payeConfig.configuration.maxPensionContribution ??
        30000;
      const disabilityAmount =
        payeConfig.configuration.disabilityExemptionAmount ?? 150000;
      const maxMortgage = payeConfig.configuration.maxMortgageInterest ?? 30000;
      const maxPostRetirementMedical =
        payeConfig.configuration.maxPostRetirementMedicalContribution ?? 15000;
      const nonCashBenefitThreshold =
        payeConfig.configuration.nonCashBenefitExemptionThreshold ?? 5000;

      // Combined NSSF + Pension is capped for tax deduction purposes
      const allowablePensionDeduction = Math.min(
        Math.max(0, nssf + pensionContribution),
        maxPension,
      );
      const allowableMortgage = Math.min(
        Math.max(0, mortgageInterest),
        maxMortgage,
      );
      const allowablePostRetirementMedical = Math.min(
        Math.max(0, postRetirementMedicalContribution),
        maxPostRetirementMedical,
      );
      const taxableNonCashBenefits =
        nonCashBenefits >= nonCashBenefitThreshold ? nonCashBenefits : 0;

      // SHIF and the employee Affordable Housing Levy are allowable PAYE
      // deductions. Non-cash benefits are added exactly once for PAYE only.
      let taxableIncome = Math.max(
        0,
        grossSalary +
          taxableNonCashBenefits -
          allowablePensionDeduction -
          shif -
          housingLevy -
          allowableMortgage -
          allowablePostRetirementMedical,
      );

      // Disability Exemption: first X amount is tax-free
      if (hasDisabilityExemption) {
        taxableIncome = Math.max(0, taxableIncome - disabilityAmount);
      }

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

      const personalRelief = payeConfig.configuration.personalRelief ?? 2400;

      // SHIF replaced NHIF and is an allowable deduction, not an insurance
      // relief premium. Only qualifying declared insurance premiums are used.
      const reliefRate = payeConfig.configuration.insuranceRelief ?? 0.15;
      const maxRelief = payeConfig.configuration.maxInsuranceRelief ?? 5000;
      const insuranceRelief = Math.min(
        Math.max(0, lifeInsurancePremium) * reliefRate,
        maxRelief,
      );

      const personalReliefApplied = Math.min(personalRelief, tax);
      const insuranceReliefApplied = Math.min(
        insuranceRelief,
        Math.max(0, tax - personalReliefApplied),
      );
      const paye = Math.max(
        0,
        tax - personalReliefApplied - insuranceReliefApplied,
      );

      return {
        paye: Math.round(paye * 100) / 100,
        taxablePay: Math.round(taxableIncome * 100) / 100,
        taxCharged: Math.round(tax * 100) / 100,
        personalReliefApplied: Math.round(personalReliefApplied * 100) / 100,
        insuranceReliefApplied: Math.round(insuranceReliefApplied * 100) / 100,
        allowablePensionDeduction:
          Math.round(allowablePensionDeduction * 100) / 100,
        allowableMortgageInterest: Math.round(allowableMortgage * 100) / 100,
        allowablePostRetirementMedicalContribution:
          Math.round(allowablePostRetirementMedical * 100) / 100,
      };
    }

    throw new NotFoundException(
      `PAYE tax configuration not found for date ${date.toISOString()}`,
    );
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

    if (grossSalary <= 0) return 0;

    if (shifConfig && shifConfig.configuration.percentage !== undefined) {
      // Percentage is stored as whole number (e.g., 2.75 for 2.75%), so divide by 100
      const shifAmount =
        grossSalary * (shifConfig.configuration.percentage / 100);
      const minAmount = shifConfig.configuration.minAmount || 0;
      return Math.round(Math.max(shifAmount, minAmount) * 100) / 100;
    }

    throw new NotFoundException(
      `SHIF tax configuration not found for date ${date.toISOString()}`,
    );
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
        Math.round(
          grossSalary * (housingConfig.configuration.percentage / 100) * 100,
        ) / 100
      );
    }

    throw new NotFoundException(
      `Housing Levy tax configuration not found for date ${date.toISOString()}`,
    );
  }

  /**
   * Calculate all taxes for a given gross salary
   * Using TaxConfigService for current Kenya tax rates
   */
  async calculateTaxes(
    grossSalary: number,
    date: Date = new Date(),
    options: {
      pensionContribution?: number;
      nonCashBenefits?: number;
      mortgageInterest?: number;
      postRetirementMedicalContribution?: number;
      lifeInsurancePremium?: number;
      hasDisabilityExemption?: boolean;
    } = {},
  ): Promise<TaxBreakdown> {
    // Statutory contributions apply to cash gross pay. Non-cash benefits are
    // added only to taxable employment income inside the PAYE calculation.
    const [nssf, shif, housingLevy] = await Promise.all([
      this.calculateNSSF(grossSalary, date),
      this.calculateSHIF(grossSalary, date),
      this.calculateHousingLevy(grossSalary, date),
    ]);
    const payeCalculation = await this.calculatePAYEFromConfig(
      grossSalary,
      nssf,
      shif,
      housingLevy,
      date,
      options,
    );
    const paye = payeCalculation.paye;

    const totalDeductions = nssf + shif + housingLevy + paye;

    return {
      nssf,
      nhif: shif,
      housingLevy,
      paye,
      totalDeductions: Math.round(totalDeductions * 100) / 100,
      taxablePay: payeCalculation.taxablePay,
      taxCharged: payeCalculation.taxCharged,
      personalReliefApplied: payeCalculation.personalReliefApplied,
      insuranceReliefApplied: payeCalculation.insuranceReliefApplied,
      allowablePensionDeduction: payeCalculation.allowablePensionDeduction,
      allowableMortgageInterest: payeCalculation.allowableMortgageInterest,
      allowablePostRetirementMedicalContribution:
        payeCalculation.allowablePostRetirementMedicalContribution,
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
   * Calculate the Gross Salary required to achieve a specific Target Net Pay.
   * Uses a binary search algorithm to find the exact gross amount.
   *
   * Tax configs are fetched once upfront and passed through to avoid
   * repeated DB round-trips on every binary-search iteration.
   */
  async calculateGrossFromNet(
    targetNet: number,
    date: Date = new Date(),
    options: {
      pensionContribution?: number;
      nonCashBenefits?: number;
      hasDisabilityExemption?: boolean;
    } = {},
  ): Promise<number> {
    if (targetNet <= 0) return 0;

    // ── Fetch all tax configs once, upfront ──────────────────────────────────
    const [tier1Config, tier2Config, shifConfig, housingConfig, payeConfig] =
      await Promise.all([
        this.taxConfigService.getActiveTaxConfig(TaxType.NSSF_TIER1, date),
        this.taxConfigService.getActiveTaxConfig(TaxType.NSSF_TIER2, date),
        this.taxConfigService.getActiveTaxConfig(TaxType.SHIF, date),
        this.taxConfigService.getActiveTaxConfig(TaxType.HOUSING_LEVY, date),
        this.taxConfigService.getActiveTaxConfig(TaxType.PAYE, date),
      ]);

    if (
      !tier1Config ||
      !tier2Config ||
      !shifConfig ||
      !housingConfig ||
      !payeConfig
    ) {
      throw new NotFoundException(
        `Incomplete tax configuration for date ${date.toISOString()}`,
      );
    }

    // ── Pure synchronous tax calculation using pre-fetched configs ───────────
    const calcTaxesSync = (grossSalary: number): number => {
      const nssf = this.calculateNSSFWithConfigs(
        grossSalary,
        tier1Config,
        tier2Config,
      );

      // SHIF must be calculated before PAYE because it is an allowable
      // deduction from taxable employment income.
      let shif = 0;
      if (
        grossSalary > 0 &&
        shifConfig?.configuration?.percentage !== undefined
      ) {
        const shifAmount =
          grossSalary * (shifConfig.configuration.percentage / 100);
        const minAmount = shifConfig.configuration.minAmount || 0;
        shif = Math.round(Math.max(shifAmount, minAmount) * 100) / 100;
      }

      // Housing Levy (employee portion)
      let housingLevy = 0;
      if (housingConfig?.configuration?.percentage !== undefined) {
        housingLevy =
          Math.round(
            grossSalary * (housingConfig.configuration.percentage / 100) * 100,
          ) / 100;
      }

      // PAYE
      let paye = 0;
      if (payeConfig?.configuration?.brackets) {
        const {
          pensionContribution = 0,
          nonCashBenefits = 0,
          hasDisabilityExemption = false,
        } = options;

        const maxPension =
          payeConfig.configuration.maxAllowablePension ?? 30000;
        const nonCashBenefitThreshold =
          payeConfig.configuration.nonCashBenefitExemptionThreshold ?? 5000;
        const disabilityAmount =
          payeConfig.configuration.disabilityExemptionAmount ?? 150000;

        const allowablePensionDeduction = Math.min(
          Math.max(0, nssf + pensionContribution),
          maxPension,
        );
        const taxableNonCashBenefits =
          nonCashBenefits >= nonCashBenefitThreshold ? nonCashBenefits : 0;
        let taxableIncome = Math.max(
          0,
          grossSalary +
            taxableNonCashBenefits -
            allowablePensionDeduction -
            shif -
            housingLevy,
        );

        if (hasDisabilityExemption) {
          taxableIncome = Math.max(0, taxableIncome - disabilityAmount);
        }

        let tax = 0;
        let remaining = taxableIncome;
        let prevLimit = 0;
        for (const bracket of payeConfig.configuration.brackets) {
          if (remaining <= 0) break;
          const taxable =
            bracket.to === null
              ? remaining
              : Math.min(remaining, bracket.to - prevLimit);
          tax += taxable * bracket.rate;
          remaining -= taxable;
          prevLimit = bracket.to || prevLimit;
        }
        const relief = payeConfig.configuration.personalRelief || 2400;
        paye = Math.round(Math.max(0, tax - relief) * 100) / 100;
      }

      return Math.round((nssf + paye + shif + housingLevy) * 100) / 100;
    };

    // ── Binary search using synchronous calculator ───────────────────────────
    let lowGross = targetNet;
    let highGross = targetNet * 2;

    // Ensure upper bound is high enough
    while (highGross - calcTaxesSync(highGross) < targetNet) {
      highGross *= 2;
    }

    const epsilon = 0.01;
    let guessedGross = (lowGross + highGross) / 2;

    for (let i = 0; i < 50; i++) {
      guessedGross = (lowGross + highGross) / 2;
      const currentNet = guessedGross - calcTaxesSync(guessedGross);

      if (Math.abs(currentNet - targetNet) <= epsilon) break;

      if (currentNet < targetNet) {
        lowGross = guessedGross;
      } else {
        highGross = guessedGross;
      }
    }

    return Math.round(guessedGross * 100) / 100;
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
    // suppress unused warnings with dummy variables
    void userId;
    void year;
    void month;

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
      console.warn(
        'Failed to load payPeriod relation:',
        error instanceof Error ? error.message : String(error),
      );
      try {
        return await this.taxSubmissionRepository.find({
          where: { userId },
          order: { createdAt: 'DESC' },
        });
      } catch (fallbackError) {
        console.error(
          'Failed to load tax submissions:',
          fallbackError instanceof Error
            ? fallbackError.message
            : String(fallbackError),
        );
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
        status: PayrollStatus.FINALIZED,
      },
    });

    if (payrollRecords.length === 0) {
      throw new NotFoundException(
        'No finalized payroll records found for this period',
      );
    }

    // Aggregate tax amounts
    const totalPaye = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxAmount || 0),
      0,
    );
    const totalNssf = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown?.nssf || 0),
      0,
    );
    const totalNhif = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown?.nhif || 0),
      0,
    );
    const totalHousingLevy = payrollRecords.reduce(
      (sum, record) => sum + Number(record.taxBreakdown?.housingLevy || 0),
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

  async getMonthlySummaries(userId: string): Promise<any[]> {
    interface TaxMonthSummary {
      year: number;
      month: number;
      monthName: string;
      totalPaye: number;
      totalNssf: number;
      totalNhif: number;
      totalHousingLevy: number;
      totalTax: number;
      status: string;
      submissions: TaxSubmission[];
      submissionIds: string[];
    }
    const submissions = await this.getSubmissions(userId);
    const summaries = new Map<string, TaxMonthSummary>();

    for (const sub of submissions) {
      // Use payPeriod endDate to determine tax month
      // Default to createdAt if payPeriod relation missing (fallback)
      let date = sub.payPeriod?.endDate
        ? new Date(sub.payPeriod.endDate)
        : sub.createdAt;

      // Validate date to prevent RangeError
      if (isNaN(date.getTime())) {
        console.warn(
          `[TaxesService] Invalid date found for submission ${sub.id}, falling back to createdAt`,
        );
        date =
          sub.createdAt instanceof Date
            ? sub.createdAt
            : new Date(sub.createdAt);
      }

      // Final fallback if even createdAt is invalid (unlikely but safe)
      if (isNaN(date.getTime())) {
        console.warn(
          `[TaxesService] Invalid createdAt for submission ${sub.id}, falling back to current date`,
        );
        date = new Date();
      }

      const year = date.getFullYear();
      const month = date.getMonth(); // 0-11
      const key = `${year}-${month}`;

      if (!summaries.has(key)) {
        let monthName = 'Unknown';
        try {
          monthName = new Intl.DateTimeFormat('en-US', {
            month: 'long',
          }).format(date);
        } catch (e) {
          console.error(
            `[TaxesService] Failed to format month for date ${date.toISOString()}: ${e instanceof Error ? e.message : String(e)}`,
          );
        }

        summaries.set(key, {
          year,
          month,
          monthName,
          totalPaye: 0,
          totalNssf: 0,
          totalNhif: 0,
          totalHousingLevy: 0,
          totalTax: 0,
          status: 'FILED', // Start as FILED, if any is PENDING, switch to PENDING
          submissions: [],
          submissionIds: [],
        });
      }

      const summary = summaries.get(key);
      if (!summary) continue;
      summary.totalPaye += Number(sub.totalPaye);
      summary.totalNssf += Number(sub.totalNssf);
      summary.totalNhif += Number(sub.totalNhif);
      summary.totalHousingLevy += Number(sub.totalHousingLevy);
      summary.totalTax +=
        Number(sub.totalPaye) +
        Number(sub.totalNssf) +
        Number(sub.totalNhif) +
        Number(sub.totalHousingLevy);

      if (sub.status === TaxSubmissionStatus.PENDING) {
        summary.status = 'PENDING';
      }

      summary.submissions.push(sub);
      summary.submissionIds.push(sub.id);
    }

    // Convert map to array and sort by date descending
    return Array.from(summaries.values()).sort((a, b) => {
      if (a.year !== b.year) return b.year - a.year;
      return b.month - a.month;
    });
  }

  async markMonthAsFiled(
    userId: string,
    year: number,
    month: number,
  ): Promise<void> {
    const submissions = await this.getSubmissions(userId);
    const toFile: TaxSubmission[] = [];

    for (const sub of submissions) {
      const date = sub.payPeriod?.endDate
        ? new Date(sub.payPeriod.endDate)
        : sub.createdAt;

      if (date.getFullYear() === year && date.getMonth() === month) {
        if (sub.status === TaxSubmissionStatus.PENDING) {
          toFile.push(sub);
        }
      }
    }

    if (toFile.length === 0) {
      throw new NotFoundException(
        'No pending submissions found for this month',
      );
    }

    const filedDate = new Date();
    for (const sub of toFile) {
      sub.status = TaxSubmissionStatus.FILED;
      sub.filingDate = filedDate;
      await this.taxSubmissionRepository.save(sub);
    }

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.TAX,
        'Monthly Tax Filed',
        `Filed tax returns for ${new Intl.DateTimeFormat('en-US', { month: 'long' }).format(new Date(year, month))} ${year}`,
        {
          count: toFile.length,
          year,
          month,
          ids: toFile.map((s) => s.id),
        },
      );
    } catch (e) {
      console.error('Failed to log activity:', e);
    }
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
