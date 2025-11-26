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
exports.TaxPaymentsController = void 0;
const common_1 = require("@nestjs/common");
const tax_payments_service_1 = require("../services/tax-payments.service");
const tax_payment_dto_1 = require("../dto/tax-payment.dto");
const tax_payment_entity_1 = require("../entities/tax-payment.entity");
const jwt_auth_guard_1 = require("../../auth/jwt-auth.guard");
let TaxPaymentsController = class TaxPaymentsController {
    taxPaymentsService;
    constructor(taxPaymentsService) {
        this.taxPaymentsService = taxPaymentsService;
    }
    async getMonthlySummary(req, year, month) {
        return this.taxPaymentsService.generateMonthlySummary(req.user.userId, parseInt(year), parseInt(month));
    }
    async recordPayment(req, dto) {
        return this.taxPaymentsService.recordPayment(req.user.userId, dto);
    }
    async getPaymentHistory(req) {
        return this.taxPaymentsService.getPaymentHistory(req.user.userId);
    }
    async getPendingPayments(req) {
        return this.taxPaymentsService.getPendingPayments(req.user.userId);
    }
    async updatePaymentStatus(req, id, status) {
        return this.taxPaymentsService.updatePaymentStatus(id, req.user.userId, status);
    }
    async getPaymentInstructions() {
        return {
            mpesa: {
                paybill: '222222',
                accountNumber: 'Your iTax Payment Registration Number',
                steps: [
                    'Go to M-Pesa menu',
                    'Select Lipa na M-Pesa',
                    'Select Pay Bill',
                    'Enter Business Number: 222222',
                    'Enter Account Number: Your iTax Payment Registration Number',
                    'Enter Amount',
                    'Enter M-Pesa PIN',
                    'Confirm payment',
                ],
            },
            bank: {
                method: 'Visit any KRA-appointed bank',
                requirement: 'Payment slip from iTax portal',
                steps: [
                    'Log in to iTax portal (itax.kra.go.ke)',
                    'Navigate to Payments section',
                    'Select tax type (PAYE, NSSF, SHIF, Housing Levy)',
                    'Generate payment slip',
                    'Present slip at any KRA-appointed bank',
                ],
            },
            deadline: '9th day of the following month',
            penalties: 'Late payment attracts penalties and interest',
        };
    }
};
exports.TaxPaymentsController = TaxPaymentsController;
__decorate([
    (0, common_1.Get)('summary/:year/:month'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('year')),
    __param(2, (0, common_1.Param)('month')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "getMonthlySummary", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, tax_payment_dto_1.CreateTaxPaymentDto]),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "recordPayment", null);
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "getPaymentHistory", null);
__decorate([
    (0, common_1.Get)('pending'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "getPendingPayments", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)('status')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "updatePaymentStatus", null);
__decorate([
    (0, common_1.Get)('instructions'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TaxPaymentsController.prototype, "getPaymentInstructions", null);
exports.TaxPaymentsController = TaxPaymentsController = __decorate([
    (0, common_1.Controller)('tax-payments'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [tax_payments_service_1.TaxPaymentsService])
], TaxPaymentsController);
//# sourceMappingURL=tax-payments.controller.js.map