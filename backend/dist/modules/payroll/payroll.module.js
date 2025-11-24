"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PayrollModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const payroll_controller_1 = require("./payroll.controller");
const payroll_service_1 = require("./payroll.service");
const batch_payroll_controller_1 = require("./batch-payroll.controller");
const batch_payroll_service_1 = require("./batch-payroll.service");
const payroll_records_controller_1 = require("./payroll-records.controller");
const pay_periods_controller_1 = require("./pay-periods.controller");
const pay_period_entity_1 = require("./entities/pay-period.entity");
const payroll_record_entity_1 = require("./entities/payroll-record.entity");
const worker_entity_1 = require("../workers/entities/worker.entity");
const transaction_entity_1 = require("../payments/entities/transaction.entity");
const tax_submission_entity_1 = require("../taxes/entities/tax-submission.entity");
const pay_periods_service_1 = require("./pay-periods.service");
const payments_module_1 = require("../payments/payments.module");
const taxes_module_1 = require("../taxes/taxes.module");
const tax_payments_module_1 = require("../tax-payments/tax-payments.module");
let PayrollModule = class PayrollModule {
};
exports.PayrollModule = PayrollModule;
exports.PayrollModule = PayrollModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([pay_period_entity_1.PayPeriod, payroll_record_entity_1.PayrollRecord, worker_entity_1.Worker, transaction_entity_1.Transaction, tax_submission_entity_1.TaxSubmission]),
            payments_module_1.PaymentsModule,
            taxes_module_1.TaxesModule,
            tax_payments_module_1.TaxPaymentsModule,
        ],
        controllers: [
            payroll_controller_1.PayrollController,
            batch_payroll_controller_1.BatchPayrollController,
            payroll_records_controller_1.PayrollRecordsController,
            pay_periods_controller_1.PayPeriodsController,
        ],
        providers: [payroll_service_1.PayrollService, batch_payroll_service_1.BatchPayrollService, pay_periods_service_1.PayPeriodsService],
        exports: [payroll_service_1.PayrollService, batch_payroll_service_1.BatchPayrollService, pay_periods_service_1.PayPeriodsService],
    })
], PayrollModule);
//# sourceMappingURL=payroll.module.js.map