import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bullmq';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminSubscriptionsController } from './admin-subscriptions.controller';
import { AdminRefundsController } from './admin-refunds.controller';
import { AdminTaxConfigController } from './admin-tax-config.controller';
import { User } from '../users/entities/user.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPlan } from '../subscriptions/entities/subscription-plan.entity';
import { PromotionalItem } from '../subscriptions/entities/promotional-item.entity';
import { Campaign } from '../subscriptions/entities/campaign.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';
import { AdminAuditLog } from './entities/audit-log.entity';
import { TaxConfig } from '../tax-config/entities/tax-config.entity';
import { PaymentsModule } from '../payments/payments.module';
import { SystemConfigModule } from '../system-config/system-config.module';
import { SystemConfig } from '../system-config/entities/system-config.entity';
import { AdminSystemConfigController } from './admin-system-config.controller';
import { NotificationsModule } from '../notifications/notifications.module';
import { Notification } from '../notifications/entities/notification.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { AdminNotificationsController } from './admin-notifications.controller';
import { AdminAuditController } from './admin-audit.controller';
import { AdminOperationsController } from './admin-operations.controller';
import { DeletionRequest } from '../data-deletion/entities/deletion-request.entity';
import { DataDeletionModule } from '../data-deletion/data-deletion.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Worker,
      Transaction,
      Subscription,
      SubscriptionPlan,
      PromotionalItem,
      Campaign,
      PayPeriod,
      PayrollRecord,
      SupportTicket,
      TaxConfig,
      SystemConfig,
      AdminAuditLog,
      Notification,
      DeviceToken,
      DeletionRequest,
    ]),
    BullModule.registerQueue(
      { name: 'wallets' },
      { name: 'subscriptions' },
      { name: 'payroll-processing' },
    ),
    PaymentsModule, // for IntaSendService + StripeService injection in AdminRefundsController
    SystemConfigModule,
    NotificationsModule,
    DataDeletionModule,
  ],
  controllers: [
    AdminController,
    AdminSubscriptionsController,
    AdminRefundsController,
    AdminTaxConfigController,
    AdminSystemConfigController,
    AdminAuditController,
    AdminNotificationsController,
    AdminOperationsController,
  ],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
