import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Export, ExportType } from '../entities/export.entity';
import {
  Transaction,
  TransactionType,
} from '../../payments/entities/transaction.entity';
import { PayrollRecord } from '../../payroll/entities/payroll-record.entity';
import * as fs from 'fs';
import * as path from 'path';

interface ExportRecord {
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
    @InjectRepository(PayrollRecord) // Injected for robust data fetching
    private payrollRecordRepository: Repository<PayrollRecord>,
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
  ): Promise<ExportRecord[]> {
    console.log(
      `[Export Service] Fetching data for user ${userId} from ${startDate} to ${endDate}`,
    );

    const records = await this.payrollRecordRepository
      .createQueryBuilder('record')
      .leftJoinAndSelect('record.worker', 'worker')
      .where('record.userId = :userId', { userId })
      .andWhere('record.periodStart >= :startDate', { startDate })
      .andWhere('record.periodStart <= :endDate', { endDate })
      .orderBy('record.periodStart', 'ASC')
      .getMany();

    console.log(`[Export Service] Found ${records.length} records`);

    return records.map((r) => {
      // Use payment date if paid, otherwise period end date or current date
      let date = r.paymentDate
        ? new Date(r.paymentDate)
        : new Date(r.periodEnd);
      if (isNaN(date.getTime())) date = new Date(r.periodEnd || new Date());

      // Ensure tax breakdown exists with defaults
      const tax = r.taxBreakdown || {};

      const grossSalary = Number(r.grossSalary) || 0;

      // Debug log for zero values
      if (grossSalary === 0) {
        console.warn(
          `[Export Service] Warning: Zero gross salary for worker ${r.worker?.name} (${r.workerId})`,
        );
      }

      return {
        date: date.toISOString().split('T')[0],
        workerName: r.worker?.name || 'Unknown',
        workerId: r.workerId,
        workerPin: r.worker?.kraPin || '',
        workerNssf: r.worker?.nssfNumber || '',
        workerNhif: r.worker?.nhifNumber || '',
        workerIdNo: r.worker?.idNumber || '',
        grossSalary: grossSalary,
        paye: Number(tax.paye) || 0,
        nssf: Number(tax.nssf) || 0,
        shif: Number(tax.shif) || Number(tax.nhif) || 0,
        housingLevy: Number(tax.housingLevy) || 0,
        totalDeductions:
          (Number(r.taxAmount) || 0) + (Number(r.otherDeductions) || 0),
        netPay: Number(r.netSalary) || 0,
      };
    });
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
      const name = r.workerName || 'Unknown';
      const resStatus = 'Resident';
      const empType = 'Primary Employee';

      // Defensive casting to ensure all values are numbers
      const basic = Number(r.grossSalary) || 0;
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

      const actualContrib = Number(r.nssf) || 0; // Pension contribution
      const mortgage = 0;

      // Taxable Pay is usually Gross - NSSF (Allowable Deduction)
      const taxable = Math.max(0, totalGross - actualContrib);

      const paye = Number(r.paye) || 0;
      const relief = 2400; // Personal Relief
      const taxPayable = paye + relief;
      const insRelief = (Number(r.shif) || 0) * 0.15;

      csv += `${pin},"${name}",${resStatus},${empType},`;
      csv += `${basic.toFixed(2)},${houseAllow.toFixed(2)},${transportAllow.toFixed(2)},${overtime.toFixed(2)},${otherAllow.toFixed(2)},`;
      csv += `${totalCash.toFixed(2)},${carBen.toFixed(2)},${otherNonCash.toFixed(2)},${totalNonCash.toFixed(2)},`;
      csv += `${totalGross.toFixed(2)},${actualContrib.toFixed(2)},${mortgage.toFixed(2)},`;
      csv += `${taxable.toFixed(2)},${taxPayable.toFixed(2)},${relief.toFixed(2)},${insRelief.toFixed(2)},${paye.toFixed(2)}\n`;
    }

    // Calculate and add totals row
    let totalBasic = 0,
      totalHouseAllow = 0,
      totalTransportAllow = 0,
      totalOvertime = 0,
      totalOtherAllow = 0;
    let totalCashPay = 0,
      totalCarBen = 0,
      totalOtherNonCash = 0,
      totalNonCash = 0;
    let totalGrossPay = 0,
      totalContrib = 0,
      totalMortgage = 0,
      totalTaxable = 0;
    let totalTaxPayable = 0,
      totalRelief = 0,
      totalInsRelief = 0,
      totalPaye = 0;

    for (const r of records) {
      const basic = Number(r.grossSalary) || 0;
      const nssf = Number(r.nssf) || 0;
      const shif = Number(r.shif) || 0;
      const paye = Number(r.paye) || 0;

      totalBasic += basic;
      totalCashPay += basic;
      totalGrossPay += basic;
      totalContrib += nssf;
      totalTaxable += Math.max(0, basic - nssf);
      totalTaxPayable += paye + 2400;
      totalRelief += 2400;
      totalInsRelief += shif * 0.15;
      totalPaye += paye;
    }

    // Add totals row with 'TOTAL' as the name
    csv += `TOTAL,TOTALS,Resident,Primary Employee,`;
    csv += `${totalBasic.toFixed(2)},${totalHouseAllow.toFixed(2)},${totalTransportAllow.toFixed(2)},${totalOvertime.toFixed(2)},${totalOtherAllow.toFixed(2)},`;
    csv += `${totalCashPay.toFixed(2)},${totalCarBen.toFixed(2)},${totalOtherNonCash.toFixed(2)},${totalNonCash.toFixed(2)},`;
    csv += `${totalGrossPay.toFixed(2)},${totalContrib.toFixed(2)},${totalMortgage.toFixed(2)},`;
    csv += `${totalTaxable.toFixed(2)},${totalTaxPayable.toFixed(2)},${totalRelief.toFixed(2)},${totalInsRelief.toFixed(2)},${totalPaye.toFixed(2)}\n`;

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
   * Generate Muster Roll CSV format
   * Attendance/payroll register with basic employee pay info
   */
  async generateMusterRollCSV(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<string> {
    const records = await this.getPayrollData(userId, startDate, endDate);

    let csv =
      'EMP NO,NAME,ID NUMBER,PHONE,GROSS SALARY,PAYE,NSSF,SHIF,HOUSING LEVY,TOTAL DEDUCTIONS,NET PAY,SIGNATURE\n';

    for (const r of records) {
      const empNo = r.workerId.substring(0, 8);
      const idNo = r.workerIdNo || '-';

      csv += `${empNo},"${r.workerName}",${idNo},-,`;
      csv += `${r.grossSalary.toFixed(2)},${r.paye.toFixed(2)},${r.nssf.toFixed(2)},`;
      csv += `${r.shif.toFixed(2)},${r.housingLevy.toFixed(2)},${r.totalDeductions.toFixed(2)},`;
      csv += `${r.netPay.toFixed(2)},\n`;
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
    console.log(
      `[Export] Creating export: type=${exportType}, userId=${userId}, dates=${startDate.toISOString()} to ${endDate.toISOString()}`,
    );

    let content: string;
    let extension: string;

    try {
      switch (exportType) {
        case ExportType.QUICKBOOKS_IIF:
          content = await this.generateQuickBooksIIF(
            userId,
            startDate,
            endDate,
          );
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
          extension = 'csv';
          break;
        case ExportType.SHIF_RETURN_EXCEL:
          content = await this.generateSHIF_Excel(userId, startDate, endDate);
          extension = 'csv';
          break;
        case ExportType.MUSTER_ROLL_CSV:
          content = await this.generateMusterRollCSV(
            userId,
            startDate,
            endDate,
          );
          extension = 'csv';
          break;
        default:
          throw new Error(`Unsupported export type: ${exportType}`);
      }
    } catch (error) {
      console.error(`[Export] Failed to generate content: ${error.message}`);
      throw error;
    }

    console.log(
      `[Export] Generated content length: ${content?.length || 0} chars`,
    );

    const fileName = `payroll_export_${exportType.toLowerCase()}_${Date.now()}.${extension}`;
    const filePath = path.join(this.exportsDir, fileName);

    // Ensure exports directory exists
    try {
      if (!fs.existsSync(this.exportsDir)) {
        console.log(`[Export] Creating exports directory: ${this.exportsDir}`);
        fs.mkdirSync(this.exportsDir, { recursive: true });
      }
      console.log(`[Export] Writing file: ${filePath}`);
      fs.writeFileSync(filePath, content, 'utf-8');
    } catch (error) {
      console.error(`[Export] Failed to write file: ${error.message}`);
      throw new Error(`Failed to write export file: ${error.message}`);
    }

    const recordCount = content.split('\n').length - 1;
    console.log(`[Export] Record count: ${recordCount}`);

    try {
      const exportRecord = this.exportRepository.create({
        userId,
        exportType,
        startDate,
        endDate,
        fileName,
        filePath,
        recordCount,
      });

      const saved = await this.exportRepository.save(exportRecord);
      console.log(`[Export] Saved export record: id=${saved.id}`);
      return saved;
    } catch (error) {
      console.error(`[Export] Failed to save to DB: ${error.message}`);
      // Clean up the file if DB save fails
      try {
        fs.unlinkSync(filePath);
      } catch {}
      throw new Error(`Failed to save export record: ${error.message}`);
    }
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
