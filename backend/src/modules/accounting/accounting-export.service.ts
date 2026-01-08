import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import {
  AccountMapping,
  AccountCategory,
} from './entities/account-mapping.entity';
import {
  AccountingExport,
  ExportFormat,
  ExportStatus,
} from './entities/accounting-export.entity';
import { ActivitiesService } from '../activities/activities.service';
import { ActivityType } from '../activities/entities/activity.entity';

export interface JournalEntry {
  date: Date;
  account: string;
  accountName: string;
  debit: number;
  credit: number;
  description: string;
}

export interface JournalEntrySet {
  entries: JournalEntry[];
  totalDebits: number;
  totalCredits: number;
  isBalanced: boolean;
}

@Injectable()
export class AccountingExportService {
  constructor(
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(AccountMapping)
    private accountMappingRepository: Repository<AccountMapping>,
    @InjectRepository(AccountingExport)
    private accountingExportRepository: Repository<AccountingExport>,
    private activitiesService: ActivitiesService,
  ) {}

  async generateJournalEntries(
    payPeriodId: string,
    userId: string,
  ): Promise<JournalEntrySet> {
    // Get all finalized payroll records for this period
    const payrollRecords = await this.payrollRecordRepository.find({
      where: {
        payPeriodId,
        userId,
        status: PayrollStatus.FINALIZED,
      },
      relations: ['worker'],
    });

    if (payrollRecords.length === 0) {
      throw new Error(
        'No finalized payroll records found for this period. Please process and finalize payroll first.',
      );
    }

    // Get user's account mappings
    const mappings = await this.getAccountMappings(userId);

    // Aggregate totals
    const totals = this.aggregatePayrollTotals(payrollRecords);

    // Generate journal entries
    const entries: JournalEntry[] = [];
    const date = new Date();
    const description = `Payroll for ${new Date(payrollRecords[0].createdAt).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`;

    // Debit: Salary Expense (Gross Salary)
    entries.push({
      date,
      account: mappings.SALARY_EXPENSE.accountCode,
      accountName: mappings.SALARY_EXPENSE.accountName,
      debit: totals.totalGrossSalary,
      credit: 0,
      description: `${description} - Gross Salaries`,
    });

    // Credit: PAYE Payable
    if (totals.totalPaye > 0) {
      entries.push({
        date,
        account: mappings.PAYE_LIABILITY.accountCode,
        accountName: mappings.PAYE_LIABILITY.accountName,
        debit: 0,
        credit: totals.totalPaye,
        description: `${description} - PAYE`,
      });
    }

    // Credit: NSSF Payable
    if (totals.totalNssf > 0) {
      entries.push({
        date,
        account: mappings.NSSF_LIABILITY.accountCode,
        accountName: mappings.NSSF_LIABILITY.accountName,
        debit: 0,
        credit: totals.totalNssf,
        description: `${description} - NSSF`,
      });
    }

    // Credit: NHIF Payable
    if (totals.totalNhif > 0) {
      entries.push({
        date,
        account: mappings.NHIF_LIABILITY.accountCode,
        accountName: mappings.NHIF_LIABILITY.accountName,
        debit: 0,
        credit: totals.totalNhif,
        description: `${description} - NHIF`,
      });
    }

    // Credit: Housing Levy Payable
    if (totals.totalHousingLevy > 0) {
      entries.push({
        date,
        account: mappings.HOUSING_LEVY_LIABILITY.accountCode,
        accountName: mappings.HOUSING_LEVY_LIABILITY.accountName,
        debit: 0,
        credit: totals.totalHousingLevy,
        description: `${description} - Housing Levy`,
      });
    }

    // Credit: Cash/Bank (Net Pay)
    entries.push({
      date,
      account: mappings.CASH_BANK.accountCode,
      accountName: mappings.CASH_BANK.accountName,
      debit: 0,
      credit: totals.totalNetPay,
      description: `${description} - Net Pay`,
    });

    // Calculate totals
    const totalDebits = entries.reduce((sum, e) => sum + e.debit, 0);
    const totalCredits = entries.reduce((sum, e) => sum + e.credit, 0);

    // Handle any difference (usually from other deductions like advances, loans, etc.)
    const difference = totalDebits - totalCredits;
    if (Math.abs(difference) > 0.01) {
      // Add a balancing entry for "Other Deductions"
      entries.push({
        date,
        account: '2190',
        accountName: 'Other Payroll Deductions',
        debit: 0,
        credit: difference,
        description: `${description} - Other Deductions/Adjustments`,
      });
    }

    // Recalculate after balancing
    const finalDebits = entries.reduce((sum, e) => sum + e.debit, 0);
    const finalCredits = entries.reduce((sum, e) => sum + e.credit, 0);
    const isBalanced = Math.abs(finalDebits - finalCredits) < 0.01;

    return {
      entries,
      totalDebits: finalDebits,
      totalCredits: finalCredits,
      isBalanced,
    };
  }

  async exportToCSV(payPeriodId: string, userId: string): Promise<string> {
    const journalEntries = await this.generateJournalEntries(
      payPeriodId,
      userId,
    );

    if (!journalEntries.isBalanced) {
      throw new Error('Journal entries are not balanced. Cannot export.');
    }

    // Generate CSV
    const headers = [
      'Date',
      'Account Code',
      'Account Name',
      'Debit',
      'Credit',
      'Description',
    ];
    const rows = journalEntries.entries.map((entry) => [
      entry.date.toISOString().split('T')[0],
      entry.account,
      entry.accountName,
      entry.debit > 0 ? entry.debit.toFixed(2) : '',
      entry.credit > 0 ? entry.credit.toFixed(2) : '',
      entry.description,
    ]);

    // Add totals row
    rows.push([
      '',
      '',
      'TOTALS',
      journalEntries.totalDebits.toFixed(2),
      journalEntries.totalCredits.toFixed(2),
      '',
    ]);

    const csv = [headers, ...rows]
      .map((row) => row.map((cell) => `"${cell}"`).join(','))
      .join('\n');

    // Save export record
    const exportRecord = this.accountingExportRepository.create({
      userId,
      payPeriodId,
      format: ExportFormat.CSV,
      status: ExportStatus.COMPLETED,
      createdAt: new Date(),
    });
    await this.accountingExportRepository.save(exportRecord);

    // Log activity
    await this.activitiesService.logActivity(
      userId,
      ActivityType.ACCOUNTING,
      'Payroll Exported',
      `Exported payroll for ${journalEntries.entries[0].date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`,
      { payPeriodId, format: ExportFormat.CSV },
    );

    return csv;
  }

  async getExportHistory(userId: string): Promise<AccountingExport[]> {
    return this.accountingExportRepository.find({
      where: { userId },
      relations: ['payPeriod'],
      order: { createdAt: 'DESC' },
    });
  }

  async getAccountMappings(
    userId: string,
  ): Promise<
    Record<AccountCategory, { accountCode: string; accountName: string }>
  > {
    const mappings = await this.accountMappingRepository.find({
      where: { userId },
    });

    // If no mappings exist, return defaults
    if (mappings.length === 0) {
      return this.getDefaultAccountMappings();
    }

    const result: Record<
      AccountCategory,
      { accountCode: string; accountName: string }
    > = {} as Record<
      AccountCategory,
      { accountCode: string; accountName: string }
    >;
    for (const mapping of mappings) {
      result[mapping.category] = {
        accountCode: mapping.accountCode,
        accountName: mapping.accountName,
      };
    }

    // Fill in any missing categories with defaults
    const defaults = this.getDefaultAccountMappings();
    for (const category of Object.values(AccountCategory)) {
      if (!result[category]) {
        result[category] = defaults[category];
      }
    }

    return result;
  }

  getDefaultAccountMappings(): Record<
    AccountCategory,
    { accountCode: string; accountName: string }
  > {
    return {
      [AccountCategory.GROSS_SALARY]: {
        accountCode: '6000',
        accountName: 'Gross Salary',
      },
      [AccountCategory.SALARY_EXPENSE]: {
        accountCode: '6100',
        accountName: 'Salaries and Wages',
      },
      [AccountCategory.PAYE_LIABILITY]: {
        accountCode: '2110',
        accountName: 'PAYE Payable',
      },
      [AccountCategory.NSSF_LIABILITY]: {
        accountCode: '2120',
        accountName: 'NSSF Payable',
      },
      [AccountCategory.NHIF_LIABILITY]: {
        accountCode: '2130',
        accountName: 'NHIF Payable',
      },
      [AccountCategory.HOUSING_LEVY_LIABILITY]: {
        accountCode: '2140',
        accountName: 'Housing Levy Payable',
      },
      [AccountCategory.CASH_BANK]: {
        accountCode: '1010',
        accountName: 'Cash at Bank',
      },
    };
  }

  async saveAccountMappings(
    userId: string,
    mappings: Array<{
      category: AccountCategory;
      accountCode: string;
      accountName: string;
    }>,
  ): Promise<AccountMapping[]> {
    // Delete existing mappings
    await this.accountMappingRepository.delete({ userId });

    // Create new mappings
    const entities = mappings.map((m) =>
      this.accountMappingRepository.create({
        userId,
        category: m.category,
        accountCode: m.accountCode,
        accountName: m.accountName,
      }),
    );

    return this.accountMappingRepository.save(entities);
  }

  private aggregatePayrollTotals(payrollRecords: PayrollRecord[]) {
    return {
      totalGrossSalary: payrollRecords.reduce(
        (sum, r) => sum + Number(r.grossSalary),
        0,
      ),
      totalPaye: payrollRecords.reduce(
        (sum, r) => sum + Number(r.taxAmount),
        0,
      ),
      totalNssf: payrollRecords.reduce(
        (sum, r) => sum + Number(r.taxBreakdown.nssf),
        0,
      ),
      totalNhif: payrollRecords.reduce(
        (sum, r) => sum + Number(r.taxBreakdown.nhif),
        0,
      ),
      totalHousingLevy: payrollRecords.reduce(
        (sum, r) => sum + Number(r.taxBreakdown.housingLevy),
        0,
      ),
      totalNetPay: payrollRecords.reduce(
        (sum, r) => sum + Number(r.netSalary),
        0,
      ),
    };
  }
}
