import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import * as path from 'path';
import { getDatabaseConnection } from './database-connection';

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
import { SubscriptionPlan } from '../modules/subscriptions/entities/subscription-plan.entity';
import { PromotionalItem } from '../modules/subscriptions/entities/promotional-item.entity';
import { Campaign } from '../modules/subscriptions/entities/campaign.entity';
import { SupportTicket } from '../modules/support/entities/support-ticket.entity';
import { SupportMessage } from '../modules/support/entities/support-message.entity';
import { AdminAuditLog } from '../modules/admin/entities/audit-log.entity';

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
  const get = (key: string): string | undefined =>
    configService.get<string>(key);
  const isTest = get('NODE_ENV') === 'test';
  const production = get('NODE_ENV') === 'production';
  return {
    type: 'postgres',
    ...getDatabaseConnection(get),
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
      SubscriptionPlan,
      PromotionalItem,
      Campaign,
      SupportTicket,
      SupportMessage,
      AdminAuditLog,
    ],
    synchronize: !production && (isTest || get('DB_SYNCHRONIZE') === 'true'),
    logging:
      !production && get('DB_LOGGING') === 'true' ? ['query', 'error'] : false,
    migrations: [path.join(__dirname, '../migrations/*{.ts,.js}')],
    // Schema changes are an explicit deployment step, never a startup side effect.
    migrationsRun: false,
    migrationsTableName: 'migrations',
  };
};
