"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaxPaymentsModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const tax_payment_entity_1 = require("./entities/tax-payment.entity");
const tax_payments_service_1 = require("./services/tax-payments.service");
const tax_payments_controller_1 = require("./controllers/tax-payments.controller");
const tax_config_module_1 = require("../tax-config/tax-config.module");
const taxes_module_1 = require("../taxes/taxes.module");
let TaxPaymentsModule = class TaxPaymentsModule {
};
exports.TaxPaymentsModule = TaxPaymentsModule;
exports.TaxPaymentsModule = TaxPaymentsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([tax_payment_entity_1.TaxPayment]),
            tax_config_module_1.TaxConfigModule,
            taxes_module_1.TaxesModule,
        ],
        controllers: [tax_payments_controller_1.TaxPaymentsController],
        providers: [tax_payments_service_1.TaxPaymentsService],
        exports: [tax_payments_service_1.TaxPaymentsService],
    })
], TaxPaymentsModule);
//# sourceMappingURL=tax-payments.module.js.map