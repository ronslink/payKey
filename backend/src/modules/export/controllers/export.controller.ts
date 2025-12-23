import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  Response,
  StreamableFile,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Response as ExpressResponse } from 'express';
import { ExportService } from '../services/export.service';
import { CreateExportDto, ExportResponseDto } from '../dto/export.dto';
import { Export } from '../entities/export.entity';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';

@Controller('export')
@UseGuards(JwtAuthGuard)
export class ExportController {
  constructor(private readonly exportService: ExportService) {}

  @Post()
  async createExport(
    @Request() req: any,
    @Body() dto: CreateExportDto,
  ): Promise<ExportResponseDto> {
    try {
      const exportRecord = await this.exportService.createExport(
        req.user.userId,
        dto.exportType,
        new Date(dto.startDate),
        new Date(dto.endDate),
      );

      return {
        id: exportRecord.id,
        fileName: exportRecord.fileName,
        downloadUrl: `/export/download/${exportRecord.id}`,
        recordCount: exportRecord.recordCount,
        createdAt: exportRecord.createdAt.toISOString(),
      };
    } catch (error) {
      console.error('Export Error:', error);
      throw new HttpException(
        `Export failed: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('history')
  async getExportHistory(@Request() req: any): Promise<Export[]> {
    return this.exportService.getExportHistory(req.user.userId);
  }

  @Get('download/:id')
  async downloadExport(
    @Request() req: any,
    @Param('id') id: string,
    @Response({ passthrough: true }) res: ExpressResponse,
  ): Promise<StreamableFile> {
    const fileBuffer = await this.exportService.getExportFile(
      id,
      req.user.userId,
    );

    const exportRecord = await this.exportService['exportRepository'].findOne({
      where: { id, userId: req.user.userId },
    });

    if (!exportRecord) {
      throw new Error('Export record not found');
    }

    res.set({
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${exportRecord.fileName}"`,
    });

    return new StreamableFile(fileBuffer);
  }
}
