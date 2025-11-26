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
exports.FinalPaymentCalculationDto = exports.CreateTerminationDto = void 0;
const class_validator_1 = require("class-validator");
const termination_entity_1 = require("../entities/termination.entity");
class CreateTerminationDto {
    reason;
    terminationDate;
    lastWorkingDate;
    noticePeriodDays;
    notes;
    severancePay;
    outstandingPayments;
}
exports.CreateTerminationDto = CreateTerminationDto;
__decorate([
    (0, class_validator_1.IsEnum)(termination_entity_1.TerminationReason),
    __metadata("design:type", String)
], CreateTerminationDto.prototype, "reason", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateTerminationDto.prototype, "terminationDate", void 0);
__decorate([
    (0, class_validator_1.IsDateString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTerminationDto.prototype, "lastWorkingDate", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Number)
], CreateTerminationDto.prototype, "noticePeriodDays", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateTerminationDto.prototype, "notes", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateTerminationDto.prototype, "severancePay", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateTerminationDto.prototype, "outstandingPayments", void 0);
class FinalPaymentCalculationDto {
    proratedSalary;
    unusedLeavePayout;
    severancePay;
    totalGross;
    taxDeductions;
    totalNet;
    breakdown;
}
exports.FinalPaymentCalculationDto = FinalPaymentCalculationDto;
//# sourceMappingURL=termination.dto.js.map