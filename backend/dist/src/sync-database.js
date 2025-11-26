"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
const typeorm_1 = require("typeorm");
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
const property_entity_1 = require("./modules/properties/entities/property.entity");
const country_entity_1 = require("./modules/countries/entities/country.entity");
const leave_request_entity_1 = require("./modules/workers/entities/leave-request.entity");
const termination_entity_1 = require("./modules/workers/entities/termination.entity");
const config_1 = require("@nestjs/config");
async function syncDatabase() {
    const configService = new config_1.ConfigService();
    const dataSource = new typeorm_1.DataSource({
        type: 'postgres',
        host: configService.get('DB_HOST', 'localhost'),
        port: configService.get('DB_PORT', 5432),
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
            property_entity_1.Property,
            country_entity_1.Country,
            leave_request_entity_1.LeaveRequest,
            termination_entity_1.Termination,
        ],
        synchronize: true,
        logging: true,
    });
    try {
        await dataSource.initialize();
        console.log('Database schema synchronized successfully!');
    }
    catch (error) {
        console.error('Error syncing database schema:', error);
    }
    finally {
        await dataSource.destroy();
    }
}
syncDatabase();
//# sourceMappingURL=sync-database.js.map