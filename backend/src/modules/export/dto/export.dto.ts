import { IsEnum, IsDateString } from 'class-validator';
import { ExportType } from '../entities/export.entity';

export class CreateExportDto {
  @IsEnum(ExportType)
  exportType: ExportType;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;
}

export class ExportResponseDto {
  id: string;
  fileName: string;
  downloadUrl: string;
  recordCount: number;
  createdAt: string;
}
