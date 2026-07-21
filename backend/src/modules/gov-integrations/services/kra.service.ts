import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as ExcelJS from 'exceljs';
import * as path from 'path';
import * as fs from 'fs';
import { PayrollRecord } from '../../payroll/entities/payroll-record.entity';
import { Worker } from '../../workers/entities/worker.entity';
import {
  GovSubmission,
  GovSubmissionType,
  GovSubmissionStatus,
} from '../entities/gov-submission.entity';

@Injectable()
export class KraService {
  private readonly outputDir = 'uploads/gov-files/kra';

  constructor(
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(GovSubmission)
    private readonly govSubmissionRepository: Repository<GovSubmission>,
  ) {
    this.ensureOutputDir();
  }

  private ensureOutputDir() {
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }
  }

  /**
   * Generate a PAYE supporting worksheet for a pay period.
   *
   * KRA's simplified PAYE return must be obtained from iTax. This workbook is
   * an audit/supporting schedule and is deliberately not represented as an
   * upload-ready KRA template. The method/type names remain for API and
   * database compatibility with existing clients.
   */
  async generateP10Excel(
    payPeriodId: string,
    userId: string,
  ): Promise<GovSubmission> {
    try {
      console.log(
        `[KRA Export] Starting P10 export for PayPeriod: ${payPeriodId}, User: ${userId}`,
      );

      // Fetch payroll records using QueryBuilder to ensure correct column mapping
      const records = await this.payrollRecordRepository
        .createQueryBuilder('pr')
        .leftJoinAndSelect('pr.worker', 'worker')
        .where('pr.payPeriodId = :payPeriodId', { payPeriodId })
        .getMany();

      if (records.length === 0) {
        console.error(
          `[KRA Export] No records found for PayPeriod: ${payPeriodId}`,
        );
        throw new Error('No payroll records found for this pay period');
      }

      console.log(`[KRA Export] Found ${records.length} records`);

      // Create a supporting workbook, not an iTax upload template.
      const workbook = new ExcelJS.Workbook();
      const readme = workbook.addWorksheet('Read_Me');
      readme.addRows([
        ['PAYE Supporting Schedule'],
        [
          'This workbook is not an iTax upload template. Use the current simplified PAYE return obtained from KRA/iTax for filing.',
        ],
        [
          'Review employee declarations and supporting documents before using these records to prepare a return.',
        ],
      ]);
      readme.getColumn(1).width = 120;
      readme.getRow(1).font = { bold: true, size: 14 };

      const sheet = workbook.addWorksheet('PAYE_Support');

      // Current payroll values used to support preparation of the official
      // simplified PAYE return.
      sheet.columns = [
        { header: 'Employee PIN', key: 'pin', width: 15 },
        { header: 'Employee Name', key: 'name', width: 30 },
        { header: 'Cash Gross Pay', key: 'cashGrossPay', width: 18 },
        { header: 'Non-Cash Benefits', key: 'nonCashBenefits', width: 18 },
        { header: 'Total Gross Pay', key: 'grossPay', width: 15 },
        { header: 'NSSF', key: 'nssf', width: 12 },
        { header: 'Employee Pension', key: 'pension', width: 18 },
        { header: 'Affordable Housing Levy', key: 'housingLevy', width: 22 },
        { header: 'SHIF', key: 'shif', width: 12 },
        { header: 'Post-Retirement Medical Fund', key: 'prmf', width: 28 },
        { header: 'Mortgage Interest', key: 'mortgageInterest', width: 15 },
        { header: 'PAYE', key: 'paye', width: 12 },
        {
          header: 'Total Statutory Deductions',
          key: 'totalStatutoryDeductions',
          width: 26,
        },
        { header: 'Net Pay', key: 'netPay', width: 15 },
      ];

      // Style header row
      sheet.getRow(1).font = { bold: true };
      sheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE0E0E0' },
      };

      // Add data rows
      let totalPaye = 0;
      for (const record of records) {
        const worker = record.worker;

        const cashGrossPay =
          Number(record.grossSalary || 0) +
          Number(record.bonuses || 0) +
          Number(record.otherEarnings || 0) +
          Number(record.overtimePay || 0);
        const nonCashBenefits = Number(record.nonCashBenefits || 0);
        const totalGrossPay = cashGrossPay + nonCashBenefits;

        const taxBreakdown = record.taxBreakdown || {};
        const paye = Number(taxBreakdown.paye || record.taxAmount || 0);
        const nssf = Number(taxBreakdown.nssf || 0);
        const shif = Number(taxBreakdown.nhif || taxBreakdown.shif || 0);
        const housingLevy = Number(taxBreakdown.housingLevy || 0);
        const totalStatutoryDeductions = Number(
          taxBreakdown.totalDeductions || 0,
        );

        totalPaye += paye;

        if (cashGrossPay === 0) {
          console.warn(
            `[KRA Export] Warning: Gross Salary is 0 for worker ${worker?.name} (ID: ${record.workerId})`,
          );
        }

        sheet.addRow({
          pin: worker?.kraPin || '',
          name: worker?.name || '',
          cashGrossPay,
          nonCashBenefits,
          grossPay: totalGrossPay,
          nssf,
          pension: Number(worker?.pensionContribution || 0),
          housingLevy,
          shif,
          prmf: Number(worker?.postRetirementMedicalContribution || 0),
          mortgageInterest: Number(worker?.mortgageInterest || 0),
          paye,
          totalStatutoryDeductions,
          netPay: Number(record.netSalary || 0),
        });
      }

      // Generate filename
      const timestamp = new Date().toISOString().split('T')[0];
      const fileName = `PAYE_SUPPORTING_SCHEDULE_${payPeriodId.substring(0, 8)}_${timestamp}.xlsx`;

      // Ensure output directory exists (using fs directly here in case ensureOutputDir has issues)
      if (!fs.existsSync(this.outputDir)) {
        console.log(`[KRA Export] Creating directory: ${this.outputDir}`);
        fs.mkdirSync(this.outputDir, { recursive: true });
      }

      const filePath = path.join(this.outputDir, fileName);
      console.log(`[KRA Export] Writing file to: ${filePath}`);

      // Write file
      await workbook.xlsx.writeFile(filePath);
      console.log(`[KRA Export] File written successfully`);

      // Create submission record
      const submission = this.govSubmissionRepository.create({
        userId,
        payPeriodId,
        type: GovSubmissionType.KRA_P10,
        status: GovSubmissionStatus.GENERATED,
        filePath,
        fileName,
        totalAmount: totalPaye,
        employeeCount: records.length,
      });

      await this.govSubmissionRepository.save(submission);
      console.log(`[KRA Export] Submission saved: ${submission.id}`);

      return submission;
    } catch (error) {
      console.error('[KRA Export] CRITICAL ERROR:', error);
      throw error;
    }
  }
}
