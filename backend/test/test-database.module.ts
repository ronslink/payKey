// test/test-database.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { PayPeriod } from '../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../src/modules/payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../src/modules/taxes/entities/tax-submission.entity';
import { TaxPayment } from '../src/modules/tax-payments/entities/tax-payment.entity';
import { TaxConfig } from '../src/modules/tax-config/entities/tax-config.entity';
import { TimeEntry } from '../src/modules/time-tracking/entities/time-entry.entity';
import { LeaveRequest } from '../src/modules/workers/entities/leave-request.entity';
import { Termination } from '../src/modules/workers/entities/termination.entity';
import { Subscription } from '../src/modules/subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../src/modules/subscriptions/entities/subscription-payment.entity';
import { AccountingExport } from '../src/modules/accounting/entities/accounting-export.entity';
import { Transaction } from '../src/modules/payments/entities/transaction.entity';
import { TaxTable } from '../src/modules/taxes/entities/tax-table.entity';
import { Export } from '../src/modules/export/entities/export.entity';
import { Property } from '../src/modules/properties/entities/property.entity';
import { Country } from '../src/modules/countries/entities/country.entity';
import { AccountMapping } from '../src/modules/accounting/entities/account-mapping.entity';
import { Activity } from '../src/modules/activities/entities/activity.entity';
import { Holiday } from '../src/modules/holidays/entities/holiday.entity';
import { DeletionRequest } from '../src/modules/data-deletion/entities/deletion-request.entity';
import { WorkerDocument } from '../src/modules/workers/entities/worker-document.entity';
import { GovSubmission } from '../src/modules/gov-integrations/entities/gov-submission.entity';
import { Notification } from '../src/modules/notifications/entities/notification.entity';
import { DeviceToken } from '../src/modules/notifications/entities/device-token.entity';
import { ExchangeRate } from '../src/modules/payments/entities/exchange-rate.entity';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: parseInt(configService.get<string>('DB_PORT', '5432')),
        // Use paykey as default to match CI configuration
        username: configService.get<string>('DB_USER') || configService.get<string>('DB_USERNAME', 'paykey'),
        password: configService.get<string>('DB_PASSWORD', 'password'),
        database: configService.get<string>('DB_NAME') || configService.get<string>('DB_DATABASE', 'paykey_test'),
        entities: [
          User,
          Worker,
          PayPeriod,
          PayrollRecord,
          TaxSubmission,
          TaxPayment,
          TaxConfig,
          TimeEntry,
          LeaveRequest,
          Termination,
          Subscription,
          SubscriptionPayment,
          AccountingExport,
          Property,
          Country,
          AccountMapping,
          Activity,
          Holiday,
          DeletionRequest,
          WorkerDocument,
          GovSubmission,
          Notification,
          DeviceToken,
          Transaction,
          TaxTable,
          Export,
          ExchangeRate,
        ],
        synchronize: true, // Auto-create schema for tests
        dropSchema: true, // Clean slate for each test run
        logging: false, // Disable query logging for tests
        extra: {
          // Connection pool settings for tests
          max: 10,
          min: 0,
          acquireTimeoutMillis: 10000,
          idleTimeoutMillis: 30000,
        },
      }),
      inject: [ConfigService],
    }),
  ],
})
export class TestDatabaseModule { }