import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from './entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
  PaymentMethod,
} from './entities/subscription-payment.entity';
import { User } from '../users/entities/user.entity';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';
import {
  NotificationType,
  NotificationsService,
} from '../notifications/notifications.service';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { IntaSendService } from '../payments/intasend.service';
import {
  PaymentMethodType,
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../payments/entities/transaction.entity';

@Processor('subscriptions')
export class SubscriptionProcessor extends WorkerHost {
  private readonly logger = new Logger(SubscriptionProcessor.name);

  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private readonly paymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(DeviceToken)
    private readonly deviceTokenRepository: Repository<DeviceToken>,
    private readonly intaSendService: IntaSendService,
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

    if (
      subscription.status !== SubscriptionStatus.ACTIVE &&
      subscription.status !== SubscriptionStatus.PAST_DUE
    ) {
      this.logger.warn(
        `Subscription ${subscriptionId} is not active or past due. Skipping renewal.`,
      );
      return;
    }

    // Check for pending tier change (e.g. scheduled downgrade)
    if (subscription.pendingTier) {
      this.logger.log(
        `Applying pending tier change for Subscription ${subscriptionId}: ${subscription.tier} -> ${subscription.pendingTier}`,
      );
      subscription.tier = subscription.pendingTier;
      subscription.pendingTier = null;
      // Clear specific notes or add a record?
      // We just update the object. The save() call later (line 69 or 82) or explicit save here.
      // Since we might exit early (if plan not found), let's save now to be safe, or just trust flow.
      // Better to save logic state.
      await this.subscriptionRepository.save(subscription);

      // Note: We continue with the NEW tier.
    }

    // Identify Plan Cost
    const plan = SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier);
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

    const user = await this.userRepository.findOne({
      where: { id: subscription.userId },
    });
    if (!user) return; // Should not happen

    if (this.isGracePeriodExpired(subscription)) {
      return this.expireUnpaidRenewal(subscription, user, amount);
    }

    if (
      subscription.status === SubscriptionStatus.ACTIVE &&
      subscription.autoRenewal === false
    ) {
      return this.expireNonRenewingSubscription(subscription, user, amount);
    }

    const existingPendingRenewal = await this.findPendingRenewalPayment(
      subscription.id,
    );

    if (existingPendingRenewal) {
      this.logger.log(
        `Renewal payment ${existingPendingRenewal.id} already pending for subscription ${subscription.id}`,
      );
      return {
        status: 'awaiting_payment',
        paymentId: existingPendingRenewal.id,
        checkoutUrl: existingPendingRenewal.metadata?.checkoutUrl,
      };
    }

    const renewalRequest = await this.createIntaSendRenewalRequest(
      subscription,
      user,
      amount,
      isYearly,
    );

    this.logger.log(
      `Created IntaSend renewal payment ${renewalRequest.payment.id} for subscription ${subscription.id}`,
    );

    await this.notifyPaymentDue(
      user,
      amount,
      renewalRequest.checkoutUrl,
      renewalRequest.payment.dueDate,
    );

    return {
      status: 'awaiting_payment',
      amount,
      paymentId: renewalRequest.payment.id,
      checkoutUrl: renewalRequest.checkoutUrl,
    };
  }

  private extendSubscriptionDates(
    subscription: Subscription,
    isYearly: boolean,
  ) {
    const now = new Date();
    // Ensure we extend from the *current* nextBillingDate if it's recent, otherwise use NOW to avoid "catching up" multiple periods instantly
    // For simplicity/robustness, we'll renew from NOW or nextBillingDate, whichever is appropriate.
    // Ideally: newNextBillingDate = oldNextBillingDate + period.

    const baseDate =
      subscription.nextBillingDate &&
      subscription.nextBillingDate > new Date(now.getTime() - 86400000 * 30)
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
    notes?: string,
  ) {
    const now = new Date();
    const periodEnd = subscription.nextBillingDate
      ? new Date(subscription.nextBillingDate)
      : new Date();

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
        tier: subscription.tier,
      },
    });
    return this.paymentRepository.save(payment);
  }

  private async findPendingRenewalPayment(subscriptionId: string) {
    const pendingPayments = await this.paymentRepository.find({
      where: {
        subscriptionId,
        status: PaymentStatus.PENDING,
        paymentProvider: 'INTASEND',
      },
      order: { createdAt: 'DESC' },
      take: 5,
    });

    return pendingPayments.find((payment) => payment.metadata?.renewal);
  }

  private async createIntaSendRenewalRequest(
    subscription: Subscription,
    user: User,
    amount: number,
    isYearly: boolean,
  ) {
    const now = new Date();
    const periodStart = subscription.nextBillingDate
      ? new Date(subscription.nextBillingDate)
      : now;
    const periodEnd = this.calculatePeriodEnd(periodStart, isYearly);
    const reference = `SUB-RENEW-${subscription.userId}-${subscription.tier}-${subscription.billingPeriod}-${Date.now()}`;

    const checkoutResult = await this.intaSendService.createCheckoutUrl(
      amount,
      user.email,
      user.firstName || 'User',
      user.lastName || '',
      reference,
      undefined,
      { method: 'PESALINK', comment: 'Paydome subscription renewal' },
    );

    const payment = await this.paymentRepository.save(
      this.paymentRepository.create({
        subscriptionId: subscription.id,
        userId: subscription.userId,
        amount,
        currency: 'KES',
        status: PaymentStatus.PENDING,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        billingPeriod: subscription.billingPeriod || 'monthly',
        periodStart,
        periodEnd,
        dueDate: now,
        paymentProvider: 'INTASEND',
        transactionId: reference,
        metadata: {
          renewal: true,
          tier: subscription.tier,
          reference,
          checkoutUrl: checkoutResult.url,
        },
      }),
    );

    const checkoutProviderRef =
      checkoutResult.invoice?.invoice_id ||
      checkoutResult.invoice_id ||
      checkoutResult.id ||
      reference;

    await this.transactionRepository.save(
      this.transactionRepository.create({
        userId: subscription.userId,
        amount,
        currency: 'KES',
        type: TransactionType.SUBSCRIPTION,
        status: TransactionStatus.PENDING,
        provider: 'INTASEND',
        providerRef: checkoutProviderRef,
        paymentMethod: PaymentMethodType.PESALINK,
        accountReference: reference,
        metadata: {
          subscriptionPaymentId: payment.id,
          renewal: true,
          planId: subscription.tier,
          billingPeriod: subscription.billingPeriod,
          reference,
          checkoutProviderRef,
          checkoutUrl: checkoutResult.url,
        },
      }),
    );

    const gracePeriodEnd = new Date(now);
    gracePeriodEnd.setDate(gracePeriodEnd.getDate() + 7);
    subscription.status = SubscriptionStatus.PAST_DUE;
    subscription.gracePeriodEndDate = gracePeriodEnd;
    subscription.notes = subscription.notes
      ? `${subscription.notes}\nRenewal payment requested on ${now.toISOString()}`
      : `Renewal payment requested on ${now.toISOString()}`;
    await this.subscriptionRepository.save(subscription);

    return {
      payment,
      checkoutUrl: checkoutResult.url,
    };
  }

  private calculatePeriodEnd(periodStart: Date, isYearly: boolean) {
    const periodEnd = new Date(periodStart);
    if (isYearly) {
      periodEnd.setFullYear(periodEnd.getFullYear() + 1);
    } else {
      periodEnd.setMonth(periodEnd.getMonth() + 1);
    }
    return periodEnd;
  }

  private isGracePeriodExpired(subscription: Subscription) {
    return (
      subscription.status === SubscriptionStatus.PAST_DUE &&
      !!subscription.gracePeriodEndDate &&
      new Date(subscription.gracePeriodEndDate) <= new Date()
    );
  }

  private async expireUnpaidRenewal(
    subscription: Subscription,
    user: User,
    amount: number,
  ) {
    const now = new Date();
    subscription.status = SubscriptionStatus.EXPIRED;
    subscription.endDate = now;
    subscription.nextBillingDate = null;
    subscription.gracePeriodEndDate = null;
    subscription.notes = subscription.notes
      ? `${subscription.notes}\nSubscription expired for unpaid renewal on ${now.toISOString()}`
      : `Subscription expired for unpaid renewal on ${now.toISOString()}`;
    await this.subscriptionRepository.save(subscription);

    const nextMonth = new Date(now);
    nextMonth.setMonth(nextMonth.getMonth() + 1);

    await this.subscriptionRepository.save(
      this.subscriptionRepository.create({
        userId: user.id,
        tier: SubscriptionTier.FREE,
        status: SubscriptionStatus.ACTIVE,
        startDate: now,
        billingPeriod: 'monthly',
        nextBillingDate: nextMonth,
        endDate: nextMonth,
        autoRenewal: false,
      }),
    );

    await this.userRepository.update({ id: user.id }, { tier: 'FREE' as any });

    await this.paymentRepository.save(
      this.paymentRepository.create({
        subscriptionId: subscription.id,
        userId: subscription.userId,
        amount,
        currency: 'KES',
        status: PaymentStatus.FAILED,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        billingPeriod: subscription.billingPeriod || 'monthly',
        periodStart: now,
        periodEnd: now,
        dueDate: now,
        paymentProvider: 'INTASEND',
        paidDate: undefined,
        notes: 'Subscription expired after unpaid renewal grace period',
        metadata: {
          renewal: true,
          expiredAfterGrace: true,
          tier: subscription.tier,
        },
      }),
    );

    await this.notifyUser(
      user.id,
      'Subscription renewal was not completed. Your account has been moved to the Free tier.',
      'Subscription Expired',
    );

    return {
      status: 'downgraded',
      reason: 'renewal_unpaid_after_grace',
    };
  }

  private async expireNonRenewingSubscription(
    subscription: Subscription,
    user: User,
    amount: number,
  ) {
    const now = new Date();
    subscription.status = SubscriptionStatus.EXPIRED;
    subscription.endDate = now;
    subscription.nextBillingDate = null;
    subscription.gracePeriodEndDate = null;
    subscription.notes = subscription.notes
      ? `${subscription.notes}\nSubscription ended with auto-renewal disabled on ${now.toISOString()}`
      : `Subscription ended with auto-renewal disabled on ${now.toISOString()}`;
    await this.subscriptionRepository.save(subscription);

    const nextMonth = new Date(now);
    nextMonth.setMonth(nextMonth.getMonth() + 1);

    await this.subscriptionRepository.save(
      this.subscriptionRepository.create({
        userId: user.id,
        tier: SubscriptionTier.FREE,
        status: SubscriptionStatus.ACTIVE,
        startDate: now,
        billingPeriod: 'monthly',
        nextBillingDate: nextMonth,
        endDate: nextMonth,
        autoRenewal: false,
      }),
    );

    await this.userRepository.update({ id: user.id }, { tier: 'FREE' as any });

    await this.paymentRepository.save(
      this.paymentRepository.create({
        subscriptionId: subscription.id,
        userId: subscription.userId,
        amount,
        currency: 'KES',
        status: PaymentStatus.FAILED,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        billingPeriod: subscription.billingPeriod || 'monthly',
        periodStart: now,
        periodEnd: now,
        dueDate: now,
        paymentProvider: 'INTASEND',
        notes: 'Subscription ended because auto-renewal was disabled',
        metadata: {
          renewal: true,
          autoRenewalDisabled: true,
          tier: subscription.tier,
        },
      }),
    );

    await this.notifyUser(
      user.id,
      'Your subscription has ended because auto-renewal was disabled. Your account has been moved to the Free tier.',
      'Subscription Ended',
    );

    return {
      status: 'downgraded',
      reason: 'auto_renewal_disabled',
    };
  }

  private async notifyUser(userId: string, message: string, title: string) {
    const token = await this.deviceTokenRepository.findOne({
      where: { userId, isActive: true },
      order: { lastUsedAt: 'DESC' },
    });

    if (token?.token) {
      this.notificationsService
        .sendPaymentStatusNotification(
          token.token,
          'User', // placeholder name
          0,
          title === 'Subscription Renewed' ? 'SUCCESS' : 'FAILED',
          'SUBSCRIPTION',
        )
        .catch((e) => this.logger.error('Failed to notify', e));
    }
  }

  private async notifyPaymentDue(
    user: User,
    amount: number,
    checkoutUrl: string,
    dueDate?: Date,
  ) {
    const token = await this.deviceTokenRepository.findOne({
      where: { userId: user.id, isActive: true },
      order: { lastUsedAt: 'DESC' },
    });

    if (token?.token) {
      this.notificationsService
        .sendSubscriptionPaymentDueNotification(
          token.token,
          amount,
          checkoutUrl,
          dueDate,
        )
        .catch((e) => this.logger.error('Failed to notify payment due', e));
    }

    if (user.email) {
      this.notificationsService
        .sendNotification({
          recipientEmail: user.email,
          subject: 'PayDome subscription payment due',
          message:
            `Your PayDome subscription renewal payment of KES ${amount.toFixed(0)} is due.` +
            ` Pay securely here: ${checkoutUrl}`,
          type: NotificationType.EMAIL,
          priority: 'HIGH',
          metadata: {
            type: 'SUBSCRIPTION_PAYMENT_DUE',
            amount,
            checkoutUrl,
            dueDate: dueDate ? new Date(dueDate).toISOString() : undefined,
          },
        })
        .catch((e) =>
          this.logger.error('Failed to send renewal payment email', e),
        );
    }
  }
}
