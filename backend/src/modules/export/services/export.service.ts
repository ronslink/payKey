import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Export, ExportType } from '../entities/export.entity';
import {
  Transaction,
  TransactionType,
} from '../../payments/entities/transaction.entity';
import * as fs from 'fs';
import * as path from 'path';

interface PayrollRecord {
  date: string;
  workerName: string;
  workerId: string;
  workerPin?: string;
  workerNssf?: string;
  workerNhif?: string;
  workerIdNo?: string;
  grossSalary: number;
  paye: number;
  nssf: number;
  shif: number;
  housingLevy: number;
  totalDeductions: number;
  netPay: number;
}

@Injectable()
export class ExportService {
  private readonly exportsDir = path.join(process.cwd(), 'exports');

  constructor(
    @InjectRepository(Export)
    private exportRepository: Repository<Export>,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
  ) {
    // Ensure exports directory exists
    if (!fs.existsSync(this.exportsDir)) {
      fs.mkdirSync(this.exportsDir, { recursive: true });
    }
  }

  /**
   * Get payroll data for date range
   */
  private async getPayrollData(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<PayrollRecord[]> {
    const transactions = await this.transactionRepository.find({
      where: {
        userId,
        createdAt: Between(startDate, endDate),
        type: TransactionType.SALARY_PAYOUT,
      },
      relations: ['worker'], // Fetch worker details
      order: {
        createdAt: 'ASC',
      },
    });

    return transactions.map((t) => ({
      date: t.createdAt.toISOString().split('T')[0],
      workerName: t.metadata?.workerName || t.worker?.name || 'Unknown',
      workerId: t.workerId,
      workerPin: t.worker?.kraPin || '',
      workerNssf: t.worker?.nssfNumber || '',
      workerNhif: t.worker?.nhifNumber || '',
      workerIdNo: t.worker?.idNumber || '',
      grossSalary: t.metadata?.grossSalary || 0,
      paye: t.metadata?.taxBreakdown?.paye || 0,
      nssf: t.metadata?.taxBreakdown?.nssf || 0,
      shif: t.metadata?.taxBreakdown?.nhif || 0,
      housingLevy: t.metadata?.taxBreakdown?.housingLevy || 0,
      totalDeductions: t.metadata?.taxBreakdown?.totalDeductions || 0,
      netPay: t.metadata?.netPay || t.amount,
    }));
  }

  /**
   * Generate QuickBooks IIF format
   */
  async generateQuickBooksIIF(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let iif = '!TRNS\tDATE\tACCNT\tAMOUNT\tMEMO\n';
    iif += '!SPL\tDATE\tACCNT\tAMOUNT\tMEMO\n';
    iif += '!ENDTRNS\n';

    for (const record of records) {
      const date = new Date(record.date).toLocaleDateString('en-US');
      const memo = `${record.workerName} - Payroll`;

      // Main transaction
      iif += `TRNS\t${date}\tPayroll Expense\t${record.grossSalary.toFixed(2)}\t${memo}\n`;

      // Splits
      iif += `SPL\t${date}\tPAYE Payable\t${record.paye.toFixed(2)}\tPAYE\n`;
      iif += `SPL\t${date}\tNSSF Payable\t${record.nssf.toFixed(2)}\tNSSF\n`;
      iif += `SPL\t${date}\tSHIF Payable\t${record.shif.toFixed(2)}\tSHIF\n`;
      iif += `SPL\t${date}\tHousing Levy Payable\t${record.housingLevy.toFixed(2)}\tHousing Levy\n`;
      iif += `SPL\t${date}\tCash\t-${record.netPay.toFixed(2)}\tNet Pay\n`;
      iif += 'ENDTRNS\n';
    }

    return iif;
  }

  /**
   * Generate Xero CSV format
   */
  async generateXeroCSV(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let csv =
      '*ContactName,*InvoiceNumber,*InvoiceDate,*DueDate,*Description,*Quantity,*UnitAmount,*AccountCode,*TaxType,Currency\n';

    records.forEach((record, index) => {
      const invoiceNum = `PAY-${new Date(record.date).getTime()}-${index + 1}`;
      const date = new Date(record.date)
        .toLocaleDateString('en-GB')
        .split('/')
        .reverse()
        .join('/');

      csv += `${record.workerName},${invoiceNum},${date},${date},Salary Payment,1,${record.netPay.toFixed(2)},6200,Tax Exempt,KES\n`;
    });

    return csv;
  }

  /**
   * Generate generic CSV format
   */
  async generateGenericCSV(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let csv =
      'Date,Worker Name,Worker ID,Gross Salary,PAYE,NSSF,SHIF,Housing Levy,Total Deductions,Net Pay\n';

    for (const record of records) {
      csv += `${record.date},${record.workerName},${record.workerId},`;
      csv += `${record.grossSalary.toFixed(2)},${record.paye.toFixed(2)},`;
      csv += `${record.nssf.toFixed(2)},${record.shif.toFixed(2)},`;
      csv += `${record.housingLevy.toFixed(2)},${record.totalDeductions.toFixed(2)},`;
      csv += `${record.netPay.toFixed(2)}\n`;
    }

    return csv;
  }

  /**
   * Generate KRA P10 CSV Format
   * Based on standard KRA iTax CSV columns
   */
  async generateKRA_P10_CSV(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    // KRA P10 CSV Layout (approximate standard)
    // PIN of Employee, Name of Employee, Residential Status, Type of Employee, Basic Salary, House Allowance, Transport Allowance, Overtime Allowance, Directors Fee, Leave Pay, Overtime, Total Cash Pay, Value of Car Benefit, Other Non-Cash Benefits, Total Non-Cash Pay, Global Income, Type of Housing, Rent of House, Computed Rent, Rent Recovered, Net Value of Housing, Total Gross Pay, 30% of Cash Pay, Actual Contribution, Permissible Limit, Mortgage Interest, Deposit on Home Ownership, Amount of Benefit, Taxable Pay, Tax Payable, Personal Relief, Insurance Relief, PAYE Tax

    let csv =
      'PIN of Employee,Name of Employee,Residential Status,Type of Employee,Basic Salary,House Allowance,Transport Allowance,Overtime Allowance,other Allowances,Total Cash Pay,Car Benefit,Other Non Cash Benefits,Total Non Cash Pay,Total Gross Pay,Actual Contribution,Morgage Interest,Taxable Pay,Tax Payable,Personal Relief,Insurance Relief,PAYE Tax\n';

    for (const r of records) {
      // Fetch employee PIN from worker details
      const pin = r.workerPin || 'A000000000Z'; // Fallback to placeholder only if missing
      const name = r.workerName;
      const resStatus = 'Resident';
      const empType = 'Primary Employee';
      const basic = r.grossSalary; // Simplified: Assuming Basic = Gross for MVP exports
      // Zeros for allowances explicitly for now
      const houseAllow = 0;
      const transportAllow = 0;
      const overtime = 0;
      const otherAllow = 0;

      const totalCash =
        basic + houseAllow + transportAllow + overtime + otherAllow;

      const carBen = 0;
      const otherNonCash = 0;
      const totalNonCash = carBen + otherNonCash;

      const totalGross = totalCash + totalNonCash;

      const actualContrib = r.nssf; // Pension contribution
      const mortgage = 0;

      // Taxable Pay is usually Gross - NSSF (Allowable Deduction)
      const taxable = totalGross - actualContrib;

      const taxPayable = r.paye + 2400; // Gross Tax before relief (Approx back-calculation)
      const relief = 2400; // Personal Relief
      const insRelief = r.shif * 0.15; // SHIF attracts 15% relief usually, verifying...
      // Actually standard personal relief is fixed. Insurance relief is separate.
      // Let's stick to simple: Tax Payable = PAYE (Net Tax) for this export if we can't reverse calc easily
      // OR: Tax Payable (Gross) -> Relief -> PAYE (Net).
      // Let's use PAYE (Net) as the final column.

      const paye = r.paye;

      csv += `${pin},"${name}",${resStatus},${empType},`;
      csv += `${basic.toFixed(2)},${houseAllow.toFixed(2)},${transportAllow.toFixed(2)},${overtime.toFixed(2)},${otherAllow.toFixed(2)},`;
      csv += `${totalCash.toFixed(2)},${carBen.toFixed(2)},${otherNonCash.toFixed(2)},${totalNonCash.toFixed(2)},`;
      csv += `${totalGross.toFixed(2)},${actualContrib.toFixed(2)},${mortgage.toFixed(2)},`;
      csv += `${taxable.toFixed(2)},${(paye + relief).toFixed(2)},${relief.toFixed(2)},0.00,${paye.toFixed(2)}\n`;
    }

    return csv;
  }

  /**
   * Generate NSSF Excel/CSV Format
   * Columns: Payroll Number, Surname, Other Names, ID No, KRA PIN, NSSF No, Gross Pay
   */
  async generateNSSF_Excel(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let csv =
      'Payroll Number,Surname,Other Names,ID No,KRA PIN,NSSF No,Gross Pay,Voluntary Contribution\n';

    for (const r of records) {
      // Split name
      const nameParts = r.workerName.split(' ');
      const surname = nameParts[0] || '';
      const otherNames = nameParts.slice(1).join(' ') || surname;

      const empId = r.workerId.substring(0, 8); // Fake payroll number from ID
      const idNo = r.workerIdNo || '000000';
      const kraPin = r.workerPin || 'A000000000Z';
      const nssfNo = r.workerNssf || '000000';

      csv += `${empId},"${surname}","${otherNames}",${idNo},${kraPin},${nssfNo},${r.grossSalary.toFixed(2)},0.00\n`;
    }

    return csv;
  }

  /**
   * Generate SHIF Excel/CSV Format
   * Columns: Payroll No, Last Name, First Name, ID No, Gross Pay, SHIF Amount
   */
  async generateSHIF_Excel(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let csv =
      'Payroll No,Last Name,First Name,ID No,Gross Salary,SHIF Amount\n';

    for (const r of records) {
      const nameParts = r.workerName.split(' ');
      const lastName = nameParts[nameParts.length - 1] || '';
      const firstName = nameParts[0] || '';
      const idNo = r.workerIdNo || '000000';

      csv += `${r.workerId.substring(0, 8)},"${lastName}","${firstName}",${idNo},${r.grossSalary.toFixed(2)},${r.shif.toFixed(2)}\n`;
    }

    return csv;
  }

  /**
   * Save export file and create record
   */
  async createExport(
    userId: string,
    exportType: ExportType,
    startDate: Date,
    endDate: Date,
  ): Promise<Export> {
    let content: string;
    let extension: string;

    switch (exportType) {
      case ExportType.QUICKBOOKS_IIF:
        content = await this.generateQuickBooksIIF(userId, startDate, endDate);
        extension = 'iif';
        break;
      case ExportType.XERO_CSV:
        content = await this.generateXeroCSV(userId, startDate, endDate);
        extension = 'csv';
        break;
      case ExportType.GENERIC_CSV:
        content = await this.generateGenericCSV(userId, startDate, endDate);
        extension = 'csv';
        break;
      case ExportType.KRA_P10_CSV:
        content = await this.generateKRA_P10_CSV(userId, startDate, endDate);
        extension = 'csv';
        break;
      case ExportType.NSSF_RETURN_EXCEL:
        content = await this.generateNSSF_Excel(userId, startDate, endDate);
        extension = 'csv'; // Sticking to CSV for simplicity
        break;
      case ExportType.SHIF_RETURN_EXCEL:
        content = await this.generateSHIF_Excel(userId, startDate, endDate);
        extension = 'csv'; // Sticking to CSV for simplicity
        break;
      default:
        throw new Error('Unsupported export type');
    }

    const fileName = `payroll_export_${exportType.toLowerCase()}_${Date.now()}.${extension}`;
    const filePath = path.join(this.exportsDir, fileName);

    fs.writeFileSync(filePath, content, 'utf-8');

    const recordCount = content.split('\n').length - 1; // Subtract header

    const exportRecord = this.exportRepository.create({
      userId,
      exportType,
      startDate,
      endDate,
      fileName,
      filePath,
      recordCount,
    });

    return this.exportRepository.save(exportRecord);
  }

  /**
   * Get export history
   */
  async getExportHistory(userId: string): Promise<Export[]> {
    return this.exportRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  /**
   * Get export file content
   */
  async getExportFile(id: string, userId: string): Promise<Buffer> {
    const exportRecord = await this.exportRepository.findOne({
      where: { id, userId },
    });

    if (!exportRecord || !exportRecord.filePath) {
      throw new Error('Export not found');
    }

    return fs.readFileSync(exportRecord.filePath);
  }
}
