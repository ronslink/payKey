"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExportController = void 0;
const common_1 = require("@nestjs/common");
const export_service_1 = require("../services/export.service");
const export_dto_1 = require("../dto/export.dto");
const jwt_auth_guard_1 = require("../../auth/jwt-auth.guard");
let ExportController = class ExportController {
    exportService;
    constructor(exportService) {
        this.exportService = exportService;
    }
    async createExport(req, dto) {
        const exportRecord = await this.exportService.createExport(req.user.userId, dto.exportType, new Date(dto.startDate), new Date(dto.endDate));
        return {
            id: exportRecord.id,
            fileName: exportRecord.fileName,
            downloadUrl: `/export/download/${exportRecord.id}`,
            recordCount: exportRecord.recordCount,
            createdAt: exportRecord.createdAt.toISOString(),
        };
    }
    async getExportHistory(req) {
        return this.exportService.getExportHistory(req.user.userId);
    }
    async downloadExport(req, id, res) {
        const fileBuffer = await this.exportService.getExportFile(id, req.user.userId);
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
        return new common_1.StreamableFile(fileBuffer);
    }
};
exports.ExportController = ExportController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, export_dto_1.CreateExportDto]),
    __metadata("design:returntype", Promise)
], ExportController.prototype, "createExport", null);
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ExportController.prototype, "getExportHistory", null);
__decorate([
    (0, common_1.Get)('download/:id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Response)({ passthrough: true })),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ExportController.prototype, "downloadExport", null);
exports.ExportController = ExportController = __decorate([
    (0, common_1.Controller)('export'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [export_service_1.ExportService])
], ExportController);
//# sourceMappingURL=export.controller.js.map