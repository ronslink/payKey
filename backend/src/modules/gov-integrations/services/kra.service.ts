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
        try {
            console.log(`[KRA Export] Starting P10 export for PayPeriod: ${payPeriodId}, User: ${userId}`);

            // Fetch payroll records using QueryBuilder to ensure correct column mapping
            const records = await this.payrollRecordRepository.createQueryBuilder('pr')
                .leftJoinAndSelect('pr.worker', 'worker')
                .where('pr.payPeriodId = :payPeriodId', { payPeriodId })
                .getMany();

            if (records.length === 0) {
                console.error(`[KRA Export] No records found for PayPeriod: ${payPeriodId}`);
                throw new Error('No payroll records found for this pay period');
            }

            console.log(`[KRA Export] Found ${records.length} records`);

            // Create workbook
            const workbook = new ExcelJS.Workbook();
            const sheet = workbook.addWorksheet('P10_Data');

            // Add headers (KRA P10 format - Standard iTax Monthly Return)
            sheet.columns = [
                { header: 'PIN', key: 'pin', width: 15 },
                { header: 'Employee Name', key: 'name', width: 30 },
                { header: 'Residential Status', key: 'residentialStatus', width: 15 },
                { header: 'Type of Employee', key: 'employeeType', width: 20 },
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
                const worker = record.worker;

                // Safe Number conversion with log for debugging
                const grossSalary = Number(record.grossSalary);
                const basicSalary = grossSalary; // MVP: Assuming basic = gross

                const taxBreakdown = record.taxBreakdown || {};
                const paye = Number(taxBreakdown.paye || record.taxAmount || 0);
                const nssf = Number(taxBreakdown.nssf || 0);
                const shif = Number(taxBreakdown.nhif || taxBreakdown.shif || 0); // Handle SHIF/NHIF mapping
                const housingLevy = Number(taxBreakdown.housingLevy || 0);

                totalPaye += paye;

                // Debug log if value is 0 unexpectedly
                if (grossSalary === 0) {
                    console.warn(`[KRA Export] Warning: Gross Salary is 0 for worker ${worker?.name} (ID: ${record.workerId})`);
                }

                sheet.addRow({
                    pin: worker?.kraPin || 'A000000000Z',
                    name: worker?.name || 'Unknown',
                    residentialStatus: 'Resident',
                    employeeType: 'Primary Employee',
                    basicSalary: basicSalary,
                    housingAllowance: Number(worker?.housingAllowance || 0),
                    transportAllowance: Number(worker?.transportAllowance || 0),
                    leavePay: 0,
                    overtime: Number(record.overtimePay || 0),
                    directorsFees: 0,
                    lumpSum: 0,
                    otherAllowances: Number(record.otherEarnings || 0),
                    grossPay: grossSalary,
                    definedBenefit: 0,
                    definedContribution: nssf,
                    mortgageInterest: 0,
                    hosp: 0,
                    benefitAmount: 0,
                    quarters: 0,
                    ownerInterest: 0,
                    taxablePay: Math.max(0, grossSalary - nssf), // Taxable Pay = Gross - NSSF (Allowable)
                    taxPayable: paye + 2400, // Approx (PAYE + Relief)
                    personalRelief: 2400,
                    insuranceRelief: shif * 0.15, // 15% of SHIF usually
                    payeTax: paye,
                });
            }

            // Generate filename
            const timestamp = new Date().toISOString().split('T')[0];
            const fileName = `KRA_P10_${payPeriodId.substring(0, 8)}_${timestamp}.xlsx`;

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
