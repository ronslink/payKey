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
exports.PayrollRecordsController = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const payroll_record_entity_1 = require("./entities/payroll-record.entity");
let PayrollRecordsController = class PayrollRecordsController {
    payrollRepository;
    constructor(payrollRepository) {
        this.payrollRepository = payrollRepository;
    }
    async getPayrollRecords(req) {
        return this.payrollRepository.find({
            where: { userId: req.user.userId },
            relations: ['worker'],
            order: { createdAt: 'DESC' },
            take: 50,
        });
    }
    async updatePayrollStatus(req, id, body) {
        return this.payrollRepository.update({ id, userId: req.user.userId }, {
            paymentStatus: body.status,
            ...(body.paymentDate && { paymentDate: new Date(body.paymentDate) }),
        });
    }
    async deletePayrollRecord(req, id) {
        return this.payrollRepository.delete({ id, userId: req.user.userId });
    }
};
exports.PayrollRecordsController = PayrollRecordsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PayrollRecordsController.prototype, "getPayrollRecords", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], PayrollRecordsController.prototype, "updatePayrollStatus", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], PayrollRecordsController.prototype, "deletePayrollRecord", null);
exports.PayrollRecordsController = PayrollRecordsController = __decorate([
    (0, common_1.Controller)('payroll-records'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], PayrollRecordsController);
//# sourceMappingURL=payroll-records.controller.js.map