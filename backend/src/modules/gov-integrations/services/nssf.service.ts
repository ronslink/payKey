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
export class NssfService {
    private readonly outputDir = 'uploads/gov-files/nssf';

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
     * Generate NSSF SF24 return file for ESSP portal
     * New Tier I/II rates apply (6% employee, 6% employer on pensionable pay)
     */
    async generateSF24(payPeriodId: string, userId: string): Promise<GovSubmission> {
        const records = await this.payrollRecordRepository.find({
            where: { payPeriodId },
            relations: ['worker'],
        });

        if (records.length === 0) {
            throw new Error('No payroll records found for this pay period');
        }

        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('SF24_Return');

        // NSSF SF24 format columns
        sheet.columns = [
            { header: 'NSSF Number', key: 'nssfNumber', width: 15 },
            { header: 'ID Number', key: 'idNumber', width: 15 },
            { header: 'Employee Name', key: 'name', width: 30 },
            { header: 'Gross Salary', key: 'grossSalary', width: 15 },
            { header: 'Employee Contribution', key: 'employeeContrib', width: 20 },
            { header: 'Employer Contribution', key: 'employerContrib', width: 20 },
            { header: 'Total Contribution', key: 'totalContrib', width: 20 },
        ];

        sheet.getRow(1).font = { bold: true };
        sheet.getRow(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FF2196F3' },
        };

        let totalEmployeeContrib = 0;
        let totalEmployerContrib = 0;

        for (const record of records) {
            const worker = record.worker as Worker;
            const taxBreakdown = record.taxBreakdown || {};
            const employeeNssf = Number(taxBreakdown.nssf || 0);
            // Employer matches employee contribution
            const employerNssf = employeeNssf;

            totalEmployeeContrib += employeeNssf;
            totalEmployerContrib += employerNssf;

            sheet.addRow({
                nssfNumber: worker?.nssfNumber || 'N/A',
                idNumber: worker?.idNumber || 'N/A',
                name: worker?.name || 'Unknown',
                grossSalary: Number(record.grossSalary || 0),
                employeeContrib: employeeNssf,
                employerContrib: employerNssf,
                totalContrib: employeeNssf + employerNssf,
            });
        }

        // Add totals row
        sheet.addRow({});
        const totalsRow = sheet.addRow({
            nssfNumber: '',
            idNumber: '',
            name: 'TOTAL',
            grossSalary: '',
            employeeContrib: totalEmployeeContrib,
            employerContrib: totalEmployerContrib,
            totalContrib: totalEmployeeContrib + totalEmployerContrib,
        });
        totalsRow.font = { bold: true };

        const timestamp = new Date().toISOString().split('T')[0];
        const fileName = `NSSF_SF24_${payPeriodId.substring(0, 8)}_${timestamp}.xlsx`;
        const filePath = path.join(this.outputDir, fileName);

        await workbook.xlsx.writeFile(filePath);

        const submission = this.govSubmissionRepository.create({
            userId,
            payPeriodId,
            type: GovSubmissionType.NSSF,
            status: GovSubmissionStatus.GENERATED,
            filePath,
            fileName,
            totalAmount: totalEmployeeContrib + totalEmployerContrib,
            employeeCount: records.length,
        });

        await this.govSubmissionRepository.save(submission);

        return submission;
    }
}
