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
exports.AccountingExport = exports.ExportStatus = exports.ExportFormat = void 0;
const typeorm_1 = require("typeorm");
const pay_period_entity_1 = require("../../payroll/entities/pay-period.entity");
var ExportFormat;
(function (ExportFormat) {
    ExportFormat["CSV"] = "CSV";
    ExportFormat["EXCEL"] = "EXCEL";
    ExportFormat["QUICKBOOKS"] = "QUICKBOOKS";
    ExportFormat["XERO"] = "XERO";
    ExportFormat["SAGE"] = "SAGE";
})(ExportFormat || (exports.ExportFormat = ExportFormat = {}));
var ExportStatus;
(function (ExportStatus) {
    ExportStatus["PENDING"] = "PENDING";
    ExportStatus["COMPLETED"] = "COMPLETED";
    ExportStatus["FAILED"] = "FAILED";
})(ExportStatus || (exports.ExportStatus = ExportStatus = {}));
let AccountingExport = class AccountingExport {
    id;
    userId;
    payPeriod;
    payPeriodId;
    format;
    status;
    filePath;
    externalId;
    errorMessage;
    createdAt;
};
exports.AccountingExport = AccountingExport;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], AccountingExport.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AccountingExport.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => pay_period_entity_1.PayPeriod),
    (0, typeorm_1.JoinColumn)({ name: 'payPeriodId' }),
    __metadata("design:type", pay_period_entity_1.PayPeriod)
], AccountingExport.prototype, "payPeriod", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AccountingExport.prototype, "payPeriodId", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: ExportFormat,
    }),
    __metadata("design:type", String)
], AccountingExport.prototype, "format", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: ExportStatus,
        default: ExportStatus.PENDING,
    }),
    __metadata("design:type", String)
], AccountingExport.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], AccountingExport.prototype, "filePath", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], AccountingExport.prototype, "externalId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], AccountingExport.prototype, "errorMessage", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], AccountingExport.prototype, "createdAt", void 0);
exports.AccountingExport = AccountingExport = __decorate([
    (0, typeorm_1.Entity)('accounting_exports')
], AccountingExport);
//# sourceMappingURL=accounting-export.entity.js.map