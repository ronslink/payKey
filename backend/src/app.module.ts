import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bull';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { WorkersModule } from './modules/workers/workers.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { TransactionsModule } from './modules/transactions/transactions.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { TaxesModule } from './modules/taxes/taxes.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { CountriesModule } from './modules/countries/countries.module';
import { PayrollModule } from './modules/payroll/payroll.module';
import { TaxPaymentsModule } from './modules/tax-payments/tax-payments.module';
import { AccountingModule } from './modules/accounting/accounting.module';
import { ActivitiesModule } from './modules/activities/activities.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { TestingModule } from './modules/testing/testing.module';
import { ReportsModule } from './modules/reports/reports.module';
import { TimeTrackingModule } from './modules/time-tracking/time-tracking.module';
import { ExportModule } from './modules/export/export.module';
import { HolidaysModule } from './modules/holidays/holidays.module';
import { ExcelImportModule } from './modules/excel-import/excel-import.module';
import { AppCacheModule } from './modules/cache/cache.module';
import { AppThrottlerModule } from './modules/throttler/throttler.module';
import { PropertiesModule } from './modules/properties/properties.module';
import { DataDeletionModule } from './modules/data-deletion/data-deletion.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { GovIntegrationsModule } from './modules/gov-integrations/gov-integrations.module';
import { getDatabaseConfig } from './config/database.config';

// Explicit Entity Imports
// Explicit Entity Imports
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
import { SubscriptionPayment } from './modules/subscriptions/entities/subscription-payment.entity';
import { Property } from './modules/properties/entities/property.entity';
import { Country } from './modules/countries/entities/country.entity';
import { LeaveRequest } from './modules/workers/entities/leave-request.entity';
import { Termination } from './modules/workers/entities/termination.entity';
import { AccountMapping } from './modules/accounting/entities/account-mapping.entity';
import { AccountingExport } from './modules/accounting/entities/accounting-export.entity';
import { Activity } from './modules/activities/entities/activity.entity';
import { TimeEntry } from './modules/time-tracking/entities/time-entry.entity';
import { Export } from './modules/export/entities/export.entity';
import { Holiday } from './modules/holidays/entities/holiday.entity';
import { DeletionRequest } from './modules/data-deletion/entities/deletion-request.entity';
import { Notification } from './modules/notifications/entities/notification.entity';
import { DeviceToken } from './modules/notifications/entities/device-token.entity';
import { GovSubmission } from './modules/gov-integrations/entities/gov-submission.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: !process.env.NODE_ENV
        ? '.env'
        : [`.env.${process.env.NODE_ENV}`, '.env'],
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: getDatabaseConfig,
      inject: [ConfigService],
    }),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        redis: {
          host: configService.get('REDIS_HOST', 'localhost'),
          port: parseInt(configService.get('REDIS_PORT', '6379')),
          password: configService.get('REDIS_PASSWORD'),
        },
      }),
      inject: [ConfigService],
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    UsersModule,
    WorkersModule,
    SubscriptionsModule,
    TransactionsModule,
    PaymentsModule,
    TaxesModule,
    NotificationsModule,
    CountriesModule,
    PayrollModule,
    TaxPaymentsModule,
    AccountingModule,
    ActivitiesModule,
    TasksModule,
    TestingModule,
    ReportsModule,
    TimeTrackingModule,
    ExportModule,
    HolidaysModule,
    ExcelImportModule,
    AppCacheModule,
    AppThrottlerModule,
    PropertiesModule,
    DataDeletionModule,
    UploadsModule,
    GovIntegrationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
  exports: [],
})
export class AppModule {
  constructor() {
    console.log('AppModule initialized');
  }
}
