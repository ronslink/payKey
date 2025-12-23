import {
  Controller,
  Post,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Request,
  BadRequestException,
  Res,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { SubscriptionGuard } from '../../subscriptions/subscription.guard';
import { WorkersService } from '../workers.service';
import type { AuthenticatedRequest } from '../../../common/interfaces/user.interface';
import * as ExcelJS from 'exceljs';
import { UsersService } from '../../users/users.service';
import { SUBSCRIPTION_PLANS } from '../../subscriptions/subscription-plans.config';

interface ImportResult {
  success: number;
  failed: number;
  errors: Array<{ row: number; name: string; error: string }>;
}

@Controller('workers')
@UseGuards(JwtAuthGuard)
export class WorkersImportController {
  constructor(
    private readonly workersService: WorkersService,
    private readonly usersService: UsersService,
  ) { }

  @Get('template')
  @UseGuards(SubscriptionGuard)
  async getTemplate(@Res() res: Response) {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Workers Import Template');

    // Define Columns with Keys matching DTO
    worksheet.columns = [
      { header: 'Full Name (Required)', key: 'name', width: 25 },
      { header: 'Phone Number (Required)', key: 'phoneNumber', width: 20 },
      { header: 'Gross Salary (KES) (Required)', key: 'salaryGross', width: 20 },
      { header: 'Start Date (YYYY-MM-DD)', key: 'startDate', width: 20 },
      { header: 'Employment Type', key: 'employmentType', width: 20 },
      { header: 'Job Title', key: 'jobTitle', width: 20 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'ID Number', key: 'idNumber', width: 15 },
      { header: 'KRA PIN', key: 'kraPin', width: 15 },
      { header: 'NSSF Number', key: 'nssfNumber', width: 15 },
      { header: 'NHIF Number', key: 'nhifNumber', width: 15 },
      { header: 'Payment Method', key: 'paymentMethod', width: 20 },
      { header: 'Payment Frequency', key: 'paymentFrequency', width: 20 },
      { header: 'M-Pesa Number', key: 'mpesaNumber', width: 20 },
      { header: 'Bank Name', key: 'bankName', width: 20 },
      { header: 'Bank Account', key: 'bankAccount', width: 20 },
      { header: 'Housing Allowance', key: 'housingAllowance', width: 18 },
      { header: 'Transport Allowance', key: 'transportAllowance', width: 18 },
      { header: 'Date of Birth (YYYY-MM-DD)', key: 'dateOfBirth', width: 20 },
    ];

    // Style Header
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' },
    };

    // Add Data Validations
    // Employment Type
    worksheet.getColumn('employmentType').eachCell((cell, rowNumber) => {
      if (rowNumber > 1) {
        cell.dataValidation = {
          type: 'list',
          allowBlank: true,
          formulae: ['"FIXED,HOURLY"'],
          showErrorMessage: true,
          errorTitle: 'Invalid Selection',
          error: 'Please select a valid employment type from the list',
        };
      }
    });

    // Payment Method
    worksheet.getColumn('paymentMethod').eachCell((cell, rowNumber) => {
      if (rowNumber > 1) {
        cell.dataValidation = {
          type: 'list',
          allowBlank: true,
          formulae: ['"MPESA,BANK,CASH"'],
        };
      }
    });

    // Payment Frequency
    worksheet.getColumn('paymentFrequency').eachCell((cell, rowNumber) => {
      if (rowNumber > 1) {
        cell.dataValidation = {
          type: 'list',
          allowBlank: true,
          formulae: ['"MONTHLY,WEEKLY"'],
        };
      }
    });

    // Add Example Row
    worksheet.addRow({
      name: 'John Doe',
      phoneNumber: '+254712345678',
      salaryGross: 50000,
      startDate: new Date().toISOString().split('T')[0],
      employmentType: 'FIXED',
      jobTitle: 'Driver',
      paymentMethod: 'MPESA',
      paymentFrequency: 'MONTHLY',
    });

    // Add validations to example row and subsequent rows (ExcelJS limitation: best to apply to column but explicit ranges work better in some viewers. 
    // The loop above applies to existing cells. We need to apply to a large range for user input.)

    // Applying validation to rows 2-1000 for convenience
    for (let r = 2; r <= 1000; r++) {
      worksheet.getCell(`E${r}`).dataValidation = { type: 'list', allowBlank: true, formulae: ['"FIXED,HOURLY"'] };
      worksheet.getCell(`L${r}`).dataValidation = { type: 'list', allowBlank: true, formulae: ['"MPESA,BANK,CASH"'] };
      worksheet.getCell(`M${r}`).dataValidation = { type: 'list', allowBlank: true, formulae: ['"MONTHLY,WEEKLY"'] };
    }


    res.header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.header('Content-Disposition', 'attachment; filename=workers_template.xlsx');

    const buffer = await workbook.xlsx.writeBuffer();
    res.send(buffer);
  }

  @Post('import')
  @UseGuards(SubscriptionGuard)
  @UseInterceptors(FileInterceptor('file'))
  async importFromExcel(
    @Request() req: AuthenticatedRequest,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<ImportResult> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    const validTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
    ];
    if (!validTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Please upload an Excel file (.xlsx)',
      );
    }

    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(file.buffer as any);

    const worksheet = workbook.worksheets[0];
    if (!worksheet) {
      throw new BadRequestException('Excel file has no worksheets');
    }

    const result: ImportResult = { success: 0, failed: 0, errors: [] };

    // 1. Analyze Header and Validate Columns
    const columnMap: Record<string, string> = {};
    const headerRow = worksheet.getRow(1);
    headerRow.eachCell((cell, colNumber) => {
      const rawValue = cell.value;
      const header = typeof rawValue === 'string' ? rawValue.toLowerCase().trim() : '';
      columnMap[header] = colNumber.toString();
    });

    // Flexible column matching
    const findCol = (keys: string[]) => {
      for (const k of keys) {
        if (columnMap[k.toLowerCase()]) return columnMap[k.toLowerCase()];
        // check partial match if strictly needed, but keys usually sufficient
        // Try clean header too (remove parens)
        for (const h in columnMap) {
          if (h.includes(k.toLowerCase())) return columnMap[h];
        }
      }
      return null;
    };

    const getVal = (row: ExcelJS.Row, keys: string[]): string => {
      const col = findCol(keys);
      if (!col) return '';
      const cell = row.getCell(parseInt(col));
      const val = cell.value;
      if (val && typeof val === 'object' && 'text' in val) return (val as any).text; // Rich text
      return val != null ? String(val).trim() : '';
    };

    // Minimal required check
    if (!findCol(['name']) || !findCol(['phone']) || !findCol(['salary'])) {
      // Only failing if absolutely critical fields are missing from header
      // However, user might have different header names. 
      // We'll rely on the row processing to catch missing data.
    }

    // 2. Count Valid Rows (Logic from previous step preserved)
    let validRowsCount = 0;
    for (let rowNum = 2; rowNum <= worksheet.rowCount; rowNum++) {
      const row = worksheet.getRow(rowNum);
      const name = getVal(row, ['name', 'fullname', 'worker name']);
      if (name) validRowsCount++;
    }

    if (validRowsCount === 0) throw new BadRequestException('No valid worker data found.');

    // 3. Subscription Check (Logic preserved)
    const user = await this.usersService.findOneById(req.user.userId);
    if (!user) throw new BadRequestException('User not found');

    // ... (Limit check logic from previous step, abbreviated for brevity in replacement but assumed present if I use replace block correctly. 
    // Wait, I am replacing the WHOLE method, so I must re-include it fully.)

    const trialEndDate = new Date(user.createdAt);
    trialEndDate.setDate(trialEndDate.getDate() + 14);
    const isInTrial = new Date() <= trialEndDate;

    if (!isInTrial) {
      const currentCount = await this.workersService.getWorkerCount(req.user.userId);
      const plan = SUBSCRIPTION_PLANS.find(p => p.tier === user.tier);
      const limit = plan?.workerLimit || 3;

      if (currentCount + validRowsCount > limit) {
        throw new BadRequestException(
          `Importing ${validRowsCount} workers would exceed your plan limit of ${limit}. You have ${currentCount}. Upgrade required.`
        );
      }
    }

    // 4. Process Rows
    for (let rowNum = 2; rowNum <= worksheet.rowCount; rowNum++) {
      const row = worksheet.getRow(rowNum);

      const name = getVal(row, ['name', 'full name']);
      if (!name) continue;

      const phoneNumber = getVal(row, ['phone', 'mobile']);
      const salaryStr = getVal(row, ['salary', 'gross', 'amount']);

      if (!phoneNumber) {
        result.failed++;
        result.errors.push({ row: rowNum, name, error: 'Missing phone' });
        continue;
      }

      const salaryGross = parseFloat(salaryStr.replace(/[^0-9.]/g, ''));
      if (isNaN(salaryGross) || salaryGross < 0) {
        result.failed++;
        result.errors.push({ row: rowNum, name, error: 'Invalid salary' });
        continue;
      }

      // Optional Fields
      const email = getVal(row, ['email']);
      const idNumber = getVal(row, ['id number', 'national id']);
      const kraPin = getVal(row, ['kra', 'pin']);
      const nssf = getVal(row, ['nssf']);
      const nhif = getVal(row, ['nhif']);
      const jobTitle = getVal(row, ['job', 'title']);
      const empType = getVal(row, ['employment', 'type']).toUpperCase();
      const startDate = getVal(row, ['start date']);
      const payMethod = getVal(row, ['payment method', 'method']).toUpperCase();
      const payFreq = getVal(row, ['payment frequency', 'frequency']).toUpperCase();

      const mpesa = getVal(row, ['mpesa']);
      const bank = getVal(row, ['bank name']);
      const account = getVal(row, ['bank account', 'account no']);

      const housing = parseFloat(getVal(row, ['housing']).replace(/[^0-9.]/g, '') || '0');
      const transport = parseFloat(getVal(row, ['transport']).replace(/[^0-9.]/g, '') || '0');
      const dob = getVal(row, ['date of birth', 'dob']);

      try {
        await this.workersService.create(req.user.userId, {
          name,
          phoneNumber,
          salaryGross,
          startDate: startDate || new Date().toISOString().split('T')[0],
          email: email || undefined,
          idNumber: idNumber || undefined,
          kraPin: kraPin || undefined,
          nssfNumber: nssf || undefined,
          nhifNumber: nhif || undefined,
          jobTitle: jobTitle || undefined,
          employmentType: (['FIXED', 'HOURLY'].includes(empType) ? empType : 'FIXED') as any,
          paymentMethod: (['MPESA', 'BANK', 'CASH'].includes(payMethod) ? payMethod : 'MPESA') as any,
          paymentFrequency: (['MONTHLY', 'WEEKLY'].includes(payFreq) ? payFreq : 'MONTHLY') as any,
          mpesaNumber: mpesa || undefined,
          bankName: bank || undefined,
          bankAccount: account || undefined,
          housingAllowance: housing,
          transportAllowance: transport,
          dateOfBirth: dob || undefined,
        });
        result.success++;
      } catch (err: any) {
        result.failed++;
        result.errors.push({ row: rowNum, name, error: err.message });
      }
    }

    return result;
  }

  private getCellValue(row: ExcelJS.Row, headers: string[], columnMap: Record<string, string>): string {
    for (const header of headers) {
      const colNum = columnMap[header];
      if (colNum) {
        const cell = row.getCell(parseInt(colNum));
        const rawValue = cell.value;
        // Handle Rich Text or specific cell types if needed, simpler for now
        if (rawValue && typeof rawValue === 'object' && 'text' in rawValue) {
          return (rawValue as any).text;
        }
        return typeof rawValue === 'string' ? rawValue.trim() : String(rawValue ?? '').trim();
      }
    }
    return '';
  }
}
