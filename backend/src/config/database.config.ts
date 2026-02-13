import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

// Entity Imports
import { User } from '../modules/users/entities/user.entity';
import { Worker } from '../modules/workers/entities/worker.entity';
import { PayPeriod } from '../modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../modules/payroll/entities/payroll-record.entity';
import { Transaction } from '../modules/payments/entities/transaction.entity';
import { TaxTable } from '../modules/taxes/entities/tax-table.entity';
import { TaxSubmission } from '../modules/taxes/entities/tax-submission.entity';
import { TaxPayment } from '../modules/tax-payments/entities/tax-payment.entity';
import { TaxConfig } from '../modules/tax-config/entities/tax-config.entity';
import { Subscription } from '../modules/subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../modules/subscriptions/entities/subscription-payment.entity';
import { Property } from '../modules/properties/entities/property.entity';
import { Country } from '../modules/countries/entities/country.entity';
import { LeaveRequest } from '../modules/workers/entities/leave-request.entity';
import { Termination } from '../modules/workers/entities/termination.entity';
import { AccountMapping } from '../modules/accounting/entities/account-mapping.entity';
import { AccountingExport } from '../modules/accounting/entities/accounting-export.entity';
import { Activity } from '../modules/activities/entities/activity.entity';
import { TimeEntry } from '../modules/time-tracking/entities/time-entry.entity';
import { Export } from '../modules/export/entities/export.entity';
import { Holiday } from '../modules/holidays/entities/holiday.entity';
import { DeletionRequest } from '../modules/data-deletion/entities/deletion-request.entity';
import { WorkerDocument } from '../modules/workers/entities/worker-document.entity';
import { GovSubmission } from '../modules/gov-integrations/entities/gov-submission.entity';
import { Notification } from '../modules/notifications/entities/notification.entity';
import { DeviceToken } from '../modules/notifications/entities/device-token.entity';
import { ExchangeRate } from '../modules/payments/entities/exchange-rate.entity';
import { SystemConfig } from '../modules/system-config/entities/system-config.entity';

/**
 * Get database configuration for TypeORM
 * Handles both local development and CI/CD environments
 *
 * Priority in CI/CD:
 * 1. Process environment variables (from GitHub Actions)
 * 2. .env.test file
 * 3. ConfigService
 * 4. Defaults
 */
export const getDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const isTest = process.env.NODE_ENV === 'test';
  // Check for any truthy value of CI or GITHUB_ACTIONS
  const isCI = !!(process.env.CI || process.env.GITHUB_ACTIONS);

  // Check for DATABASE_URL first (production/hosted DBs)
  const dbUrl = configService.get('DATABASE_URL');
  if (dbUrl) {
    return {
      type: 'postgres',
      url: dbUrl,
      ssl: { rejectUnauthorized: false },
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
        Export,
        Holiday,
        DeletionRequest,
        WorkerDocument,
        GovSubmission,
        Notification,
        DeviceToken,
        ExchangeRate,
        SystemConfig,
      ],
      synchronize: false, // Use migrations in production!
      logging: ['query', 'error'],
      migrationsRun: true, // Auto-run migrations on startup
    };
  }

  // In CI environments, prioritize process.env over ConfigService
  // This ensures GitHub Actions environment variables are used
  const getConfig = (key: string, defaultValue: string = ''): string => {
    if (isCI) {
      // In CI, use process.env directly
      return process.env[key] || defaultValue;
    }
    // Locally, use ConfigService with proper typing
    return configService.get<string>(key) || defaultValue;
  };

  // Get username with multiple fallbacks
  // In CI, force 'postgres' user if DB_USER/DB_USERNAME are missing or explicitly set to root,
  // OR if we suspect permissions issues. To be safe, let's stick to env vars but add logging.

  // Safer strategy: If CI, and no explicit user, default to 'postgres' (superuser) instead of 'paykey'
  const defaultUser = isCI ? 'postgres' : 'paykey';
  const username =
    getConfig('DB_USERNAME') || getConfig('DB_USER') || defaultUser;

  const password = getConfig('DB_PASSWORD', 'Tina76');
  const host = getConfig('DB_HOST', 'localhost');
  const port = parseInt(getConfig('DB_PORT', '5432'));
  const database = getConfig('DB_NAME', isTest ? 'paykey_test' : 'paykey');

  const config: TypeOrmModuleOptions = {
    type: 'postgres',
    host,
    port,
    username,
    password,
    database,
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
      Export,
      Holiday,
      DeletionRequest,
      WorkerDocument,
      GovSubmission,
      Notification,
      DeviceToken,
      ExchangeRate,
      SystemConfig,
    ],
    ],
    synchronize: isTest || true, // Keep enabled for now
    logging: ['query', 'error'],
  };

  // Log configuration in test/CI environments (without password)
  if (isTest || isCI) {
    console.log('🔧 Database Configuration:', {
      environment: isCI ? 'CI' : isTest ? 'Local Test' : 'Development',
      host: config.host,
      port: config.port,
      username: config.username,
      database: config.database,
      synchronize: config.synchronize,
    });
  }

  return config;
};
