"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaxesModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const taxes_controller_1 = require("./taxes.controller");
const tax_submission_controller_1 = require("./tax-submission.controller");
const taxes_service_1 = require("./taxes.service");
const tax_table_entity_1 = require("./entities/tax-table.entity");
const tax_submission_entity_1 = require("./entities/tax-submission.entity");
const users_module_1 = require("../users/users.module");
const tax_config_module_1 = require("../tax-config/tax-config.module");
const payroll_record_entity_1 = require("../payroll/entities/payroll-record.entity");
let TaxesModule = class TaxesModule {
};
exports.TaxesModule = TaxesModule;
exports.TaxesModule = TaxesModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([tax_table_entity_1.TaxTable, tax_submission_entity_1.TaxSubmission, payroll_record_entity_1.PayrollRecord]),
            users_module_1.UsersModule,
            tax_config_module_1.TaxConfigModule
        ],
        controllers: [taxes_controller_1.TaxesController, tax_submission_controller_1.TaxSubmissionController],
        providers: [taxes_service_1.TaxesService],
        exports: [taxes_service_1.TaxesService],
    })
], TaxesModule);
//# sourceMappingURL=taxes.module.js.map