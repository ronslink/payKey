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
exports.TaxTable = void 0;
const typeorm_1 = require("typeorm");
let TaxTable = class TaxTable {
    id;
    year;
    effectiveDate;
    nssfConfig;
    nhifConfig;
    housingLevyRate;
    payeBands;
    personalRelief;
    isActive;
    createdAt;
    updatedAt;
};
exports.TaxTable = TaxTable;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], TaxTable.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", Number)
], TaxTable.prototype, "year", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], TaxTable.prototype, "effectiveDate", void 0);
__decorate([
    (0, typeorm_1.Column)('jsonb'),
    __metadata("design:type", Object)
], TaxTable.prototype, "nssfConfig", void 0);
__decorate([
    (0, typeorm_1.Column)('jsonb'),
    __metadata("design:type", Object)
], TaxTable.prototype, "nhifConfig", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 5, scale: 4 }),
    __metadata("design:type", Number)
], TaxTable.prototype, "housingLevyRate", void 0);
__decorate([
    (0, typeorm_1.Column)('jsonb'),
    __metadata("design:type", Array)
], TaxTable.prototype, "payeBands", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2 }),
    __metadata("design:type", Number)
], TaxTable.prototype, "personalRelief", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: true }),
    __metadata("design:type", Boolean)
], TaxTable.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], TaxTable.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], TaxTable.prototype, "updatedAt", void 0);
exports.TaxTable = TaxTable = __decorate([
    (0, typeorm_1.Entity)('tax_tables')
], TaxTable);
//# sourceMappingURL=tax-table.entity.js.map