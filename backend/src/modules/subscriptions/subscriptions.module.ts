import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionsController } from './subscriptions.controller';
import { FeatureAccessController } from './feature-access.controller';
import { Subscription } from './entities/subscription.entity';
import { SubscriptionPayment } from './entities/subscription-payment.entity';
import { FeatureAccessService } from './feature-access.service';
import { MockDataService } from './mock-data.service';
import { UsersModule } from '../users/users.module';

import { SubscriptionCallbackController } from './subscription-callback.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subscription, SubscriptionPayment]),
    forwardRef(() => UsersModule),
  ],
  controllers: [SubscriptionsController, FeatureAccessController, SubscriptionCallbackController],
  providers: [FeatureAccessService, MockDataService],
  exports: [FeatureAccessService, MockDataService],
})
export class SubscriptionsModule { }
