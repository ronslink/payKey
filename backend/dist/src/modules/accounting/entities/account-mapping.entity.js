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
exports.AccountMapping = exports.AccountCategory = void 0;
const typeorm_1 = require("typeorm");
var AccountCategory;
(function (AccountCategory) {
    AccountCategory["SALARY_EXPENSE"] = "SALARY_EXPENSE";
    AccountCategory["PAYE_LIABILITY"] = "PAYE_LIABILITY";
    AccountCategory["NSSF_LIABILITY"] = "NSSF_LIABILITY";
    AccountCategory["NHIF_LIABILITY"] = "NHIF_LIABILITY";
    AccountCategory["HOUSING_LEVY_LIABILITY"] = "HOUSING_LEVY_LIABILITY";
    AccountCategory["CASH_BANK"] = "CASH_BANK";
})(AccountCategory || (exports.AccountCategory = AccountCategory = {}));
let AccountMapping = class AccountMapping {
    id;
    userId;
    category;
    accountCode;
    accountName;
    description;
    createdAt;
    updatedAt;
};
exports.AccountMapping = AccountMapping;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], AccountMapping.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AccountMapping.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: AccountCategory,
    }),
    __metadata("design:type", String)
], AccountMapping.prototype, "category", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AccountMapping.prototype, "accountCode", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], AccountMapping.prototype, "accountName", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], AccountMapping.prototype, "description", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], AccountMapping.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], AccountMapping.prototype, "updatedAt", void 0);
exports.AccountMapping = AccountMapping = __decorate([
    (0, typeorm_1.Entity)('account_mappings')
], AccountMapping);
//# sourceMappingURL=account-mapping.entity.js.map