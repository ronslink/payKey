import { StreamableFile } from '@nestjs/common';
import type { Response as ExpressResponse } from 'express';
import { ExportService } from '../services/export.service';
import { CreateExportDto, ExportResponseDto } from '../dto/export.dto';
import { Export } from '../entities/export.entity';
export declare class ExportController {
    private readonly exportService;
    constructor(exportService: ExportService);
    createExport(req: any, dto: CreateExportDto): Promise<ExportResponseDto>;
    getExportHistory(req: any): Promise<Export[]>;
    downloadExport(req: any, id: string, res: ExpressResponse): Promise<StreamableFile>;
}
