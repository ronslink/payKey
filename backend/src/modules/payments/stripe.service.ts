import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
  PaymentMethod,
} from '../subscriptions/entities/subscription-payment.entity';
import { User } from '../users/entities/user.entity';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from './entities/transaction.entity';
import { ExchangeRateService } from './exchange-rate.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { SystemConfigService } from '../system-config/system-config.service';

@Injectable()
export class StripeService {
  private readonly logger = new Logger(StripeService.name);
  private stripe: Stripe | null = null;

  constructor(
    private configService: ConfigService,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private paymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    private exchangeRateService: ExchangeRateService,
    private notificationsService: NotificationsService,
    @InjectRepository(DeviceToken)
    private deviceTokenRepository: Repository<DeviceToken>,
    private systemConfigService: SystemConfigService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey) {
      this.logger.warn('Stripe secret key not configured');
    } else {
      this.stripe = new Stripe(secretKey, { apiVersion: '2024-06-20' });
    }
  }

  private ensureStripeConfigured(): Stripe {
    if (!this.stripe) {
      throw new BadRequestException('Stripe not configured');
    }
    return this.stripe;
  }

  /**
   * Construct and verify a Stripe webhook event from raw payload
   */
  constructEvent(payload: Buffer, signature: string): Stripe.Event {
    const stripe = this.ensureStripeConfigured();
    const webhookSecret = this.configService.get<string>(
      'STRIPE_WEBHOOK_SECRET',
    );
    if (!webhookSecret) {
      throw new BadRequestException('Stripe webhook secret not configured');
    }
    return stripe.webhooks.constructEvent(payload, signature, webhookSecret);
  }

  /**
   * Create Stripe customer for user
   */
  async createCustomer(email: string, name?: string): Promise<Stripe.Customer> {
    const stripe = this.ensureStripeConfigured();

    return await stripe.customers.create({
      email,
      name,
      metadata: {
        source: 'PayKey Payroll System',
      },
    });
  }

  /**
   * Create subscription checkout session
   */
  async createCheckoutSession(
    userId: string,
    planTier: string,
    customerEmail: string,
    customerName?: string,
    billingPeriod: 'monthly' | 'yearly' = 'monthly',
    successUrl?: string,
    cancelUrl?: string,
  ): Promise<{ sessionId: string; url: string }> {
    const stripe = this.ensureStripeConfigured();

    const normalizedTier = planTier.toUpperCase();
    if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(normalizedTier)) {
      throw new BadRequestException('Invalid subscription plan');
    }

    try {
      // Create or get customer
      const customers = await stripe.customers.list({
        email: customerEmail,
        limit: 1,
      });
      let customer = customers.data[0];

      if (!customer) {
        customer = await this.createCustomer(customerEmail, customerName);
      }

      const frontendUrl =
        (await this.systemConfigService.get('FRONTEND_URL')) ||
        this.configService.get<string>('FRONTEND_URL');

      if (!frontendUrl) {
        throw new BadRequestException(
          'System configuration error: FRONTEND_URL not set',
        );
      }

      const session = await stripe.checkout.sessions.create({
        customer: customer.id,
        mode: 'subscription',
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: `${planTier.toUpperCase()} Plan (${billingPeriod}) - PayKey Payroll`,
                description: `${billingPeriod === 'monthly' ? 'Monthly' : 'Yearly'} subscription for ${planTier} plan`,
              },
              recurring: {
                interval: billingPeriod === 'yearly' ? 'year' : 'month',
              },
              unit_amount: this.getPlanPrice(normalizedTier, billingPeriod), // Convert to cents
            },
            quantity: 1,
          },
        ],
        metadata: {
          userId,
          planTier: normalizedTier,
          billingPeriod,
          source: 'PayKey',
        },
        success_url:
          successUrl ||
          `${frontendUrl}/payments/subscriptions/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: cancelUrl || `${frontendUrl}/payments/subscriptions/cancel`,
        allow_promotion_codes: true,
      });

      return {
        sessionId: session.id,
        url: session.url || '',
      };
    } catch (error) {
      this.logger.error('Failed to create checkout session', error);
      throw new BadRequestException('Failed to create checkout session');
    }
  }

  /**
   * Create Payment Intent for Wallet Top Up (SEPA/Card)
   */
  async createPaymentIntent(
    userId: string,
    amount: number,
    currency: string = 'eur',
    paymentMethodTypes: string[] = ['card', 'sepa_debit'],
  ): Promise<{ clientSecret: string; transactionId: string }> {
    const stripe = this.ensureStripeConfigured();

    // Create pending transaction
    const transaction = this.transactionRepository.create({
      userId,
      amount,
      currency: currency.toUpperCase(),
      type: TransactionType.DEPOSIT,
      status: TransactionStatus.PENDING,
      provider: 'STRIPE',
      metadata: {
        description: 'Wallet Top Up via Stripe',
        initiatedAt: new Date().toISOString(),
      },
    });
    await this.transactionRepository.save(transaction);

    // Create PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency.toLowerCase(),
      payment_method_types: paymentMethodTypes,
      metadata: {
        userId,
        transactionId: transaction.id,
        type: 'WALLET_TOPUP',
      },
    });

    // Update transaction with PI ID
    transaction.providerRef = paymentIntent.id;
    await this.transactionRepository.save(transaction);

    if (!paymentIntent.client_secret) {
      throw new BadRequestException('Failed to generate client secret');
    }

    return {
      clientSecret: paymentIntent.client_secret,
      transactionId: transaction.id,
    };
  }

  private getPlanPrice(
    planTier: string,
    billingPeriod: 'monthly' | 'yearly' = 'monthly',
  ): number {
    const monthlyPrices: Record<string, number> = {
      FREE: 0,
      BASIC: 999, // $9.99
      GOLD: 2999, // $29.99
      PLATINUM: 4999, // $49.99
    };

    // Yearly prices (approx 10x monthly)
    const yearlyPrices: Record<string, number> = {
      FREE: 0,
      BASIC: 9999, // $99.99
      GOLD: 29999, // $299.99
      PLATINUM: 49999, // $499.99
    };

    return billingPeriod === 'yearly'
      ? yearlyPrices[planTier] || yearlyPrices.BASIC
      : monthlyPrices[planTier] || monthlyPrices.BASIC;
  }

  /**
   * Upgrade an existing Stripe subscription with proration
   * Stripe automatically prorates the charge when switching plans
   */
  async upgradeSubscription(
    userId: string,
    newPlanTier: string,
  ): Promise<{
    success: boolean;
    message: string;
    subscriptionId?: string;
    prorationAmount?: number;
  }> {
    const stripe = this.ensureStripeConfigured();
    const normalizedTier = newPlanTier.toUpperCase();

    // Get current subscription
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });

    if (!subscription || !subscription.stripeSubscriptionId) {
      return {
        success: false,
        message:
          'No active Stripe subscription found. Please use checkout instead.',
      };
    }

    try {
      // Fetch the Stripe subscription
      const stripeSubscription = await stripe.subscriptions.retrieve(
        subscription.stripeSubscriptionId,
      );

      if (!stripeSubscription || stripeSubscription.status !== 'active') {
        return {
          success: false,
          message: 'Stripe subscription is not active',
        };
      }

      // Get the current subscription item
      const subscriptionItem = stripeSubscription.items.data[0];
      if (!subscriptionItem) {
        return {
          success: false,
          message: 'Could not find subscription item to upgrade',
        };
      }

      // Create a new price for the upgraded plan
      const newPrice = await stripe.prices.create({
        currency: 'usd',
        product_data: {
          name: `${normalizedTier} Plan - PayKey Payroll`,
        },
        recurring: { interval: 'month' },
        unit_amount: this.getPlanPrice(normalizedTier),
      });

      // Update the subscription with proration
      const updatedStripeSubscription = await stripe.subscriptions.update(
        subscription.stripeSubscriptionId,
        {
          items: [
            {
              id: subscriptionItem.id,
              price: newPrice.id,
            },
          ],
          proration_behavior: 'create_prorations',
          metadata: {
            planTier: normalizedTier,
            upgradedAt: new Date().toISOString(),
          },
        },
      );

      // Get the latest invoice to see proration amount
      const invoices = await stripe.invoices.list({
        subscription: subscription.stripeSubscriptionId,
        limit: 1,
      });
      const latestInvoice = invoices.data[0];

      // Update local subscription record
      subscription.tier = normalizedTier as SubscriptionTier;
      subscription.updatedAt = new Date();
      await this.subscriptionRepository.save(subscription);

      this.logger.log(
        `Upgraded Stripe subscription for user ${userId} to ${normalizedTier}`,
      );

      return {
        success: true,
        message: `Successfully upgraded to ${normalizedTier} plan. Proration applied.`,
        subscriptionId: updatedStripeSubscription.id,
        prorationAmount: latestInvoice
          ? (latestInvoice.amount_due || 0) / 100
          : undefined,
      };
    } catch (error) {
      this.logger.error('Failed to upgrade Stripe subscription', error);
      return {
        success: false,
        message: `Failed to upgrade: ${error.message}`,
      };
    }
  }

  /**
   * Handle Stripe webhook events
   */
  async handleWebhook(event: Stripe.Event): Promise<void> {
    this.ensureStripeConfigured();
    this.logger.log(`Processing Stripe webhook: ${event.type}`);

    try {
      switch (event.type) {
        case 'checkout.session.completed':
          await this.handleCheckoutCompleted(event.data.object);
          break;
        case 'payment_intent.succeeded':
          await this.handlePaymentIntentSucceeded(event.data.object);
          break;
        case 'invoice.payment_succeeded':
          await this.handlePaymentSucceeded(event.data.object);
          break;
        case 'invoice.payment_failed':
          await this.handlePaymentFailed(event.data.object);
          break;
        case 'customer.subscription.deleted':
          await this.handleSubscriptionCancelled(event.data.object);
          break;
        case 'customer.subscription.updated':
          await this.handleSubscriptionUpdated(event.data.object);
          break;
        default:
          this.logger.log(`Unhandled event type: ${event.type}`);
      }
    } catch (error) {
      this.logger.error(`Error handling webhook ${event.type}`, error);
      throw error;
    }
  }

  /**
   * Handle successful checkout completion
   */
  private async handleCheckoutCompleted(
    session: Stripe.Checkout.Session,
  ): Promise<void> {
    const metadata = session.metadata || {};
    const userId = metadata.userId;
    const planTier = metadata.planTier;

    if (!userId || !planTier) {
      this.logger.error('Missing metadata in checkout session');
      return;
    }

    // Update or create subscription
    let subscription = await this.subscriptionRepository.findOne({
      where: { userId },
    });

    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        userId,
        tier: planTier as SubscriptionTier,
        status: SubscriptionStatus.ACTIVE,
        startDate: new Date(),
        stripeSubscriptionId: session.subscription as string,
      });
    } else {
      subscription.tier = planTier as SubscriptionTier;
      subscription.status = SubscriptionStatus.ACTIVE;
      subscription.startDate = new Date();
      subscription.stripeSubscriptionId = session.subscription as string;
    }

    await this.subscriptionRepository.save(subscription);

    // Sync tier to User entity
    // We need to inject UsersRepository or use QueryBuilder to update the user table directly
    await this.subscriptionRepository.manager.update(
      'users',
      { id: userId },
      { tier: planTier },
    );

    // Create payment record for this checkout (amount_total is in cents)
    const amountPaid = (session.amount_total || 0) / 100;
    if (amountPaid > 0) {
      const now = new Date();
      const periodEnd = new Date(now);
      periodEnd.setMonth(periodEnd.getMonth() + 1);
      const payment = this.paymentRepository.create({
        subscriptionId: subscription.id,
        userId,
        amount: amountPaid,
        currency: (session.currency || 'usd').toUpperCase(),
        status: PaymentStatus.COMPLETED,
        paymentMethod: PaymentMethod.STRIPE,
        billingPeriod: metadata.billingPeriod || 'monthly',
        periodStart: now,
        periodEnd,
        dueDate: now,
        paidDate: now,
        invoiceNumber: `stripe_checkout_${session.id}`,
        paymentProvider: 'stripe',
        transactionId: session.payment_intent as string || session.id,
        metadata: {
          stripeSessionId: session.id,
          stripeSubscriptionId: session.subscription,
          planTier,
        },
      });
      await this.paymentRepository.save(payment);
    }

    this.logger.log(
      `Subscription activated for user ${userId} with plan ${planTier}`,
    );
  }

  /**
   * Handle successful payment
   */
  private async handlePaymentSucceeded(invoice: Stripe.Invoice): Promise<void> {
    if (!invoice.subscription) return;

    // Find subscription by Stripe ID
    const subscription = await this.subscriptionRepository.findOne({
      where: { stripeSubscriptionId: invoice.subscription as string },
    });

    if (!subscription) {
      this.logger.error(
        `Subscription not found for Stripe ID: ${invoice.subscription}`,
      );
      return;
    }

    // Create payment record
    const payment = this.paymentRepository.create({
      subscriptionId: subscription.id,
      userId: subscription.userId,
      amount: (invoice.amount_paid || 0) / 100, // Convert from cents
      currency: invoice.currency.toUpperCase(),
      status: PaymentStatus.COMPLETED,
      paymentMethod: PaymentMethod.STRIPE,
      billingPeriod: 'monthly',
      periodStart: new Date(invoice.period_start * 1000),
      periodEnd: new Date(invoice.period_end * 1000),
      dueDate: new Date((invoice.due_date || Date.now()) * 1000),
      paidDate: new Date(),
      invoiceNumber: invoice.number || `inv_${invoice.id}`,
      paymentProvider: 'stripe',
      transactionId: invoice.payment_intent as string,
      metadata: {
        stripeInvoiceId: invoice.id,
        stripeSubscriptionId: invoice.subscription,
      },
    });

    await this.paymentRepository.save(payment);
    this.logger.log(`Payment recorded for subscription ${subscription.id}`);
  }

  /**
   * Handle failed payment
   */
  private async handlePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
    if (!invoice.subscription) return;

    const subscription = await this.subscriptionRepository.findOne({
      where: { stripeSubscriptionId: invoice.subscription as string },
    });

    if (subscription) {
      // Create failed payment record
      const payment = this.paymentRepository.create({
        subscriptionId: subscription.id,
        userId: subscription.userId,
        amount: (invoice.amount_due || 0) / 100,
        currency: invoice.currency.toUpperCase(),
        status: PaymentStatus.FAILED,
        paymentMethod: PaymentMethod.STRIPE,
        billingPeriod: 'monthly',
        periodStart: new Date(invoice.period_start * 1000),
        periodEnd: new Date(invoice.period_end * 1000),
        dueDate: new Date((invoice.due_date || Date.now()) * 1000),
        invoiceNumber: invoice.number || `inv_${invoice.id}`,
        paymentProvider: 'stripe',
        transactionId: invoice.payment_intent as string,
        metadata: {
          stripeInvoiceId: invoice.id,
          error: invoice.last_finalization_error?.message,
        },
      });

      await this.paymentRepository.save(payment);

      // Update subscription status if needed
      if (invoice.attempt_count > 3) {
        subscription.status = SubscriptionStatus.PAST_DUE;
        await this.subscriptionRepository.save(subscription);
      }
    }
  }

  /**
   * Handle subscription cancellation
   */
  private async handleSubscriptionCancelled(
    stripeSubscription: Stripe.Subscription,
  ): Promise<void> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { stripeSubscriptionId: stripeSubscription.id },
    });

    if (subscription) {
      subscription.status = SubscriptionStatus.CANCELLED;
      subscription.endDate = new Date();
      await this.subscriptionRepository.save(subscription);
      this.logger.log(`Subscription cancelled for user ${subscription.userId}`);
    }
  }

  /**
   * Handle subscription updates
   */
  private async handleSubscriptionUpdated(
    stripeSubscription: Stripe.Subscription,
  ): Promise<void> {
    const subscription = await this.subscriptionRepository.findOne({
      where: { stripeSubscriptionId: stripeSubscription.id },
    });

    if (subscription) {
      // Update status based on Stripe subscription status
      switch (stripeSubscription.status) {
        case 'active':
          subscription.status = SubscriptionStatus.ACTIVE;
          break;
        case 'past_due':
          subscription.status = SubscriptionStatus.PAST_DUE;
          break;
        case 'canceled':
          subscription.status = SubscriptionStatus.CANCELLED;
          subscription.endDate = new Date();
          break;
        case 'unpaid':
          subscription.status = SubscriptionStatus.PAST_DUE;
          break;
      }

      await this.subscriptionRepository.save(subscription);
    }
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(userId: string): Promise<void> {
    const stripe = this.ensureStripeConfigured();

    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });

    if (!subscription || !subscription.stripeSubscriptionId) {
      throw new NotFoundException('Active subscription not found');
    }

    try {
      await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);

      subscription.status = SubscriptionStatus.CANCELLED;
      subscription.endDate = new Date();
      await this.subscriptionRepository.save(subscription);

      this.logger.log(`Subscription cancelled for user ${userId}`);
    } catch (error) {
      this.logger.error('Failed to cancel subscription', error);
      throw new BadRequestException('Failed to cancel subscription');
    }
  }

  /**
   * Update subscription
   */
  async updateSubscription(userId: string, newPlanTier: string): Promise<void> {
    const stripe = this.ensureStripeConfigured();

    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });

    if (!subscription || !subscription.stripeSubscriptionId) {
      throw new NotFoundException('Active subscription not found');
    }

    const normalizedTier = newPlanTier.toUpperCase();
    if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(normalizedTier)) {
      throw new BadRequestException('Invalid subscription plan');
    }

    try {
      // In a real implementation, you'd need to get the current subscription items
      // and update them with the new price. For simplicity, we'll cancel and create new

      // Cancel current subscription
      await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);

      // Create new subscription with updated plan
      // This is simplified - in production, you'd use subscription modification
      subscription.tier = normalizedTier as SubscriptionTier;
      subscription.status = SubscriptionStatus.ACTIVE;
      subscription.startDate = new Date();

      await this.subscriptionRepository.save(subscription);

      // Sync tier to User entity
      await this.subscriptionRepository.manager.update(
        'users',
        { id: userId },
        { tier: normalizedTier },
      );

      this.logger.log(
        `Subscription updated for user ${userId} to ${normalizedTier}`,
      );
    } catch (error) {
      this.logger.error('Failed to update subscription', error);
      throw new BadRequestException('Failed to update subscription');
    }
  }

  /**
   * Get Stripe account information
   */
  async getAccountInfo(): Promise<any> {
    if (!this.stripe) {
      return {
        connected: false,
        message: 'Stripe not configured',
      };
    }

    try {
      const account = await this.stripe.accounts.retrieve();
      return {
        connected: true,
        id: account.id,
        charges_enabled: account.charges_enabled,
        payouts_enabled: account.payouts_enabled,
        details_submitted: account.details_submitted,
      };
    } catch (error) {
      this.logger.error('Failed to get Stripe account info', error);
      return {
        connected: false,
        message: 'Failed to retrieve account information',
      };
    }
  }

  /**
   * Handle Payment Intent Succeeded (Wallet Top Up)
   */
  private async handlePaymentIntentSucceeded(
    paymentIntent: Stripe.PaymentIntent,
  ): Promise<void> {
    const { userId, transactionId, type } = paymentIntent.metadata;

    if (type !== 'WALLET_TOPUP' || !transactionId) {
      return; // Ignore non-wallet payments
    }

    const transaction = await this.transactionRepository.findOne({
      where: { id: transactionId },
    });
    if (!transaction) {
      this.logger.error(`Transaction not found for PI: ${paymentIntent.id}`);
      return;
    }

    if (transaction.status === TransactionStatus.SUCCESS) {
      this.logger.log(`Transaction ${transactionId} already processed`);
      return;
    }

    // Update Transaction
    transaction.status = TransactionStatus.SUCCESS;
    transaction.providerRef = paymentIntent.id;
    // transaction.updatedAt = new Date(); // Not in entity
    await this.transactionRepository.save(transaction);

    // Credit Wallet
    // Stripe charges are in cents, so we use amount/100
    const amountReceivedEur = paymentIntent.amount_received / 100;

    let amountToCredit = amountReceivedEur;
    let appliedRate = 1;
    let targetCurrency = 'EUR';

    // FX Conversion (EUR -> KES)
    if (transaction.currency !== 'KES' && transaction.currency !== 'USD') {
      targetCurrency = 'KES';
      try {
        // Fetch latest periodic rate (Cached/DB)
        appliedRate = await this.exchangeRateService.getLatestRate(
          'EUR',
          'KES',
        );
        amountToCredit = this.roundCurrency(amountReceivedEur * appliedRate);
      } catch (e) {
        this.logger.error(
          'FX Conversion Failed. Using 1:1 Fallback (Manual Review Required)',
          e,
        );
        // Fallback is 1:1, effectively freezing real value transfer until resolved
      }
    }

    // Update Transaction Metadata
    transaction.metadata = {
      ...transaction.metadata,
      fxApplied: {
        sourceAmount: amountReceivedEur,
        sourceCurrency: 'EUR',
        targetCurrency,
        rate: appliedRate,
        creditedAmount: amountToCredit,
      },
    };
    await this.transactionRepository.save(transaction);

    await this.userRepository.increment(
      { id: userId },
      'walletBalance',
      amountToCredit,
    );

    this.logger.log(
      `Wallet credited for user ${userId}: ${amountToCredit} KES (Rate: ${appliedRate}, Source: ${amountReceivedEur} EUR)`,
    );

    // Send Push Notification
    try {
      const deviceToken = await this.deviceTokenRepository.findOne({
        where: { userId, isActive: true },
        order: { lastUsedAt: 'DESC' },
      });

      if (deviceToken?.token) {
        await this.notificationsService.sendPaymentStatusNotification(
          deviceToken.token,
          'Wallet', // "Worker Name" context used as "Wallet" for topups
          amountToCredit,
          'SUCCESS',
          'TOPUP',
        );
      }
    } catch (e) {
      this.logger.error('Failed to send Top-Up Notification', e);
    }
  }

  private roundCurrency(amount: number): number {
    return Math.round(amount * 100) / 100;
  }

  /**
   * Create a Stripe refund for a payment intent
   */
  async createRefund(
    paymentIntentId: string,
    amount: number,
  ): Promise<Stripe.Refund> {
    const stripe = this.ensureStripeConfigured();
    return stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: Math.round(amount * 100), // Convert to cents
    });
  }
}
