"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const auth_module_1 = require("./modules/auth/auth.module");
const users_module_1 = require("./modules/users/users.module");
const workers_module_1 = require("./modules/workers/workers.module");
const subscriptions_module_1 = require("./modules/subscriptions/subscriptions.module");
const transactions_module_1 = require("./modules/transactions/transactions.module");
const payments_module_1 = require("./modules/payments/payments.module");
const taxes_module_1 = require("./modules/taxes/taxes.module");
const notifications_module_1 = require("./modules/notifications/notifications.module");
const countries_module_1 = require("./modules/countries/countries.module");
const payroll_module_1 = require("./modules/payroll/payroll.module");
const tax_payments_module_1 = require("./modules/tax-payments/tax-payments.module");
const accounting_module_1 = require("./modules/accounting/accounting.module");
const activities_module_1 = require("./modules/activities/activities.module");
const user_entity_1 = require("./modules/users/entities/user.entity");
const worker_entity_1 = require("./modules/workers/entities/worker.entity");
const pay_period_entity_1 = require("./modules/payroll/entities/pay-period.entity");
const payroll_record_entity_1 = require("./modules/payroll/entities/payroll-record.entity");
const transaction_entity_1 = require("./modules/payments/entities/transaction.entity");
const tax_table_entity_1 = require("./modules/taxes/entities/tax-table.entity");
const tax_submission_entity_1 = require("./modules/taxes/entities/tax-submission.entity");
const tax_payment_entity_1 = require("./modules/tax-payments/entities/tax-payment.entity");
const tax_config_entity_1 = require("./modules/tax-config/entities/tax-config.entity");
const subscription_entity_1 = require("./modules/subscriptions/entities/subscription.entity");
const subscription_payment_entity_1 = require("./modules/subscriptions/entities/subscription-payment.entity");
const property_entity_1 = require("./modules/properties/entities/property.entity");
const country_entity_1 = require("./modules/countries/entities/country.entity");
const leave_request_entity_1 = require("./modules/workers/entities/leave-request.entity");
const termination_entity_1 = require("./modules/workers/entities/termination.entity");
const account_mapping_entity_1 = require("./modules/accounting/entities/account-mapping.entity");
const accounting_export_entity_1 = require("./modules/accounting/entities/accounting-export.entity");
const activity_entity_1 = require("./modules/activities/entities/activity.entity");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            typeorm_1.TypeOrmModule.forRootAsync({
                imports: [config_1.ConfigModule],
                useFactory: (configService) => ({
                    type: 'postgres',
                    host: configService.get('DB_HOST', 'localhost'),
                    port: parseInt(configService.get('DB_PORT', '5432')),
                    username: configService.get('DB_USERNAME', 'postgres'),
                    password: configService.get('DB_PASSWORD', 'admin'),
                    database: configService.get('DB_NAME', 'paykey'),
                    entities: [
                        user_entity_1.User,
                        worker_entity_1.Worker,
                        pay_period_entity_1.PayPeriod,
                        payroll_record_entity_1.PayrollRecord,
                        transaction_entity_1.Transaction,
                        tax_table_entity_1.TaxTable,
                        tax_submission_entity_1.TaxSubmission,
                        tax_payment_entity_1.TaxPayment,
                        tax_config_entity_1.TaxConfig,
                        subscription_entity_1.Subscription,
                        subscription_payment_entity_1.SubscriptionPayment,
                        property_entity_1.Property,
                        country_entity_1.Country,
                        leave_request_entity_1.LeaveRequest,
                        termination_entity_1.Termination,
                        account_mapping_entity_1.AccountMapping,
                        accounting_export_entity_1.AccountingExport,
                        activity_entity_1.Activity,
                    ],
                    synchronize: false,
                    logging: ['query', 'error'],
                }),
                inject: [config_1.ConfigService],
            }),
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            workers_module_1.WorkersModule,
            subscriptions_module_1.SubscriptionsModule,
            transactions_module_1.TransactionsModule,
            payments_module_1.PaymentsModule,
            taxes_module_1.TaxesModule,
            notifications_module_1.NotificationsModule,
            countries_module_1.CountriesModule,
            payroll_module_1.PayrollModule,
            tax_payments_module_1.TaxPaymentsModule,
            accounting_module_1.AccountingModule,
            activities_module_1.ActivitiesModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [app_service_1.AppService],
        exports: [],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map