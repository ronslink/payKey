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

      const session = await stripe.checkout.sessions.create({
        customer: customer.id,
        mode: 'subscription',
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: `${planTier.toUpperCase()} Plan - PayKey Payroll`,
                description: `Monthly subscription for ${planTier} plan`,
              },
              recurring: {
                interval: 'month',
              },
              unit_amount: this.getPlanPrice(normalizedTier), // Convert to cents
            },
            quantity: 1,
          },
        ],
        metadata: {
          userId,
          planTier: normalizedTier,
          source: 'PayKey',
        },
        success_url:
          successUrl ||
          `${this.configService.get<string>('FRONTEND_URL')}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url:
          cancelUrl ||
          `${this.configService.get<string>('FRONTEND_URL')}/subscription/cancel`,
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

  private getPlanPrice(planTier: string): number {
    const prices: Record<string, number> = {
      FREE: 0,
      BASIC: 999, // $9.99
      GOLD: 2999,  // $29.99
      PLATINUM: 4999, // $49.99
    };
    return prices[planTier] || prices.BASIC;
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
          await this.handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
          break;
        case 'invoice.payment_succeeded':
          await this.handlePaymentSucceeded(event.data.object as Stripe.Invoice);
          break;
        case 'invoice.payment_failed':
          await this.handlePaymentFailed(event.data.object as Stripe.Invoice);
          break;
        case 'customer.subscription.deleted':
          await this.handleSubscriptionCancelled(event.data.object as Stripe.Subscription);
          break;
        case 'customer.subscription.updated':
          await this.handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
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
  private async handleCheckoutCompleted(session: Stripe.Checkout.Session): Promise<void> {
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
    this.logger.log(`Subscription activated for user ${userId} with plan ${planTier}`);
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
      this.logger.error(`Subscription not found for Stripe ID: ${invoice.subscription}`);
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
}
