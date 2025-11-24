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
exports.PayrollRecord = exports.PayrollStatus = void 0;
const typeorm_1 = require("typeorm");
const worker_entity_1 = require("../../workers/entities/worker.entity");
var PayrollStatus;
(function (PayrollStatus) {
    PayrollStatus["DRAFT"] = "draft";
    PayrollStatus["FINALIZED"] = "finalized";
    PayrollStatus["PAID"] = "paid";
})(PayrollStatus || (exports.PayrollStatus = PayrollStatus = {}));
let PayrollRecord = class PayrollRecord {
    id;
    userId;
    workerId;
    payPeriodId;
    worker;
    periodStart;
    periodEnd;
    grossSalary;
    bonuses;
    otherEarnings;
    otherDeductions;
    netSalary;
    taxAmount;
    status;
    paymentStatus;
    paymentMethod;
    paymentDate;
    finalizedAt;
    taxBreakdown;
    deductions;
    createdAt;
    updatedAt;
};
exports.PayrollRecord = PayrollRecord;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], PayrollRecord.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PayrollRecord.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], PayrollRecord.prototype, "workerId", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], PayrollRecord.prototype, "payPeriodId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => worker_entity_1.Worker, { eager: true }),
    (0, typeorm_1.JoinColumn)({ name: 'workerId' }),
    __metadata("design:type", worker_entity_1.Worker)
], PayrollRecord.prototype, "worker", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "periodStart", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "periodEnd", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "grossSalary", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "bonuses", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "otherEarnings", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "otherDeductions", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "netSalary", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], PayrollRecord.prototype, "taxAmount", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'simple-enum',
        enum: PayrollStatus,
        default: PayrollStatus.DRAFT
    }),
    __metadata("design:type", String)
], PayrollRecord.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 'pending' }),
    __metadata("design:type", String)
], PayrollRecord.prototype, "paymentStatus", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: 'mpesa' }),
    __metadata("design:type", String)
], PayrollRecord.prototype, "paymentMethod", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "paymentDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "finalizedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], PayrollRecord.prototype, "taxBreakdown", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'json', nullable: true }),
    __metadata("design:type", Object)
], PayrollRecord.prototype, "deductions", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], PayrollRecord.prototype, "updatedAt", void 0);
exports.PayrollRecord = PayrollRecord = __decorate([
    (0, typeorm_1.Entity)('payroll_records')
], PayrollRecord);
//# sourceMappingURL=payroll-record.entity.js.map