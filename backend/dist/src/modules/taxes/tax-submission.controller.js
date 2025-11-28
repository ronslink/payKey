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
exports.TaxSubmissionController = void 0;
const common_1 = require("@nestjs/common");
const taxes_service_1 = require("./taxes.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let TaxSubmissionController = class TaxSubmissionController {
    taxesService;
    constructor(taxesService) {
        this.taxesService = taxesService;
    }
    async getSubmissions(req) {
        return this.taxesService.getSubmissions(req.user.userId);
    }
    async markAsFiled(req, id) {
        return this.taxesService.markAsFiled(id, req.user.userId);
    }
    async generateSubmission(req, body) {
        return this.taxesService.generateTaxSubmission(body.payPeriodId, req.user.userId);
    }
};
exports.TaxSubmissionController = TaxSubmissionController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TaxSubmissionController.prototype, "getSubmissions", null);
__decorate([
    (0, common_1.Patch)(':id/file'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], TaxSubmissionController.prototype, "markAsFiled", null);
__decorate([
    (0, common_1.Post)('generate'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], TaxSubmissionController.prototype, "generateSubmission", null);
exports.TaxSubmissionController = TaxSubmissionController = __decorate([
    (0, common_1.Controller)('taxes/submissions'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [taxes_service_1.TaxesService])
], TaxSubmissionController);
//# sourceMappingURL=tax-submission.controller.js.map