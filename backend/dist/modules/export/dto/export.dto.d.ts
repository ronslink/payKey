import { ExportType } from '../entities/export.entity';
export declare class CreateExportDto {
    exportType: ExportType;
    startDate: string;
    endDate: string;
}
export declare class ExportResponseDto {
    id: string;
    fileName: string;
    downloadUrl: string;
    recordCount: number;
    createdAt: string;
}
