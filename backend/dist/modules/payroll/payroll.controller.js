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
exports.PayrollController = void 0;
const common_1 = require("@nestjs/common");
const payroll_service_1 = require("./payroll.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let PayrollController = class PayrollController {
    payrollService;
    constructor(payrollService) {
        this.payrollService = payrollService;
    }
    async calculatePayroll(req) {
        return this.payrollService.calculatePayrollForUser(req.user.userId);
    }
    async calculatePayrollForWorkers(req, body) {
        const fullPayroll = await this.payrollService.calculatePayrollForUser(req.user.userId);
        if (body.workerIds && body.workerIds.length > 0) {
            const filteredItems = fullPayroll.payrollItems.filter((item) => body.workerIds.includes(item.workerId));
            const totalGross = filteredItems.reduce((sum, item) => sum + item.grossSalary, 0);
            const totalDeductions = filteredItems.reduce((sum, item) => sum + item.taxBreakdown.totalDeductions, 0);
            const totalNetPay = filteredItems.reduce((sum, item) => sum + item.netPay, 0);
            return {
                payrollItems: filteredItems,
                summary: {
                    totalGross: Math.round(totalGross * 100) / 100,
                    totalDeductions: Math.round(totalDeductions * 100) / 100,
                    totalNetPay: Math.round(totalNetPay * 100) / 100,
                    workerCount: filteredItems.length,
                },
            };
        }
        return fullPayroll;
    }
    async calculateSingleWorkerPayroll(req, workerId) {
        return this.payrollService.calculateSingleWorkerPayroll(workerId, req.user.userId);
    }
    async processPayroll(req, body) {
        const payrollCalculation = await this.payrollService.calculatePayrollForUser(req.user.userId);
        const selectedPayrollItems = payrollCalculation.payrollItems.filter((item) => body.workerIds.includes(item.workerId));
        return {
            ...payrollCalculation,
            payrollItems: selectedPayrollItems,
            message: 'Payroll processing initiated',
        };
    }
    async saveDraftPayroll(req, body) {
        return this.payrollService.saveDraftPayroll(req.user.userId, body.payPeriodId, body.payrollItems);
    }
    async updateDraftPayrollItem(req, payrollRecordId, body) {
        return this.payrollService.updateDraftPayrollItem(req.user.userId, payrollRecordId, body);
    }
    async getDraftPayroll(req, payPeriodId) {
        return this.payrollService.getDraftPayroll(req.user.userId, payPeriodId);
    }
    async finalizePayroll(req, payPeriodId) {
        return this.payrollService.finalizePayroll(req.user.userId, payPeriodId);
    }
};
exports.PayrollController = PayrollController;
__decorate([
    (0, common_1.Get)('calculate'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "calculatePayroll", null);
__decorate([
    (0, common_1.Post)('calculate'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "calculatePayrollForWorkers", null);
__decorate([
    (0, common_1.Get)('calculate/:workerId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('workerId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "calculateSingleWorkerPayroll", null);
__decorate([
    (0, common_1.Post)('process'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "processPayroll", null);
__decorate([
    (0, common_1.Post)('draft'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "saveDraftPayroll", null);
__decorate([
    (0, common_1.Patch)('draft/:payrollRecordId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('payrollRecordId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "updateDraftPayrollItem", null);
__decorate([
    (0, common_1.Get)('draft/:payPeriodId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('payPeriodId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "getDraftPayroll", null);
__decorate([
    (0, common_1.Post)('finalize/:payPeriodId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('payPeriodId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], PayrollController.prototype, "finalizePayroll", null);
exports.PayrollController = PayrollController = __decorate([
    (0, common_1.Controller)('payroll'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [payroll_service_1.PayrollService])
], PayrollController);
//# sourceMappingURL=payroll.controller.js.map