import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { User } from './modules/users/entities/user.entity';
import { Worker } from './modules/workers/entities/worker.entity';
import { PayPeriod } from './modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from './modules/payroll/entities/payroll-record.entity';
import { Transaction } from './modules/payments/entities/transaction.entity';
import { TaxTable } from './modules/taxes/entities/tax-table.entity';
import { TaxSubmission } from './modules/taxes/entities/tax-submission.entity';
import { TaxPayment } from './modules/tax-payments/entities/tax-payment.entity';
import { TaxConfig } from './modules/tax-config/entities/tax-config.entity';
import { Subscription } from './modules/subscriptions/entities/subscription.entity';
import { Property } from './modules/properties/entities/property.entity';
import { Country } from './modules/countries/entities/country.entity';
import { LeaveRequest } from './modules/workers/entities/leave-request.entity';
import { Termination } from './modules/workers/entities/termination.entity';
import { ConfigService } from '@nestjs/config';

async function syncDatabase() {
  const configService = new ConfigService();
  
  const dataSource = new DataSource({
    type: 'postgres',
    host: configService.get('DB_HOST', 'localhost'),
    port: configService.get('DB_PORT', 5432),
    username: configService.get('DB_USERNAME', 'postgres'),
    password: configService.get('DB_PASSWORD', 'admin'),
    database: configService.get('DB_NAME', 'paykey'),
    entities: [
      User,
      Worker,
      PayPeriod,
      PayrollRecord,
      Transaction,
      TaxTable,
      TaxSubmission,
      TaxPayment,
      TaxConfig,
      Subscription,
      Property,
      Country,
      LeaveRequest,
      Termination,
    ],
    synchronize: true,
    logging: true,
  });

  try {
    await dataSource.initialize();
    console.log('Database schema synchronized successfully!');
  } catch (error) {
    console.error('Error syncing database schema:', error);
  } finally {
    await dataSource.destroy();
  }
}

syncDatabase();