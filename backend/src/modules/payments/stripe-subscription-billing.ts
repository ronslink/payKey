import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EntityManager, Repository } from 'typeorm';
import Stripe from 'stripe';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentMethod,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from '../subscriptions/subscription-plans.config';
import { User, UserTier } from '../users/entities/user.entity';

const idOf = (
  value: string | { id: string } | null | undefined,
): string | undefined => (typeof value === 'string' ? value : value?.id);

/** One invoice is one receipt, regardless of callback order or retries. */
export class StripeSubscriptionBilling {
  constructor(
    private readonly stripe: Stripe,
    private readonly subscriptions: Repository<Subscription>,
    private readonly payments: Repository<SubscriptionPayment>,
    private readonly config: ConfigService,
  ) {}

  returnUrl(result: 'success' | 'cancel', sessionId?: string): string {
    const base =
      this.config.get<string>('BILLING_FRONTEND_URL') ||
      this.config.get<string>('WEBSITE_URL') ||
      'https://paydome.co';
    const url = new URL(`/payments/subscriptions/${result}`, base);
    if (
      !['https:', 'http:'].includes(url.protocol) ||
      (this.config.get('NODE_ENV') === 'production' &&
        url.protocol !== 'https:')
    ) {
      throw new BadRequestException('A secure billing website URL is required');
    }
    if (sessionId) url.searchParams.set('session_id', sessionId);
    return url.toString();
  }

  private plan(tier: string, billingPeriod: string) {
    const plan = SUBSCRIPTION_PLANS.find(
      (entry) =>
        entry.tier === tier && ['BASIC', 'GOLD', 'PLATINUM'].includes(tier),
    );
    if (!plan || !['monthly', 'yearly'].includes(billingPeriod))
      throw new BadRequestException('Invalid paid subscription plan');
    return plan;
  }

  // Call while holding the account billing lock, before starting another provider.
  // A browser cancel redirect does not make an open Stripe session unpayable.
  async assertNoPayableCheckout(
    userId: string,
    email: string,
    storedCustomerId?: string,
  ): Promise<void> {
    const customerIds = new Set(storedCustomerId ? [storedCustomerId] : []);
    for await (const customer of this.stripe.customers.list({
      email,
      limit: 100,
    })) {
      customerIds.add(customer.id);
    }
    for (const customerId of customerIds) {
      for await (const session of this.stripe.checkout.sessions.list({
        customer: customerId,
        limit: 100,
      })) {
        if (await this.checkoutNeedsResolution(session, userId))
          throw new BadRequestException(
            'A card subscription checkout is still open or being confirmed. Finish that payment or wait for it to expire before starting another subscription payment.',
          );
      }
    }
  }

  private async checkoutNeedsResolution(
    session: Stripe.Checkout.Session,
    userId: string,
  ) {
    if (
      session.mode !== 'subscription' ||
      session.metadata?.userId !== userId ||
      session.status === 'expired'
    )
      return false;
    const subscriptionId = idOf(session.subscription);
    if (session.status === 'complete' && subscriptionId) {
      const contract = await this.stripe.subscriptions.retrieve(subscriptionId);
      return !['canceled', 'incomplete_expired'].includes(contract.status);
    }
    return true;
  }

  private async customerForCheckout(
    manager: EntityManager,
    userId: string,
    email: string,
    name?: string,
  ) {
    const account = await manager.findOne(User, { where: { id: userId } });
    if (account?.stripeCustomerId) return account.stripeCustomerId;
    const customers = await this.stripe.customers.list({ email, limit: 1 });
    const customer =
      customers.data[0] ||
      (await this.stripe.customers.create({
        email,
        name,
        metadata: { userId, source: 'PayKey' },
      }));
    // Commit the stable identity outside the enclosing checkout transaction.
    // An accepted-but-lost session response must not roll back this correlation.
    // The enclosing account lock still serializes all billing initiations.
    await this.subscriptions.manager.update(
      User,
      { id: userId },
      { stripeCustomerId: customer.id },
    );
    return customer.id;
  }

  async createCheckout(
    userId: string,
    tier: string,
    email: string,
    name?: string,
    billingPeriod: 'monthly' | 'yearly' = 'monthly',
  ) {
    const plan = this.plan(tier.toUpperCase(), billingPeriod);
    return this.subscriptions.manager.transaction(async (manager) => {
      await this.lock(manager, userId);
      const pendingPayment = await manager.findOne(SubscriptionPayment, {
        where: {
          userId,
          paymentProvider: 'INTASEND',
          status: PaymentStatus.PENDING,
        },
      });
      if (pendingPayment) {
        throw new BadRequestException(
          'An M-Pesa or bank subscription payment is still pending. Wait for its result before starting a card payment.',
        );
      }
      const current = await manager.findOne(Subscription, {
        where: { userId },
      });
      if (current?.stripeSubscriptionId) {
        const existing = await this.stripe.subscriptions.retrieve(
          current.stripeSubscriptionId,
        );
        if (!['canceled', 'incomplete_expired'].includes(existing.status)) {
          throw new BadRequestException(
            'A Stripe subscription already exists. Manage the existing subscription before starting another.',
          );
        }
      }
      const customerId = await this.customerForCheckout(
        manager,
        userId,
        email,
        name,
      );
      const sessions = await this.stripe.checkout.sessions.list({
        customer: customerId,
        limit: 100,
      });
      for (const session of sessions.data.filter(
        (entry) => entry.metadata?.userId === userId,
      )) {
        if (
          session.status === 'complete' &&
          session.payment_status === 'paid' &&
          idOf(session.subscription)
        ) {
          const existing = await this.stripe.subscriptions.retrieve(
            idOf(session.subscription)!,
          );
          if (!['canceled', 'incomplete_expired'].includes(existing.status)) {
            throw new BadRequestException(
              'Your payment is being confirmed. Check the existing checkout status.',
            );
          }
        }
        if (session.status === 'open') {
          if (
            session.metadata?.planTier === plan.tier &&
            session.metadata?.billingPeriod === billingPeriod &&
            session.url
          ) {
            return { sessionId: session.id, url: session.url };
          }
          await this.stripe.checkout.sessions.expire(session.id);
        }
      }
      const metadata = {
        userId,
        planTier: plan.tier,
        billingPeriod,
        source: 'PayKey',
      };
      const session = await this.stripe.checkout.sessions.create({
        customer: customerId,
        client_reference_id: userId,
        mode: 'subscription',
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: `${plan.name} Plan (${billingPeriod}) - Paydome`,
              },
              recurring: {
                interval: billingPeriod === 'yearly' ? 'year' : 'month',
              },
              unit_amount: Math.round(
                (billingPeriod === 'yearly'
                  ? plan.priceUSDYearly
                  : plan.priceUSD) * 100,
              ),
            },
            quantity: 1,
          },
        ],
        metadata,
        subscription_data: { metadata },
        success_url: `${this.returnUrl('success')}?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: this.returnUrl('cancel'),
      });
      if (!session.url)
        throw new BadRequestException('Stripe did not return a checkout URL');
      return { sessionId: session.id, url: session.url };
    });
  }

  async checkoutStatus(userId: string, sessionId: string) {
    if (!/^cs_[a-zA-Z0-9_]+$/.test(sessionId) || sessionId.length > 255)
      throw new NotFoundException('Checkout not found');
    const session = await this.stripe.checkout.sessions.retrieve(sessionId);
    if (session.mode !== 'subscription' || session.metadata?.userId !== userId)
      throw new NotFoundException('Checkout not found');
    const invoiceId = idOf(session.invoice);
    const stripeSubscriptionId = idOf(session.subscription);
    const [receipt, subscription] = await Promise.all([
      invoiceId
        ? this.payments.findOne({
            where: {
              userId,
              transactionId: invoiceId,
              status: PaymentStatus.COMPLETED,
            },
          })
        : null,
      stripeSubscriptionId
        ? this.subscriptions.findOne({
            where: { userId, stripeSubscriptionId },
          })
        : null,
    ]);
    const paymentStatus =
      session.payment_status === 'paid'
        ? 'paid'
        : session.status === 'expired'
          ? 'failed'
          : 'pending';
    return {
      paymentStatus,
      entitlementActive:
        paymentStatus === 'paid' &&
        !!receipt &&
        subscription?.status === SubscriptionStatus.ACTIVE &&
        String(subscription.tier) === session.metadata?.planTier &&
        !!subscription.nextBillingDate &&
        new Date(subscription.nextBillingDate).getTime() > Date.now(),
      tier: session.metadata?.planTier || null,
      billingPeriod: session.metadata?.billingPeriod || 'monthly',
    };
  }

  async checkoutCompleted(sessionId: string) {
    const session = await this.stripe.checkout.sessions.retrieve(sessionId);
    if (session.mode !== 'subscription' || session.payment_status !== 'paid')
      return;
    const invoiceId = idOf(session.invoice);
    if (!invoiceId)
      throw new BadRequestException(
        'Paid subscription checkout is missing its invoice',
      );
    await this.invoicePaid(invoiceId, session);
  }

  async invoicePaid(invoiceId: string, session?: Stripe.Checkout.Session) {
    const invoice = await this.stripe.invoices.retrieve(invoiceId);
    const stripeId = idOf(invoice.subscription);
    if (!stripeId || !invoice.paid || invoice.status !== 'paid') return;
    const provider = await this.stripe.subscriptions.retrieve(stripeId);
    const existing = await this.subscriptions.findOne({
      where: { stripeSubscriptionId: stripeId },
    });
    const userId =
      invoice.subscription_details?.metadata?.userId ||
      provider.metadata?.userId ||
      session?.metadata?.userId ||
      existing?.userId;
    const tier =
      invoice.subscription_details?.metadata?.planTier ||
      provider.metadata?.planTier ||
      session?.metadata?.planTier ||
      existing?.tier;
    const billingPeriod =
      invoice.subscription_details?.metadata?.billingPeriod ||
      provider.metadata?.billingPeriod ||
      session?.metadata?.billingPeriod ||
      existing?.billingPeriod ||
      'monthly';
    if (!userId || !tier)
      throw new BadRequestException('Subscription owner metadata is missing');
    this.plan(tier, billingPeriod);
    if (
      (session &&
        (session.metadata?.userId !== userId ||
          idOf(session.subscription) !== stripeId)) ||
      (existing && existing.userId !== userId)
    ) {
      throw new BadRequestException('Subscription ownership mismatch');
    }
    const line = invoice.lines.data.find(
      (entry) => entry.type === 'subscription' && !entry.proration,
    );
    const periodStart = new Date(
      (line?.period.start || invoice.period_start) * 1000,
    );
    const periodEnd = new Date((line?.period.end || invoice.period_end) * 1000);
    if (!(periodEnd > periodStart))
      throw new BadRequestException('Invalid invoice service period');

    await this.subscriptions.manager.transaction(async (manager) => {
      await this.lock(manager, userId);
      // A cancellation may have completed while this callback waited on the lock.
      const currentProvider =
        await this.stripe.subscriptions.retrieve(stripeId);
      let subscription = await manager.findOne(Subscription, {
        where: { stripeSubscriptionId: stripeId },
      });
      subscription ||= await manager.findOne(Subscription, {
        where: { userId },
      });
      if (
        subscription?.stripeSubscriptionId &&
        subscription.stripeSubscriptionId !== stripeId &&
        subscription.status === SubscriptionStatus.ACTIVE
      ) {
        throw new BadRequestException(
          'Another subscription is already active for this account',
        );
      }
      if (!subscription)
        subscription = manager.create(Subscription, {
          userId,
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.PENDING,
        });
      const sameStripeSubscription =
        subscription.stripeSubscriptionId === stripeId;
      if (sameStripeSubscription || currentProvider.status === 'active') {
        subscription.stripeSubscriptionId = stripeId;
      }
      const paymentIntentId = idOf(invoice.payment_intent);
      const receipt = await manager.findOne(SubscriptionPayment, {
        where: [
          { userId, transactionId: invoice.id },
          ...(paymentIntentId
            ? [{ userId, transactionId: paymentIntentId }]
            : []),
          ...(session
            ? [{ userId, invoiceNumber: `stripe_checkout_${session.id}` }]
            : []),
        ],
      });
      // The invoice ID also deduplicates invoices whose payment_intent is null.
      const alreadyRecorded =
        receipt?.status === PaymentStatus.COMPLETED &&
        receipt.transactionId === invoice.id;
      const active =
        currentProvider.status === 'active' &&
        idOf(currentProvider.latest_invoice) === invoice.id &&
        periodEnd.getTime() > Date.now() &&
        (!sameStripeSubscription ||
          !subscription.nextBillingDate ||
          periodEnd >= new Date(subscription.nextBillingDate));
      if (active) {
        subscription.tier = tier as SubscriptionTier;
        subscription.status = SubscriptionStatus.ACTIVE;
        subscription.startDate ||= periodStart;
        subscription.endDate = periodEnd;
        subscription.nextBillingDate = periodEnd;
        subscription.billingPeriod = billingPeriod;
        subscription.amount = (invoice.amount_paid || 0) / 100;
        subscription.lockedPrice = subscription.amount;
        subscription.currency = invoice.currency.toUpperCase();
        subscription.autoRenewal = !currentProvider.cancel_at_period_end;
        subscription.gracePeriodEndDate = null;
      }
      await manager.save(Subscription, subscription);
      const payment = manager.create(SubscriptionPayment, {
        ...(receipt || {}),
        subscriptionId: subscription.id,
        userId,
        amount: invoice.amount_paid / 100,
        currency: invoice.currency.toUpperCase(),
        status: PaymentStatus.COMPLETED,
        paymentMethod: PaymentMethod.STRIPE,
        billingPeriod,
        periodStart,
        periodEnd,
        dueDate: new Date((invoice.due_date || invoice.created) * 1000),
        paidDate: new Date(
          (invoice.status_transitions.paid_at || invoice.created) * 1000,
        ),
        invoiceNumber: invoice.number || invoice.id,
        paymentProvider: 'stripe',
        transactionId: invoice.id,
        metadata: {
          stripeInvoiceId: invoice.id,
          stripeSubscriptionId: stripeId,
          stripeSessionId: session?.id,
          planTier: tier,
        },
      });
      if (!alreadyRecorded) await manager.save(SubscriptionPayment, payment);
      if (active)
        await manager.update(User, { id: userId }, { tier: tier as UserTier });
    });
  }

  async invoiceFailed(invoiceId: string) {
    const invoice = await this.stripe.invoices.retrieve(invoiceId);
    if (invoice.paid) return this.invoicePaid(invoiceId);
    const stripeId = idOf(invoice.subscription);
    if (!stripeId) return;
    const existing = await this.subscriptions.findOne({
      where: { stripeSubscriptionId: stripeId },
    });
    if (!existing) return;
    await this.subscriptions.manager.transaction(async (manager) => {
      await this.lock(manager, existing.userId);
      const subscription = await manager.findOne(Subscription, {
        where: { id: existing.id },
      });
      if (!subscription || subscription.stripeSubscriptionId !== stripeId)
        return;
      const provider = await this.stripe.subscriptions.retrieve(stripeId);
      const receipt = await manager.findOne(SubscriptionPayment, {
        where: { userId: subscription.userId, transactionId: invoice.id },
      });
      if (receipt?.status === PaymentStatus.COMPLETED) return;
      await manager.save(
        SubscriptionPayment,
        manager.create(SubscriptionPayment, {
          ...(receipt || {}),
          subscriptionId: subscription.id,
          userId: subscription.userId,
          amount: invoice.amount_due / 100,
          currency: invoice.currency.toUpperCase(),
          status: PaymentStatus.FAILED,
          paymentMethod: PaymentMethod.STRIPE,
          billingPeriod: subscription.billingPeriod,
          periodStart: new Date(invoice.period_start * 1000),
          periodEnd: new Date(invoice.period_end * 1000),
          dueDate: new Date((invoice.due_date || invoice.created) * 1000),
          invoiceNumber: invoice.number || invoice.id,
          paymentProvider: 'stripe',
          transactionId: invoice.id,
          metadata: {
            stripeInvoiceId: invoice.id,
            stripeSubscriptionId: stripeId,
          },
        }),
      );
      if (
        idOf(provider.latest_invoice) === invoice.id &&
        provider.status !== 'active'
      ) {
        subscription.status = SubscriptionStatus.PAST_DUE;
        await manager.save(Subscription, subscription);
        await manager.update(
          User,
          { id: subscription.userId },
          { tier: UserTier.FREE },
        );
      }
    });
  }

  async subscriptionChanged(stripeId: string) {
    // Retrieve current state so late canceled/active callbacks cannot reverse a newer state.
    const existing = await this.subscriptions.findOne({
      where: { stripeSubscriptionId: stripeId },
    });
    if (!existing) return;
    const paidInvoiceId = await this.subscriptions.manager.transaction(
      async (manager) => {
        await this.lock(manager, existing.userId);
        const subscription = await manager.findOne(Subscription, {
          where: { id: existing.id },
        });
        if (!subscription || subscription.stripeSubscriptionId !== stripeId)
          return;
        const provider = await this.stripe.subscriptions.retrieve(stripeId);
        subscription.autoRenewal = !provider.cancel_at_period_end;
        if (
          [
            'canceled',
            'unpaid',
            'incomplete_expired',
            'paused',
            'past_due',
          ].includes(provider.status)
        ) {
          subscription.status =
            provider.status === 'canceled'
              ? SubscriptionStatus.CANCELLED
              : SubscriptionStatus.PAST_DUE;
          if (provider.status === 'canceled')
            subscription.endDate = new Date(
              (provider.ended_at ||
                provider.canceled_at ||
                Math.floor(Date.now() / 1000)) * 1000,
            );
          await manager.update(
            User,
            { id: subscription.userId },
            { tier: UserTier.FREE },
          );
        }
        // Only a verified paid invoice can grant or restore entitlement.
        await manager.save(Subscription, subscription);
        return provider.status === 'active'
          ? idOf(provider.latest_invoice)
          : undefined;
      },
    );
    if (paidInvoiceId) await this.invoicePaid(paidInvoiceId);
  }

  private lock(manager: EntityManager, userId: string) {
    return manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
      `stripe-billing:${userId}`,
    ]);
  }
}
