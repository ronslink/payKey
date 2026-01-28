import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bullmq';
import { SubscriptionsController } from './subscriptions.controller';
import { FeatureAccessController } from './feature-access.controller';
import { Subscription } from './entities/subscription.entity';
import { SubscriptionPayment } from './entities/subscription-payment.entity';
import { FeatureAccessService } from './feature-access.service';
import { MockDataService } from './mock-data.service';
import { UsersModule } from '../users/users.module';
import { PaymentsModule } from '../payments/payments.module';
import { Transaction } from '../payments/entities/transaction.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { User } from '../users/entities/user.entity';
import { NotificationsModule } from '../notifications/notifications.module';

import { SubscriptionCallbackController } from './subscription-callback.controller';
import { ImportFeatureGuard } from './import-feature.guard';
import { SubscriptionProcessor } from './subscription.processor';
import { SubscriptionScheduler } from './subscription.scheduler';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Subscription,
      SubscriptionPayment,
      Transaction,
      DeviceToken,
      User,
    ]),
    BullModule.registerQueue({
      name: 'subscriptions',
    }),
    forwardRef(() => UsersModule),
    forwardRef(() => PaymentsModule),
    NotificationsModule,
  ],
  controllers: [
    SubscriptionsController,
    FeatureAccessController,
    SubscriptionCallbackController,
  ],
  providers: [
    FeatureAccessService,
    MockDataService,
    ImportFeatureGuard,
    SubscriptionProcessor,
    SubscriptionScheduler,
  ],
  exports: [FeatureAccessService, MockDataService, ImportFeatureGuard],
})
export class SubscriptionsModule { }
