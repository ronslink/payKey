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
      order: {
        createdAt: 'ASC',
      },
    });

    return transactions.map((t) => ({
      date: t.createdAt.toISOString().split('T')[0],
      workerName: t.metadata?.workerName || 'Unknown',
      workerId: t.workerId,
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
      default:
        throw new Error('Unsupported export type');
    }

    const fileName = `payroll_export_${Date.now()}.${extension}`;
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
