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
exports.TaxSubmission = exports.TaxSubmissionStatus = void 0;
const typeorm_1 = require("typeorm");
const pay_period_entity_1 = require("../../payroll/entities/pay-period.entity");
var TaxSubmissionStatus;
(function (TaxSubmissionStatus) {
    TaxSubmissionStatus["PENDING"] = "PENDING";
    TaxSubmissionStatus["FILED"] = "FILED";
})(TaxSubmissionStatus || (exports.TaxSubmissionStatus = TaxSubmissionStatus = {}));
let TaxSubmission = class TaxSubmission {
    id;
    userId;
    payPeriod;
    payPeriodId;
    totalPaye;
    totalNssf;
    totalNhif;
    totalHousingLevy;
    status;
    filingDate;
    createdAt;
    updatedAt;
};
exports.TaxSubmission = TaxSubmission;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], TaxSubmission.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], TaxSubmission.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => pay_period_entity_1.PayPeriod, (payPeriod) => payPeriod.taxSubmissions),
    (0, typeorm_1.JoinColumn)({ name: 'payPeriodId' }),
    __metadata("design:type", pay_period_entity_1.PayPeriod)
], TaxSubmission.prototype, "payPeriod", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], TaxSubmission.prototype, "payPeriodId", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], TaxSubmission.prototype, "totalPaye", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], TaxSubmission.prototype, "totalNssf", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], TaxSubmission.prototype, "totalNhif", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0 }),
    __metadata("design:type", Number)
], TaxSubmission.prototype, "totalHousingLevy", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: TaxSubmissionStatus,
        default: TaxSubmissionStatus.PENDING,
    }),
    __metadata("design:type", String)
], TaxSubmission.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], TaxSubmission.prototype, "filingDate", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], TaxSubmission.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], TaxSubmission.prototype, "updatedAt", void 0);
exports.TaxSubmission = TaxSubmission = __decorate([
    (0, typeorm_1.Entity)('tax_submissions')
], TaxSubmission);
//# sourceMappingURL=tax-submission.entity.js.map