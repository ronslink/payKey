import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, SubscriptionStatus, SubscriptionTier } from './entities/subscription.entity';
import { SubscriptionPayment, PaymentStatus, PaymentMethod } from './entities/subscription-payment.entity';
import { User, UserTier } from '../users/entities/user.entity';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';
import { NotificationsService } from '../notifications/notifications.service';
import { DeviceToken } from '../notifications/entities/device-token.entity';

@Processor('subscriptions')
export class SubscriptionProcessor extends WorkerHost {
    private readonly logger = new Logger(SubscriptionProcessor.name);

    constructor(
        @InjectRepository(Subscription)
        private readonly subscriptionRepository: Repository<Subscription>,
        @InjectRepository(SubscriptionPayment)
        private readonly paymentRepository: Repository<SubscriptionPayment>,
        @InjectRepository(User)
        private readonly userRepository: Repository<User>,
        @InjectRepository(DeviceToken)
        private readonly deviceTokenRepository: Repository<DeviceToken>,
        private readonly notificationsService: NotificationsService,
    ) {
        super();
    }

    async process(job: Job<{ subscriptionId: string }>): Promise<any> {
        this.logger.log(`Processing subscription job ${job.id}: ${job.name}`);

        switch (job.name) {
            case 'renew-subscription':
                return this.handleRenewal(job.data.subscriptionId);
            default:
                this.logger.warn(`Unknown job name: ${job.name}`);
        }
    }

    private async handleRenewal(subscriptionId: string) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { id: subscriptionId },
            relations: ['user'],
        });

        if (!subscription) {
            this.logger.error(`Subscription ${subscriptionId} not found`);
            return;
        }

        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            this.logger.warn(`Subscription ${subscriptionId} is not active. Skipping renewal.`);
            return;
        }

        // Identify Plan Cost
        const plan = SUBSCRIPTION_PLANS.find(p => p.tier === subscription.tier);
        if (!plan) return;

        // Determine Amount (Monthly vs Yearly)
        const isYearly = subscription.billingPeriod === 'yearly';
        const amount = isYearly ? plan.priceKESYearly : plan.priceKES;

        if (amount <= 0) {
            // Free plan auto-renewal (just extend dates)
            this.extendSubscriptionDates(subscription, isYearly);
            await this.subscriptionRepository.save(subscription);
            return { status: 'renewed', type: 'free' };
        }

        // Check Wallet Balance
        const user = await this.userRepository.findOne({ where: { id: subscription.userId } });
        if (!user) return; // Should not happen

        if (Number(user.walletBalance) >= amount) {
            // SUCCESS: Deduct & Renew
            await this.userRepository.decrement({ id: user.id }, 'walletBalance', amount);

            this.extendSubscriptionDates(subscription, isYearly);
            await this.subscriptionRepository.save(subscription);

            // Record Payment
            await this.createPaymentRecord(subscription, amount, PaymentStatus.COMPLETED);

            this.logger.log(`Renewed subscription ${subscriptionId} for user ${user.id}`);
            await this.notifyUser(user.id, `Your ${plan.name} subscription has been successfully renewed.`, 'Subscription Renewed');

            return { status: 'renewed', amount };
        } else {
            // FAILURE: Insufficient Funds - DOWNGRADE TO FREE
            const now = new Date();

            // 1. Mark current paid subscription as EXPIRED
            subscription.status = SubscriptionStatus.EXPIRED;
            subscription.endDate = now;
            await this.subscriptionRepository.save(subscription);

            // 2. Downgrade User to FREE (Wait, SubscriptionTier vs UserTier mismatch)
            await this.userRepository.update({ id: user.id }, { tier: UserTier.FREE });

            // 3. Create new FREE Subscription
            const nextMonth = new Date(now);
            nextMonth.setMonth(nextMonth.getMonth() + 1);

            const freeSubscription = this.subscriptionRepository.create({
                userId: user.id,
                tier: SubscriptionTier.FREE,
                status: SubscriptionStatus.ACTIVE,
                startDate: now,
                billingPeriod: 'monthly',
                nextBillingDate: nextMonth,
                endDate: nextMonth,
            });
            await this.subscriptionRepository.save(freeSubscription);

            // Record Failed Payment (for visibility)
            await this.createPaymentRecord(subscription, amount, PaymentStatus.FAILED, 'Insufficient wallet balance - Downgraded to FREE');

            this.logger.warn(`Downgraded user ${user.id} to FREE due to failed renewal (Insufficient Funds)`);

            await this.notifyUser(
                user.id,
                `Subscription renewal failed due to insufficient funds. Your account has been downgraded to the Free tier.`,
                'Subscription Expired'
            );

            return { status: 'downgraded', reason: 'insufficient_funds' };
        }
    }

    private extendSubscriptionDates(subscription: Subscription, isYearly: boolean) {
        const now = new Date();
        // Ensure we extend from the *current* nextBillingDate if it's recent, otherwise use NOW to avoid "catching up" multiple periods instantly
        // For simplicity/robustness, we'll renew from NOW or nextBillingDate, whichever is appropriate. 
        // Ideally: newNextBillingDate = oldNextBillingDate + period.

        let baseDate = subscription.nextBillingDate && subscription.nextBillingDate > new Date(now.getTime() - 86400000 * 30)
            ? subscription.nextBillingDate
            : now;

        if (isYearly) {
            baseDate.setFullYear(baseDate.getFullYear() + 1);
        } else {
            baseDate.setMonth(baseDate.getMonth() + 1);
        }

        subscription.nextBillingDate = baseDate;
        subscription.endDate = baseDate; // Assuming access until next billing
    }

    private async createPaymentRecord(
        subscription: Subscription,
        amount: number,
        status: PaymentStatus,
        notes?: string
    ) {
        const now = new Date();
        const periodEnd = new Date(subscription.nextBillingDate);

        const payment = this.paymentRepository.create({
            subscription: subscription, // Use relation
            userId: subscription.userId,
            amount: amount,
            currency: 'KES',
            status: status,
            paymentMethod: PaymentMethod.WALLET,
            billingPeriod: subscription.billingPeriod || 'monthly',
            periodStart: now,
            periodEnd: periodEnd,
            dueDate: now,
            paidDate: status === PaymentStatus.COMPLETED ? now : undefined, // Use undefined for null/missing
            notes: notes,
            paymentProvider: 'INTERNAL_WALLET',
            metadata: {
                renewal: true,
                tier: subscription.tier
            }
        });
        return this.paymentRepository.save(payment);
    }

    private async notifyUser(userId: string, message: string, title: string) {
        const token = await this.deviceTokenRepository.findOne({
            where: { userId, isActive: true },
            order: { lastUsedAt: 'DESC' }
        });

        if (token?.token) {
            this.notificationsService.sendPaymentStatusNotification(
                token.token,
                'User', // placeholder name
                0,
                title === 'Subscription Renewed' ? 'SUCCESS' : 'FAILED',
                'SUBSCRIPTION'
            ).catch(e => this.logger.error('Failed to notify', e));
        }
    }
}
