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
exports.Termination = exports.TerminationReason = void 0;
const typeorm_1 = require("typeorm");
const worker_entity_1 = require("./worker.entity");
const user_entity_1 = require("../../users/entities/user.entity");
var TerminationReason;
(function (TerminationReason) {
    TerminationReason["RESIGNATION"] = "RESIGNATION";
    TerminationReason["DISMISSAL"] = "DISMISSAL";
    TerminationReason["CONTRACT_END"] = "CONTRACT_END";
    TerminationReason["ILLNESS"] = "ILLNESS";
    TerminationReason["DEATH"] = "DEATH";
    TerminationReason["RETIREMENT"] = "RETIREMENT";
    TerminationReason["REDUNDANCY"] = "REDUNDANCY";
    TerminationReason["OTHER"] = "OTHER";
})(TerminationReason || (exports.TerminationReason = TerminationReason = {}));
let Termination = class Termination {
    id;
    worker;
    workerId;
    user;
    userId;
    reason;
    terminationDate;
    lastWorkingDate;
    noticePeriodDays;
    notes;
    proratedSalary;
    unusedLeavePayout;
    severancePay;
    totalFinalPayment;
    paymentBreakdown;
    createdAt;
};
exports.Termination = Termination;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Termination.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => worker_entity_1.Worker),
    (0, typeorm_1.JoinColumn)({ name: 'workerId' }),
    __metadata("design:type", worker_entity_1.Worker)
], Termination.prototype, "worker", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Termination.prototype, "workerId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User),
    (0, typeorm_1.JoinColumn)({ name: 'userId' }),
    __metadata("design:type", user_entity_1.User)
], Termination.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Termination.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: TerminationReason,
    }),
    __metadata("design:type", String)
], Termination.prototype, "reason", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], Termination.prototype, "terminationDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true }),
    __metadata("design:type", Date)
], Termination.prototype, "lastWorkingDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0 }),
    __metadata("design:type", Number)
], Termination.prototype, "noticePeriodDays", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Termination.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], Termination.prototype, "proratedSalary", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], Termination.prototype, "unusedLeavePayout", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], Termination.prototype, "severancePay", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 2 }),
    __metadata("design:type", Number)
], Termination.prototype, "totalFinalPayment", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb', nullable: true }),
    __metadata("design:type", Object)
], Termination.prototype, "paymentBreakdown", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Termination.prototype, "createdAt", void 0);
exports.Termination = Termination = __decorate([
    (0, typeorm_1.Entity)('terminations')
], Termination);
//# sourceMappingURL=termination.entity.js.map