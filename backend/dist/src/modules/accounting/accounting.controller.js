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
exports.AccountingController = void 0;
const common_1 = require("@nestjs/common");
const accounting_export_service_1 = require("./accounting-export.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
class SaveMappingsDto {
    mappings;
}
let AccountingController = class AccountingController {
    accountingExportService;
    constructor(accountingExportService) {
        this.accountingExportService = accountingExportService;
    }
    async exportPayroll(req, payPeriodId, format = 'CSV') {
        try {
            const userId = req.user.userId;
            if (format === 'CSV') {
                const csv = await this.accountingExportService.exportToCSV(payPeriodId, userId);
                return {
                    format: 'CSV',
                    data: csv,
                    filename: `payroll_export_${payPeriodId}.csv`,
                };
            }
            throw new common_1.HttpException('Unsupported export format', common_1.HttpStatus.BAD_REQUEST);
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to export payroll', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    getAvailableFormats() {
        return {
            formats: [
                { id: 'CSV', name: 'CSV (Comma Separated Values)', description: 'Compatible with Excel and most accounting software' },
                { id: 'EXCEL', name: 'Excel Spreadsheet', description: 'Microsoft Excel format (Coming soon)', disabled: true },
                { id: 'QUICKBOOKS', name: 'QuickBooks Online', description: 'Direct integration with QuickBooks (Coming soon)', disabled: true },
                { id: 'XERO', name: 'Xero', description: 'Direct integration with Xero (Coming soon)', disabled: true },
                { id: 'SAGE', name: 'Sage', description: 'Sage-compatible CSV format (Coming soon)', disabled: true },
            ],
        };
    }
    async saveAccountMappings(req, dto) {
        const userId = req.user.userId;
        const mappings = await this.accountingExportService.saveAccountMappings(userId, dto.mappings);
        return { success: true, mappings };
    }
    async getAccountMappings(req) {
        const userId = req.user.userId;
        const mappings = await this.accountingExportService.getAccountMappings(userId);
        return { mappings };
    }
    getDefaultMappings() {
        const defaults = this.accountingExportService.getDefaultAccountMappings();
        return { defaults };
    }
    async generateJournalEntries(req, payPeriodId) {
        try {
            const userId = req.user.userId;
            const journalEntries = await this.accountingExportService.generateJournalEntries(payPeriodId, userId);
            return journalEntries;
        }
        catch (error) {
            throw new common_1.HttpException(error.message || 'Failed to generate journal entries', common_1.HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
};
exports.AccountingController = AccountingController;
__decorate([
    (0, common_1.Post)('export/:payPeriodId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('payPeriodId')),
    __param(2, (0, common_1.Body)('format')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], AccountingController.prototype, "exportPayroll", null);
__decorate([
    (0, common_1.Get)('formats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AccountingController.prototype, "getAvailableFormats", null);
__decorate([
    (0, common_1.Post)('mappings'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, SaveMappingsDto]),
    __metadata("design:returntype", Promise)
], AccountingController.prototype, "saveAccountMappings", null);
__decorate([
    (0, common_1.Get)('mappings'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AccountingController.prototype, "getAccountMappings", null);
__decorate([
    (0, common_1.Get)('mappings/defaults'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AccountingController.prototype, "getDefaultMappings", null);
__decorate([
    (0, common_1.Post)('journal-entries/:payPeriodId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('payPeriodId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], AccountingController.prototype, "generateJournalEntries", null);
exports.AccountingController = AccountingController = __decorate([
    (0, common_1.Controller)('accounting'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [accounting_export_service_1.AccountingExportService])
], AccountingController);
//# sourceMappingURL=accounting.controller.js.map