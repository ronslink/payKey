import {
  Controller,
  Post,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Request,
  Res,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TierGuard, RequireTiers } from '../../common/guards/tier.guard';
import { ExcelImportService } from './excel-import.service';

@Controller('excel-import')
@UseGuards(JwtAuthGuard, TierGuard)
export class ExcelImportController {
  constructor(private readonly excelImportService: ExcelImportService) { }

  /**
   * Upload and import employees from Excel file
   * Restricted to GOLD and PLATINUM users
   */
  @Post('employees')
  @RequireTiers('GOLD', 'PLATINUM')
  @UseInterceptors(FileInterceptor('file'))
  async importEmployees(
    @UploadedFile()
    file: { buffer: Buffer; mimetype: string; originalname: string },
    @Request() req: any,
  ) {
    // Debug logging
    console.log('=== Excel Import Debug ===');
    console.log('File received:', file ? 'yes' : 'no');
    if (file) {
      console.log('  - originalname:', file.originalname);
      console.log('  - mimetype:', file.mimetype);
      console.log('  - buffer size:', file.buffer?.length || 0);
    }
    console.log('User:', req.user?.userId);
    console.log('========================');

    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    // Validate file type
    const validTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
    ];

    if (
      !validTypes.includes(file.mimetype) &&
      !file.originalname.endsWith('.xlsx')
    ) {
      throw new BadRequestException('File must be an Excel file (.xlsx)');
    }

    return this.excelImportService.importEmployees(
      file.buffer,
      req.user.userId,
    );
  }

  /**
   * Download sample Excel template
   * Shows required fields marked with asterisk (*)
   */
  @Get('employees/template')
  @RequireTiers('GOLD', 'PLATINUM')
  async downloadTemplate(@Res() res: Response) {
    const buffer = this.excelImportService.generateTemplate();

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename=employee_import_template.xlsx',
    );

    res.send(buffer);
  }
}
