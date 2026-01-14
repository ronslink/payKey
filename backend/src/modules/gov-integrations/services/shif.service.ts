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
export class ShifService {
    private readonly outputDir = 'uploads/gov-files/shif';

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
     * Generate SHIF contribution file for SHA portal
     * Rate: 2.75% of gross salary (min KES 300)
     */
    async generateContributionFile(payPeriodId: string, userId: string): Promise<GovSubmission> {
        const records = await this.payrollRecordRepository.find({
            where: { payPeriodId },
            relations: ['worker'],
        });

        if (records.length === 0) {
            throw new Error('No payroll records found for this pay period');
        }

        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('SHIF_Contributions');

        // SHA format columns
        sheet.columns = [
            { header: 'ID Number', key: 'idNumber', width: 15 },
            { header: 'Employee Name', key: 'name', width: 30 },
            { header: 'SHIF Number', key: 'shifNumber', width: 15 },
            { header: 'Gross Salary', key: 'grossSalary', width: 15 },
            { header: 'SHIF Contribution (2.75%)', key: 'contribution', width: 20 },
            { header: 'Phone Number', key: 'phone', width: 15 },
        ];

        sheet.getRow(1).font = { bold: true };
        sheet.getRow(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FF4CAF50' },
        };

        let totalContribution = 0;
        for (const record of records) {
            const worker = record.worker as Worker;
            const taxBreakdown = record.taxBreakdown || {};
            // SHIF is stored as nhif or shif in taxBreakdown
            const shif = Number(taxBreakdown.nhif || taxBreakdown.shif || 0);
            totalContribution += shif;

            sheet.addRow({
                idNumber: worker?.idNumber || 'N/A',
                name: worker?.name || 'Unknown',
                shifNumber: worker?.nhifNumber || 'N/A', // NHIF number transitions to SHIF
                grossSalary: Number(record.grossSalary || 0),
                contribution: shif,
                phone: worker?.phoneNumber || '',
            });
        }

        // Add totals row
        sheet.addRow({});
        sheet.addRow({
            idNumber: '',
            name: 'TOTAL',
            shifNumber: '',
            grossSalary: '',
            contribution: totalContribution,
            phone: '',
        });

        const timestamp = new Date().toISOString().split('T')[0];
        const fileName = `SHIF_${payPeriodId.substring(0, 8)}_${timestamp}.xlsx`;
        const filePath = path.join(this.outputDir, fileName);

        await workbook.xlsx.writeFile(filePath);

        const submission = this.govSubmissionRepository.create({
            userId,
            payPeriodId,
            type: GovSubmissionType.SHIF,
            status: GovSubmissionStatus.GENERATED,
            filePath,
            fileName,
            totalAmount: totalContribution,
            employeeCount: records.length,
        });

        await this.govSubmissionRepository.save(submission);

        return submission;
    }
}
