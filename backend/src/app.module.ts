import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
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
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => {
        const dbHost = configService.get('DB_HOST', 'db');
        const dbPort = configService.get('DB_PORT', '5432');
        const dbUser = configService.get('DB_USER') || configService.get('DB_USERNAME') || 'postgres';
        return {
          type: 'postgres',
          host: dbHost,
          port: parseInt(configService.get('DB_PORT', '5432')),
          username: configService.get('DB_USER', configService.get('DB_USERNAME', 'postgres')),
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
            SubscriptionPayment,
            Property,
            Country,
            LeaveRequest,
            Termination,
            AccountMapping,
            AccountingExport,
            Activity,
            TimeEntry,
          ],

          synchronize: false,
          logging: ['query', 'error'],
        };
      },
      inject: [ConfigService],
    }),
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
  ],
  controllers: [AppController],
  providers: [AppService],
  exports: [],
})
export class AppModule { }
