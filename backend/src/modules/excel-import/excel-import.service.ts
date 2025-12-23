import { Injectable, BadRequestException } from '@nestjs/common';
import * as XLSX from 'xlsx';
import { WorkersService } from '../workers/workers.service';
import {
    EmployeeImportResultDto,
    ALL_COLUMNS,
} from './dto/employee-import.dto';

interface ParsedRow {
    name?: string;
    phoneNumber?: string;
    salaryGross?: number;
    idNumber?: string;
    kraPin?: string;
    nssfNumber?: string;
    nhifNumber?: string;
    jobTitle?: string;
    startDate?: string;
    dateOfBirth?: string;
}

@Injectable()
export class ExcelImportService {
    constructor(private readonly workersService: WorkersService) { }

    /**
     * Parse and validate Excel file for employee import
     */
    async importEmployees(
        buffer: Buffer,
        userId: string,
    ): Promise<EmployeeImportResultDto> {
        const result: EmployeeImportResultDto = {
            success: true,
            totalRows: 0,
            importedCount: 0,
            errorCount: 0,
            errors: [],
            importedEmployees: [],
        };

        try {
            // Parse Excel file
            const workbook = XLSX.read(buffer, { type: 'buffer' });
            const sheetName = workbook.SheetNames[0];

            if (!sheetName) {
                throw new BadRequestException('Excel file has no sheets');
            }

            const sheet = workbook.Sheets[sheetName];
            const rows: ParsedRow[] = XLSX.utils.sheet_to_json(sheet, {
                defval: '',
                raw: false,
            });

            if (rows.length === 0) {
                throw new BadRequestException('Excel file has no data rows');
            }

            result.totalRows = rows.length;

            // Validate header columns (first row keys)
            const firstRowKeys = Object.keys(rows[0] || {});
            this.validateHeaders(firstRowKeys);

            // Normalize row keys map
            const keyMap: Record<string, keyof ParsedRow> = {};
            firstRowKeys.forEach(key => {
                const cleanKey = key.toLowerCase().replace(/[*\s]/g, '');
                switch (cleanKey) {
                    case 'name': keyMap[key] = 'name'; break;
                    case 'phonenumber': keyMap[key] = 'phoneNumber'; break;
                    case 'salarygross': keyMap[key] = 'salaryGross'; break;
                    case 'idnumber': keyMap[key] = 'idNumber'; break;
                    case 'krapin': keyMap[key] = 'kraPin'; break;
                    case 'nssfnumber': keyMap[key] = 'nssfNumber'; break;
                    case 'nhifnumber': keyMap[key] = 'nhifNumber'; break;
                    case 'jobtitle': keyMap[key] = 'jobTitle'; break;
                    case 'startdate': keyMap[key] = 'startDate'; break;
                    case 'dateofbirth': keyMap[key] = 'dateOfBirth'; break;
                    // Note: 'shifnumber' could map to 'nhifNumber' if we want to handle renaming
                }
            });

            // Process each row
            for (let i = 0; i < rows.length; i++) {
                const rawRow = rows[i] as any;
                const row: ParsedRow = {};

                // Map raw keys to normalized keys
                Object.keys(rawRow).forEach(key => {
                    const normalizedKey = keyMap[key];
                    if (normalizedKey) {
                        row[normalizedKey] = rawRow[key];
                    }
                });

                const rowNum = i + 2; // Excel rows are 1-indexed, plus header row

                try {
                    // Validate required fields
                    const validationErrors = this.validateRow(row, rowNum);

                    if (validationErrors.length > 0) {
                        result.errors.push(...validationErrors);
                        result.errorCount++;
                        continue;
                    }

                    // Create worker
                    const worker = await this.workersService.create(
                        userId,
                        {
                            name: row.name!.trim(),
                            phoneNumber: this.normalizePhone(row.phoneNumber!),
                            salaryGross: parseFloat(String(row.salaryGross)),
                            idNumber: row.idNumber?.trim() || undefined,
                            kraPin: row.kraPin?.trim() || undefined,
                            nssfNumber: row.nssfNumber?.trim() || undefined,
                            nhifNumber: row.nhifNumber?.trim() || undefined,
                            jobTitle: row.jobTitle?.trim() || undefined,
                            startDate: row.startDate ? new Date(row.startDate).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
                            dateOfBirth: row.dateOfBirth ? new Date(row.dateOfBirth).toISOString().split('T')[0] : undefined,
                        },
                    );

                    result.importedEmployees.push({ name: worker.name, id: worker.id });
                    result.importedCount++;
                } catch (error: any) {
                    result.errors.push({
                        row: rowNum,
                        field: 'general',
                        message: error.message || 'Failed to create employee',
                    });
                    result.errorCount++;
                }
            }

            result.success = result.errorCount === 0;
            return result;
        } catch (error: any) {
            throw new BadRequestException(
                `Failed to process Excel file: ${error.message}`,
            );
        }
    }

    /**
     * Validate that required headers are present
     */
    private validateHeaders(headers: string[]): void {
        const normalizedHeaders = headers.map(h =>
            h.toLowerCase().replace(/[*\s]/g, '')
        );

        const requiredHeaders = ['name', 'phonenumber', 'salarygross'];
        const missingHeaders = requiredHeaders.filter(
            req => !normalizedHeaders.some(h => h === req)
        );

        if (missingHeaders.length > 0) {
            throw new BadRequestException(
                `Missing required columns: ${missingHeaders.join(', ')}. ` +
                `Required columns are marked with * in the template.`
            );
        }
    }

    /**
     * Validate a single row
     */
    private validateRow(
        row: ParsedRow,
        rowNum: number,
    ): { row: number; field: string; message: string }[] {
        const errors: { row: number; field: string; message: string }[] = [];

        // Required: name
        if (!row.name || String(row.name).trim() === '') {
            errors.push({
                row: rowNum,
                field: 'name*',
                message: 'Name is required',
            });
        }

        // Required: phoneNumber
        if (!row.phoneNumber || String(row.phoneNumber).trim() === '') {
            errors.push({
                row: rowNum,
                field: 'phoneNumber*',
                message: 'Phone number is required',
            });
        }

        // Required: salaryGross (must be a valid number)
        const salary = parseFloat(String(row.salaryGross));
        if (isNaN(salary) || salary <= 0) {
            errors.push({
                row: rowNum,
                field: 'salaryGross*',
                message: 'Salary must be a positive number',
            });
        }

        // Optional: validate date formats if provided
        if (row.startDate && !this.isValidDate(row.startDate)) {
            errors.push({
                row: rowNum,
                field: 'startDate',
                message: 'Invalid date format (use YYYY-MM-DD)',
            });
        }

        if (row.dateOfBirth && !this.isValidDate(row.dateOfBirth)) {
            errors.push({
                row: rowNum,
                field: 'dateOfBirth',
                message: 'Invalid date format (use YYYY-MM-DD)',
            });
        }

        return errors;
    }

    /**
     * Validate date string
     */
    private isValidDate(dateStr: string): boolean {
        const date = new Date(dateStr);
        return !isNaN(date.getTime());
    }

    /**
     * Normalize phone number
     */
    private normalizePhone(phone: string): string {
        let normalized = String(phone).replace(/\s/g, '');
        if (!normalized.startsWith('+') && !normalized.startsWith('0')) {
            normalized = '+' + normalized;
        }
        return normalized;
    }

    /**
     * Generate a sample Excel template with validation instructions
     */
    generateTemplate(): Buffer {
        const workbook = XLSX.utils.book_new();

        // Instructions sheet
        const instructions = [
            { 'Employee Import Instructions': 'Please follow these guidelines when filling in employee data:' },
            { 'Employee Import Instructions': '' },
            { 'Employee Import Instructions': '🔴 REQUIRED FIELDS (marked with *)' },
            { 'Employee Import Instructions': '  - name*: Full employee name (e.g., "John Doe")' },
            { 'Employee Import Instructions': '  - phoneNumber*: Phone with country code (e.g., "+254700000000")' },
            { 'Employee Import Instructions': '  - salaryGross*: Monthly gross salary as a number (e.g., "25000")' },
            { 'Employee Import Instructions': '' },
            { 'Employee Import Instructions': '🟢 OPTIONAL FIELDS' },
            { 'Employee Import Instructions': '  - idNumber: National ID number' },
            { 'Employee Import Instructions': '  - kraPin: KRA PIN (format: A001234567X)' },
            { 'Employee Import Instructions': '  - nssfNumber: NSSF registration number' },
            { 'Employee Import Instructions': '  - nhifNumber: NHIF/SHIF registration number' },
            { 'Employee Import Instructions': '  - jobTitle: Job title or position' },
            { 'Employee Import Instructions': '  - startDate: Employment start date (YYYY-MM-DD format)' },
            { 'Employee Import Instructions': '  - dateOfBirth: Date of birth (YYYY-MM-DD format)' },
            { 'Employee Import Instructions': '' },
            { 'Employee Import Instructions': '⚠️ VALIDATION RULES' },
            { 'Employee Import Instructions': '  - All required fields must be filled' },
            { 'Employee Import Instructions': '  - Salary must be a positive number' },
            { 'Employee Import Instructions': '  - Dates must be in YYYY-MM-DD format (e.g., 2024-01-15)' },
            { 'Employee Import Instructions': '  - Phone numbers should include country code' },
        ];

        const instructionsSheet = XLSX.utils.json_to_sheet(instructions);
        instructionsSheet['!cols'] = [{ wch: 80 }];
        XLSX.utils.book_append_sheet(workbook, instructionsSheet, 'Instructions');

        // Data sheet with headers
        const headers = [
            'name*',
            'phoneNumber*',
            'salaryGross*',
            'idNumber',
            'kraPin',
            'nssfNumber',
            'nhifNumber',
            'jobTitle',
            'startDate',
            'dateOfBirth',
        ];

        const sampleRows = [
            {
                'name*': 'John Doe (SAMPLE - DELETE THIS ROW)',
                'phoneNumber*': '+254700000000',
                'salaryGross*': '25000',
                'idNumber': '12345678',
                'kraPin': 'A001234567X',
                'nssfNumber': '123456789',
                'nhifNumber': '7654321',
                'jobTitle': 'House Help',
                'startDate': '2024-01-01',
                'dateOfBirth': '1990-05-15',
            },
        ];

        const dataSheet = XLSX.utils.json_to_sheet(sampleRows, { header: headers });

        // Set column widths
        dataSheet['!cols'] = [
            { wch: 35 }, // name
            { wch: 18 }, // phone
            { wch: 14 }, // salary
            { wch: 12 }, // idNumber
            { wch: 14 }, // kraPin
            { wch: 12 }, // nssf
            { wch: 12 }, // nhif
            { wch: 15 }, // jobTitle
            { wch: 12 }, // startDate
            { wch: 12 }, // dateOfBirth
        ];

        XLSX.utils.book_append_sheet(workbook, dataSheet, 'Employees');

        return XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
    }
}
