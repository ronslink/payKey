import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, IsNull } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Subscription, SubscriptionStatus } from './entities/subscription.entity';

@Injectable()
export class SubscriptionScheduler {
    private readonly logger = new Logger(SubscriptionScheduler.name);

    constructor(
        @InjectRepository(Subscription)
        private readonly subscriptionRepository: Repository<Subscription>,
        @InjectQueue('subscriptions')
        private readonly subscriptionQueue: Queue,
    ) { }

    @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
    async handleSubscriptionRenewals() {
        this.logger.log('Checking for expiring subscriptions...');

        const now = new Date();

        // Find active subscriptions that:
        // 1. Are expiring (nextBillingDate <= NOW)
        // 2. Are not Stripe managed (stripeSubscriptionId IS NULL)
        // 3. Are Active or Past Due (retry)
        const expiringSubscriptions = await this.subscriptionRepository.find({
            where: [
                {
                    status: SubscriptionStatus.ACTIVE,
                    stripeSubscriptionId: IsNull(),
                    nextBillingDate: LessThanOrEqual(now),
                },
                // Optional: Retry PAST_DUE subscriptions?
                {
                    status: SubscriptionStatus.PAST_DUE,
                    stripeSubscriptionId: IsNull(),
                    nextBillingDate: LessThanOrEqual(now),
                }
            ],
        });

        this.logger.log(`Found ${expiringSubscriptions.length} subscriptions due for renewal`);

        for (const sub of expiringSubscriptions) {
            await this.subscriptionQueue.add('renew-subscription', {
                subscriptionId: sub.id,
            }, {
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 60000
                }
            });
        }
    }
}
