import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { PaymentsController } from './payments.controller';
import { UnifiedPaymentsController } from './unified-payments.controller';
import { SubscriptionPaymentsController } from './subscription-payments.controller';
import { StripeService } from './stripe.service';
import { PayrollPaymentService } from './payroll-payment.service';
import { IntaSendService } from './intasend.service';
import { WalletProcessor } from './wallet.processor';
import { BalanceSyncTask } from './balance-sync.task';

import { Transaction } from './entities/transaction.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { TaxesModule } from '../taxes/taxes.module';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { User } from '../users/entities/user.entity';
import { TimeTrackingModule } from '../time-tracking/time-tracking.module';
import { TaxPaymentsModule } from '../tax-payments/tax-payments.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { ExchangeRate } from './entities/exchange-rate.entity';

import { HttpModule } from '@nestjs/axios';

import { ExchangeRateService } from './exchange-rate.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Transaction,
      Worker,
      PayPeriod,
      PayrollRecord,
      TaxSubmission,
      Subscription,
      SubscriptionPayment,
      User,
      DeviceToken,
      ExchangeRate,
    ]),
    forwardRef(() => TaxesModule),
    forwardRef(() => TimeTrackingModule),
    forwardRef(() => TaxPaymentsModule),
    HttpModule,
    ConfigModule,
    BullModule.registerQueue(
      { name: 'wallets' },
      { name: 'payroll-processing' }, // For scheduling status check jobs
    ),
    NotificationsModule,
  ],
  controllers: [
    PaymentsController,
    UnifiedPaymentsController,
    SubscriptionPaymentsController,
  ],
  providers: [
    StripeService,
    PayrollPaymentService,
    IntaSendService,
    WalletProcessor,
    BalanceSyncTask,
    ExchangeRateService,
  ],
  exports: [
    StripeService,
    PayrollPaymentService,
    IntaSendService,
    ExchangeRateService,
  ],
})
export class PaymentsModule {}
