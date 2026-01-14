import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as ExcelJS from 'exceljs';
import * as path from 'path';
import * as fs from 'fs';
import { PayrollRecord } from '../../payroll/entities/payroll-record.entity';
import { Worker } from '../../workers/entities/worker.entity';
import { GovSubmission, GovSubmissionType, GovSubmissionStatus } from '../entities/gov-submission.entity';

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
     * Generate P10 Excel file in KRA format for a pay period
     */
    async generateP10Excel(payPeriodId: string, userId: string): Promise<GovSubmission> {
        // Fetch payroll records for this period
        const records = await this.payrollRecordRepository.find({
            where: { payPeriodId },
            relations: ['worker'],
        });

        if (records.length === 0) {
            throw new Error('No payroll records found for this pay period');
        }

        // Create workbook
        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('P10_Data');

        // Add headers (KRA P10 format)
        sheet.columns = [
            { header: 'PIN', key: 'pin', width: 15 },
            { header: 'Employee Name', key: 'name', width: 30 },
            { header: 'Residential Status', key: 'residentialStatus', width: 15 },
            { header: 'Type of Employee', key: 'employeeType', width: 15 },
            { header: 'Basic Salary', key: 'basicSalary', width: 15 },
            { header: 'Housing Allowance', key: 'housingAllowance', width: 15 },
            { header: 'Transport Allowance', key: 'transportAllowance', width: 15 },
            { header: 'Leave Pay', key: 'leavePay', width: 12 },
            { header: 'Overtime', key: 'overtime', width: 12 },
            { header: 'Directors Fees', key: 'directorsFees', width: 15 },
            { header: 'Lump Sum Payments', key: 'lumpSum', width: 15 },
            { header: 'Other Allowances', key: 'otherAllowances', width: 15 },
            { header: 'Total Gross Pay', key: 'grossPay', width: 15 },
            { header: 'Defined Benefit', key: 'definedBenefit', width: 15 },
            { header: 'Defined Contribution', key: 'definedContribution', width: 15 },
            { header: 'Mortgage Interest', key: 'mortgageInterest', width: 15 },
            { header: 'HOSP', key: 'hosp', width: 12 },
            { header: 'Amount of Benefit', key: 'benefitAmount', width: 15 },
            { header: 'Value of Quarters', key: 'quarters', width: 15 },
            { header: 'Owner Occupied Interest', key: 'ownerInterest', width: 20 },
            { header: 'Taxable Pay', key: 'taxablePay', width: 15 },
            { header: 'Tax Payable', key: 'taxPayable', width: 15 },
            { header: 'Personal Relief', key: 'personalRelief', width: 15 },
            { header: 'Insurance Relief', key: 'insuranceRelief', width: 15 },
            { header: 'PAYE Tax', key: 'payeTax', width: 12 },
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
            const worker = record.worker as Worker;
            const taxBreakdown = record.taxBreakdown || {};
            const paye = Number(taxBreakdown.paye || record.taxAmount || 0);
            const nssf = Number(taxBreakdown.nssf || 0);
            totalPaye += paye;

            sheet.addRow({
                pin: worker?.kraPin || 'N/A',
                name: worker?.name || 'Unknown',
                residentialStatus: 'R', // Resident
                employeeType: 'P', // Primary
                basicSalary: Number(record.grossSalary || 0),
                housingAllowance: Number(worker?.housingAllowance || 0),
                transportAllowance: Number(worker?.transportAllowance || 0),
                leavePay: 0,
                overtime: Number(record.overtimePay || 0),
                directorsFees: 0,
                lumpSum: 0,
                otherAllowances: Number(record.otherEarnings || 0),
                grossPay: Number(record.grossSalary || 0),
                definedBenefit: 0,
                definedContribution: nssf,
                mortgageInterest: 0,
                hosp: 0,
                benefitAmount: 0,
                quarters: 0,
                ownerInterest: 0,
                taxablePay: Number(record.grossSalary || 0) - nssf,
                taxPayable: paye + 2400, // Before relief
                personalRelief: 2400,
                insuranceRelief: 0,
                payeTax: paye,
            });
        }

        // Generate filename
        const timestamp = new Date().toISOString().split('T')[0];
        const fileName = `P10_${payPeriodId.substring(0, 8)}_${timestamp}.xlsx`;
        const filePath = path.join(this.outputDir, fileName);

        // Write file
        await workbook.xlsx.writeFile(filePath);

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

        return submission;
    }
}
