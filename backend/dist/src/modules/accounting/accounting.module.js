"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AccountingModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const accounting_controller_1 = require("./accounting.controller");
const accounting_export_service_1 = require("./accounting-export.service");
const account_mapping_entity_1 = require("./entities/account-mapping.entity");
const accounting_export_entity_1 = require("./entities/accounting-export.entity");
const payroll_record_entity_1 = require("../payroll/entities/payroll-record.entity");
let AccountingModule = class AccountingModule {
};
exports.AccountingModule = AccountingModule;
exports.AccountingModule = AccountingModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([account_mapping_entity_1.AccountMapping, accounting_export_entity_1.AccountingExport, payroll_record_entity_1.PayrollRecord]),
        ],
        controllers: [accounting_controller_1.AccountingController],
        providers: [accounting_export_service_1.AccountingExportService],
        exports: [accounting_export_service_1.AccountingExportService],
    })
], AccountingModule);
//# sourceMappingURL=accounting.module.js.map