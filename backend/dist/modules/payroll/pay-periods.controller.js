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
exports.PayPeriodsController = void 0;
const common_1 = require("@nestjs/common");
const pay_periods_service_1 = require("./pay-periods.service");
const create_pay_period_dto_1 = require("./dto/create-pay-period.dto");
const update_pay_period_dto_1 = require("./dto/update-pay-period.dto");
const pay_period_entity_1 = require("./entities/pay-period.entity");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let PayPeriodsController = class PayPeriodsController {
    payPeriodsService;
    constructor(payPeriodsService) {
        this.payPeriodsService = payPeriodsService;
    }
    create(createPayPeriodDto) {
        return this.payPeriodsService.create(createPayPeriodDto);
    }
    findAll(page = '1', limit = '10', status, frequency) {
        const pageNum = parseInt(page, 10) || 1;
        const limitNum = parseInt(limit, 10) || 10;
        return this.payPeriodsService.findAll(pageNum, limitNum, status, frequency);
    }
    findOne(id) {
        return this.payPeriodsService.findOne(id);
    }
    update(id, updatePayPeriodDto) {
        return this.payPeriodsService.update(id, updatePayPeriodDto);
    }
    remove(id) {
        return this.payPeriodsService.remove(id);
    }
    activate(id) {
        return this.payPeriodsService.activate(id);
    }
    process(id) {
        return this.payPeriodsService.process(id);
    }
    complete(id) {
        return this.payPeriodsService.complete(id);
    }
    close(id) {
        return this.payPeriodsService.close(id);
    }
    getStatistics(id) {
        return this.payPeriodsService.getPayPeriodStatistics(id);
    }
    generatePayPeriods(body) {
        return this.payPeriodsService.generatePayPeriods(body.userId, body.frequency, new Date(body.startDate), new Date(body.endDate));
    }
};
exports.PayPeriodsController = PayPeriodsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_pay_period_dto_1.CreatePayPeriodDto]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('status')),
    __param(3, (0, common_1.Query)('frequency')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "findOne", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_pay_period_dto_1.UpdatePayPeriodDto]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "remove", null);
__decorate([
    (0, common_1.Post)(':id/activate'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "activate", null);
__decorate([
    (0, common_1.Post)(':id/process'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "process", null);
__decorate([
    (0, common_1.Post)(':id/complete'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "complete", null);
__decorate([
    (0, common_1.Post)(':id/close'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "close", null);
__decorate([
    (0, common_1.Get)(':id/statistics'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "getStatistics", null);
__decorate([
    (0, common_1.Post)('generate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], PayPeriodsController.prototype, "generatePayPeriods", null);
exports.PayPeriodsController = PayPeriodsController = __decorate([
    (0, common_1.Controller)('pay-periods'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [pay_periods_service_1.PayPeriodsService])
], PayPeriodsController);
//# sourceMappingURL=pay-periods.controller.js.map