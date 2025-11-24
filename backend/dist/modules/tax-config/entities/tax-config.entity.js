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
exports.TaxConfig = exports.RateType = exports.TaxType = void 0;
const typeorm_1 = require("typeorm");
var TaxType;
(function (TaxType) {
    TaxType["PAYE"] = "PAYE";
    TaxType["SHIF"] = "SHIF";
    TaxType["NSSF_TIER1"] = "NSSF_TIER1";
    TaxType["NSSF_TIER2"] = "NSSF_TIER2";
    TaxType["HOUSING_LEVY"] = "HOUSING_LEVY";
})(TaxType || (exports.TaxType = TaxType = {}));
var RateType;
(function (RateType) {
    RateType["PERCENTAGE"] = "PERCENTAGE";
    RateType["GRADUATED"] = "GRADUATED";
    RateType["TIERED"] = "TIERED";
})(RateType || (exports.RateType = RateType = {}));
let TaxConfig = class TaxConfig {
    id;
    taxType;
    rateType;
    effectiveFrom;
    effectiveTo;
    configuration;
    paymentDeadline;
    isActive;
    notes;
    createdAt;
    updatedAt;
};
exports.TaxConfig = TaxConfig;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], TaxConfig.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: TaxType,
    }),
    __metadata("design:type", String)
], TaxConfig.prototype, "taxType", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: RateType,
    }),
    __metadata("design:type", String)
], TaxConfig.prototype, "rateType", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], TaxConfig.prototype, "effectiveFrom", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date', nullable: true }),
    __metadata("design:type", Date)
], TaxConfig.prototype, "effectiveTo", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'jsonb' }),
    __metadata("design:type", Object)
], TaxConfig.prototype, "configuration", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: '9th of following month' }),
    __metadata("design:type", String)
], TaxConfig.prototype, "paymentDeadline", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: true }),
    __metadata("design:type", Boolean)
], TaxConfig.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], TaxConfig.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], TaxConfig.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], TaxConfig.prototype, "updatedAt", void 0);
exports.TaxConfig = TaxConfig = __decorate([
    (0, typeorm_1.Entity)('tax_configs')
], TaxConfig);
//# sourceMappingURL=tax-config.entity.js.map