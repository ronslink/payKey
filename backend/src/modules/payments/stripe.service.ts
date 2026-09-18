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
} from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
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
import { StripeSubscriptionBilling } from './stripe-subscription-billing';

@Injectable()
export class StripeService {
  private readonly logger = new Logger(StripeService.name);
  private stripe: Stripe | null = null;

  constructor(
    private readonly configService: ConfigService,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private readonly paymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    private readonly exchangeRateService: ExchangeRateService,
    private readonly notificationsService: NotificationsService,
    @InjectRepository(DeviceToken)
    private readonly deviceTokenRepository: Repository<DeviceToken>,
    private readonly systemConfigService: SystemConfigService,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (this.configService.get('NODE_ENV') === 'production') {
      if (!secretKey || !/^(sk|rk)_live_/.test(secretKey)) {
        throw new Error(
          'Production paid subscriptions require a live Stripe API key',
        );
      }
      if (
        !this.configService
          .get<string>('STRIPE_WEBHOOK_SECRET')
          ?.startsWith('whsec_')
      ) {
        throw new Error(
          'Production paid subscriptions require a Stripe webhook signing secret',
        );
      }
    }
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
    _successUrl?: string,
    _cancelUrl?: string,
  ): Promise<{ sessionId: string; url: string }> {
    // Retain legacy positional arguments while using only the server return URL.
    void _successUrl;
    void _cancelUrl;
    return this.billing().createCheckout(
      userId,
      planTier,
      customerEmail,
      customerName,
      billingPeriod,
    );
  }

  private billing(): StripeSubscriptionBilling {
    return new StripeSubscriptionBilling(
      this.ensureStripeConfigured(),
      this.subscriptionRepository,
      this.paymentRepository,
      this.configService,
    );
  }

  getCheckoutStatus(userId: string, sessionId: string) {
    return this.billing().checkoutStatus(userId, sessionId);
  }

  billingReturnUrl(result: 'success' | 'cancel', sessionId?: string) {
    return this.billing().returnUrl(result, sessionId);
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

  /**
   * Handle Stripe webhook events
   */
  async handleWebhook(event: Stripe.Event): Promise<void> {
    this.ensureStripeConfigured();
    this.logger.log(`Processing Stripe webhook: ${event.type}`);

    try {
      switch (event.type) {
        case 'checkout.session.completed':
        case 'checkout.session.async_payment_succeeded':
          await this.handleCheckoutCompleted(event.data.object);
          break;
        case 'payment_intent.succeeded':
          await this.handlePaymentIntentSucceeded(event.data.object);
          break;
        case 'invoice.payment_succeeded':
        case 'invoice.paid':
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
    await this.billing().checkoutCompleted(session.id);
  }

  private async handlePaymentSucceeded(invoice: Stripe.Invoice): Promise<void> {
    await this.billing().invoicePaid(invoice.id);
  }

  private async handlePaymentFailed(invoice: Stripe.Invoice): Promise<void> {
    await this.billing().invoiceFailed(invoice.id);
  }

  private async handleSubscriptionCancelled(
    subscription: Stripe.Subscription,
  ): Promise<void> {
    await this.billing().subscriptionChanged(subscription.id);
  }

  private async handleSubscriptionUpdated(
    subscription: Stripe.Subscription,
  ): Promise<void> {
    await this.billing().subscriptionChanged(subscription.id);
  }

  async setCancelAtPeriodEnd(
    userId: string,
    cancelAtPeriodEnd: boolean,
  ): Promise<Subscription> {
    const stripe = this.ensureStripeConfigured();

    const subscription = await this.subscriptionRepository.findOne({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });

    if (!subscription?.stripeSubscriptionId) {
      throw new NotFoundException('Active Stripe subscription not found');
    }

    const stripeSubscription = await stripe.subscriptions.update(
      subscription.stripeSubscriptionId,
      {
        cancel_at_period_end: cancelAtPeriodEnd,
      },
    );

    subscription.autoRenewal = !stripeSubscription.cancel_at_period_end;
    subscription.endDate = stripeSubscription.cancel_at_period_end
      ? new Date(stripeSubscription.current_period_end * 1000)
      : null;
    await this.subscriptionRepository.save(subscription);

    return subscription;
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

      await this.billing().subscriptionChanged(
        subscription.stripeSubscriptionId,
      );

      this.logger.log(`Subscription cancelled for user ${userId}`);
    } catch (error) {
      this.logger.error('Failed to cancel subscription', error);
      throw new BadRequestException('Failed to cancel subscription');
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

    const amountToCredit = await this.transactionRepository.manager.transaction(
      async (manager) => {
        const transaction = await manager.findOne(Transaction, {
          where: { id: transactionId },
          lock: { mode: 'pessimistic_write' },
        });
        if (!transaction) {
          this.logger.error(
            `Transaction not found for PI: ${paymentIntent.id}`,
          );
          return undefined;
        }

        if (transaction.status === TransactionStatus.SUCCESS) {
          this.logger.log(`Transaction ${transactionId} already processed`);
          return undefined;
        }

        // Update Transaction
        transaction.status = TransactionStatus.SUCCESS;
        transaction.providerRef = paymentIntent.id;
        // transaction.updatedAt = new Date(); // Not in entity
        await manager.save(Transaction, transaction);

        // Credit Wallet
        // Stripe charges are in cents, so we use amount/100
        const amountReceivedEur = paymentIntent.amount_received / 100;

        let amount = amountReceivedEur;
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
            amount = this.roundCurrency(amountReceivedEur * appliedRate);
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
            creditedAmount: amount,
          },
        };
        await manager.save(Transaction, transaction);

        await manager.increment(User, { id: userId }, 'walletBalance', amount);

        this.logger.log(
          `Wallet credited for user ${userId}: ${amount} KES (Rate: ${appliedRate}, Source: ${amountReceivedEur} EUR)`,
        );

        return amount;
      },
    );

    if (amountToCredit !== undefined) {
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
