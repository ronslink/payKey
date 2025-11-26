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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PayPeriod = exports.PayPeriodStatus = exports.PayPeriodFrequency = void 0;
const typeorm_1 = require("typeorm");
const tax_submission_entity_1 = require("../../taxes/entities/tax-submission.entity");
var PayPeriodFrequency;
(function (PayPeriodFrequency) {
    PayPeriodFrequency["WEEKLY"] = "WEEKLY";
    PayPeriodFrequency["BIWEEKLY"] = "BIWEEKLY";
    PayPeriodFrequency["MONTHLY"] = "MONTHLY";
    PayPeriodFrequency["QUARTERLY"] = "QUARTERLY";
})(PayPeriodFrequency || (exports.PayPeriodFrequency = PayPeriodFrequency = {}));
var PayPeriodStatus;
(function (PayPeriodStatus) {
    PayPeriodStatus["DRAFT"] = "DRAFT";
    PayPeriodStatus["ACTIVE"] = "ACTIVE";
    PayPeriodStatus["PROCESSING"] = "PROCESSING";
    PayPeriodStatus["COMPLETED"] = "COMPLETED";
    PayPeriodStatus["CLOSED"] = "CLOSED";
})(PayPeriodStatus || (exports.PayPeriodStatus = PayPeriodStatus = {}));
let PayPeriod = class PayPeriod {
    id;
    name;
    startDate;
    endDate;
    userId;
    payDate;
    frequency;
    status;
    totalGrossAmount;
    totalNetAmount;
    totalTaxAmount;
    totalWorkers;
    processedWorkers;
    notes;
    createdBy;
    approvedBy;
    approvedAt;
    processedAt;
    createdAt;
    updatedAt;
    taxSubmissions;
    transactions;
};
exports.PayPeriod = PayPeriod;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PayPeriod.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PayPeriod.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], PayPeriod.prototype, "startDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], PayPeriod.prototype, "endDate", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PayPeriod.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true }),
    __metadata("design:type", String)
], PayPeriod.prototype, "payDate", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: PayPeriodFrequency,
        default: PayPeriodFrequency.MONTHLY,
    }),
    __metadata("design:type", String)
], PayPeriod.prototype, "frequency", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: PayPeriodStatus,
        default: PayPeriodStatus.DRAFT,
    }),
    __metadata("design:type", String)
], PayPeriod.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 15, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayPeriod.prototype, "totalGrossAmount", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 15, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayPeriod.prototype, "totalNetAmount", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 15, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayPeriod.prototype, "totalTaxAmount", void 0);
__decorate([
    (0, typeorm_1.Column)('int', { default: 0 }),
    __metadata("design:type", Number)
], PayPeriod.prototype, "totalWorkers", void 0);
__decorate([
    (0, typeorm_1.Column)('int', { default: 0 }),
    __metadata("design:type", Number)
], PayPeriod.prototype, "processedWorkers", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], PayPeriod.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PayPeriod.prototype, "createdBy", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PayPeriod.prototype, "approvedBy", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], PayPeriod.prototype, "approvedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], PayPeriod.prototype, "processedAt", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], PayPeriod.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], PayPeriod.prototype, "updatedAt", void 0);
__decorate([
    (0, typeorm_1.OneToMany)(() => tax_submission_entity_1.TaxSubmission, (taxSubmission) => taxSubmission.payPeriod),
    __metadata("design:type", Array)
], PayPeriod.prototype, "taxSubmissions", void 0);
exports.PayPeriod = PayPeriod = __decorate([
    (0, typeorm_1.Entity)('pay_periods')
], PayPeriod);
//# sourceMappingURL=pay-period.entity.js.map