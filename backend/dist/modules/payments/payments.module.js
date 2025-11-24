"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const payments_controller_1 = require("./payments.controller");
const mpesa_service_1 = require("./mpesa.service");
const payroll_service_1 = require("./payroll.service");
const transaction_entity_1 = require("./entities/transaction.entity");
const worker_entity_1 = require("../workers/entities/worker.entity");
const taxes_module_1 = require("../taxes/taxes.module");
const pay_period_entity_1 = require("../payroll/entities/pay-period.entity");
const tax_submission_entity_1 = require("../taxes/entities/tax-submission.entity");
const time_tracking_module_1 = require("../time-tracking/time-tracking.module");
const axios_1 = require("@nestjs/axios");
let PaymentsModule = class PaymentsModule {
};
exports.PaymentsModule = PaymentsModule;
exports.PaymentsModule = PaymentsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([transaction_entity_1.Transaction, worker_entity_1.Worker, pay_period_entity_1.PayPeriod, tax_submission_entity_1.TaxSubmission]),
            taxes_module_1.TaxesModule,
            time_tracking_module_1.TimeTrackingModule,
            axios_1.HttpModule,
        ],
        controllers: [payments_controller_1.PaymentsController],
        providers: [mpesa_service_1.MpesaService, payroll_service_1.PayrollService],
        exports: [mpesa_service_1.MpesaService],
    })
], PaymentsModule);
//# sourceMappingURL=payments.module.js.map