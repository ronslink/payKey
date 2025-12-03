import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { AccountingExportService } from './accounting-export.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccountCategory } from './entities/account-mapping.entity';

class SaveMappingsDto {
  mappings: Array<{
    category: AccountCategory;
    accountCode: string;
    accountName: string;
  }>;
}

@Controller('accounting')
@UseGuards(JwtAuthGuard)
export class AccountingController {
  constructor(
    private readonly accountingExportService: AccountingExportService,
  ) { }

  @Post('export/:payPeriodId')
  async exportPayroll(
    @Request() req: any,
    @Param('payPeriodId') payPeriodId: string,
    @Body('format') format: string = 'CSV',
  ) {
    try {
      const userId = req.user.userId;

      if (format === 'CSV') {
        const csv = await this.accountingExportService.exportToCSV(
          payPeriodId,
          userId,
        );
        return {
          format: 'CSV',
          data: csv,
          filename: `payroll_export_${payPeriodId}.csv`,
        };
      }

      throw new HttpException(
        'Unsupported export format',
        HttpStatus.BAD_REQUEST,
      );
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to export payroll',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }


  @Get('history')
  async getExportHistory(@Request() req: any) {
    const userId = req.user.userId;
    const history = await this.accountingExportService.getExportHistory(userId);
    return { history };
  }

  @Get('formats')
  getAvailableFormats() {
    return {
      formats: [
        {
          id: 'CSV',
          name: 'CSV (Comma Separated Values)',
          description: 'Compatible with Excel and most accounting software',
        },
        {
          id: 'EXCEL',
          name: 'Excel Spreadsheet',
          description: 'Microsoft Excel format (Coming soon)',
          disabled: true,
        },
        {
          id: 'QUICKBOOKS',
          name: 'QuickBooks Online',
          description: 'Direct integration with QuickBooks (Coming soon)',
          disabled: true,
        },
        {
          id: 'XERO',
          name: 'Xero',
          description: 'Direct integration with Xero (Coming soon)',
          disabled: true,
        },
        {
          id: 'SAGE',
          name: 'Sage',
          description: 'Sage-compatible CSV format (Coming soon)',
          disabled: true,
        },
      ],
    };
  }

  @Post('mappings')
  async saveAccountMappings(@Request() req: any, @Body() dto: SaveMappingsDto) {
    const userId = req.user.userId;
    const mappings = await this.accountingExportService.saveAccountMappings(
      userId,
      dto.mappings,
    );
    return { success: true, mappings };
  }

  @Get('mappings')
  async getAccountMappings(@Request() req: any) {
    const userId = req.user.userId;
    const mappings =
      await this.accountingExportService.getAccountMappings(userId);
    return { mappings };
  }

  @Get('mappings/defaults')
  getDefaultMappings() {
    const defaults = this.accountingExportService.getDefaultAccountMappings();
    return { defaults };
  }

  @Post('journal-entries/:payPeriodId')
  async generateJournalEntries(
    @Request() req: any,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    try {
      const userId = req.user.userId;
      const journalEntries =
        await this.accountingExportService.generateJournalEntries(
          payPeriodId,
          userId,
        );
      return journalEntries;
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to generate journal entries',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
