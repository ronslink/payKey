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
exports.TaxesController = void 0;
const common_1 = require("@nestjs/common");
const taxes_service_1 = require("./taxes.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const user_entity_1 = require("../users/entities/user.entity");
class CalculateTaxDto {
    grossSalary;
}
let TaxesController = class TaxesController {
    taxesService;
    constructor(taxesService) {
        this.taxesService = taxesService;
    }
    calculateTaxes(dto) {
        return this.taxesService.calculateTaxes(dto.grossSalary);
    }
    async createTaxTable(taxTableData) {
        return this.taxesService.createTaxTable(taxTableData);
    }
    getComplianceStatus(req) {
        return this.taxesService.getComplianceStatus(req.user.userId);
    }
    getUpcomingDeadlines() {
        return this.taxesService.getUpcomingDeadlines();
    }
    async getTaxTables() {
        return this.taxesService.getTaxTables();
    }
    getSubmissions(req) {
        return this.taxesService.getSubmissions(req.user.userId);
    }
    markAsFiled(req, id) {
        return this.taxesService.markAsFiled(id, req.user.userId);
    }
    async getCurrentTaxTable() {
        return this.taxesService.getTaxTable(new Date());
    }
};
exports.TaxesController = TaxesController;
__decorate([
    (0, common_1.Post)('calculate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CalculateTaxDto]),
    __metadata("design:returntype", void 0)
], TaxesController.prototype, "calculateTaxes", null);
__decorate([
    (0, common_1.Post)('tables'),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.ADMIN),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TaxesController.prototype, "createTaxTable", null);
__decorate([
    (0, common_1.Get)('compliance'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], TaxesController.prototype, "getComplianceStatus", null);
__decorate([
    (0, common_1.Get)('deadlines'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], TaxesController.prototype, "getUpcomingDeadlines", null);
__decorate([
    (0, common_1.Get)('tables'),
    (0, roles_guard_1.Roles)(user_entity_1.UserRole.ADMIN),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TaxesController.prototype, "getTaxTables", null);
__decorate([
    (0, common_1.Get)('submissions'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], TaxesController.prototype, "getSubmissions", null);
__decorate([
    (0, common_1.Patch)('submissions/:id/file'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], TaxesController.prototype, "markAsFiled", null);
__decorate([
    (0, common_1.Get)('current'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TaxesController.prototype, "getCurrentTaxTable", null);
exports.TaxesController = TaxesController = __decorate([
    (0, common_1.Controller)('taxes'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [taxes_service_1.TaxesService])
], TaxesController);
//# sourceMappingURL=taxes.controller.js.map