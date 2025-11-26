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
exports.MonthlyTaxSummaryDto = exports.TaxSummaryDto = exports.CreateTaxPaymentDto = void 0;
const class_validator_1 = require("class-validator");
const tax_config_entity_1 = require("../../tax-config/entities/tax-config.entity");
const tax_payment_entity_1 = require("../entities/tax-payment.entity");
class CreateTaxPaymentDto {
    taxType;
    paymentYear;
    paymentMonth;
    amount;
    paymentDate;
    paymentMethod;
    receiptNumber;
    notes;
}
exports.CreateTaxPaymentDto = CreateTaxPaymentDto;
__decorate([
    (0, class_validator_1.IsEnum)(tax_config_entity_1.TaxType),
    __metadata("design:type", String)
], CreateTaxPaymentDto.prototype, "taxType", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(2020),
    (0, class_validator_1.Max)(2100),
    __metadata("design:type", Number)
], CreateTaxPaymentDto.prototype, "paymentYear", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.Max)(12),
    __metadata("design:type", Number)
], CreateTaxPaymentDto.prototype, "paymentMonth", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateTaxPaymentDto.prototype, "amount", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTaxPaymentDto.prototype, "paymentDate", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(tax_payment_entity_1.PaymentMethod),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTaxPaymentDto.prototype, "paymentMethod", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTaxPaymentDto.prototype, "receiptNumber", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTaxPaymentDto.prototype, "notes", void 0);
class TaxSummaryDto {
    taxType;
    amount;
    status;
    dueDate;
}
exports.TaxSummaryDto = TaxSummaryDto;
class MonthlyTaxSummaryDto {
    year;
    month;
    totalDue;
    totalPaid;
    taxes;
    paymentInstructions;
}
exports.MonthlyTaxSummaryDto = MonthlyTaxSummaryDto;
//# sourceMappingURL=tax-payment.dto.js.map