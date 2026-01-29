import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
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
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';
import { UsersService } from '../users/users.service';
import { IntaSendService } from '../payments/intasend.service';
import { StripeService } from '../payments/stripe.service';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../payments/entities/transaction.entity';
import { WorkersService } from '../workers/workers.service';

@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  private readonly logger = new Logger(SubscriptionsController.name);

  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    private usersService: UsersService,
    private intaSendService: IntaSendService,
    private stripeService: StripeService,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    private workersService: WorkersService,
  ) { }

  @Get('plans')
  getPlans() {
    return SUBSCRIPTION_PLANS.map((plan, index) => ({
      id: plan.tier.toLowerCase(), // Use tier as ID
      tier: plan.tier,
      name: plan.name,
      description: `${plan.name} plan - Up to ${plan.workerLimit} workers`,
      price_usd: plan.priceUSD,
      price_kes: plan.priceKES,
      currency: 'USD',
      active: true,
      features: this.convertFeaturesToMap(plan.features),
      sort_order: index + 1,
      worker_limit: plan.workerLimit,
      billing_period: 'monthly',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }));
  }

  private convertFeaturesToMap(features: string[]): Record<string, boolean> {
    const featureMap: Record<string, boolean> = {};
    features.forEach((feature) => {
      const key = feature
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9_]/g, '')
        .replace(/_+/g, '_');
      featureMap[key] = true;
    });
    return featureMap;
  }

  /**
   * Calculate prorated amount for subscription upgrade
   *
   * @param currentTier - Current subscription tier
   * @param newTier - New subscription tier
   * @param currentPeriodStart - Start date of current billing period
   * @returns Proration details including amount to charge
   */
  private calculateProration(
    currentTier: string,
    newTier: string,
    currentPeriodStart: Date,
  ): {
    daysRemaining: number;
    daysInPeriod: number;
    currentPlanCredit: number;
    newPlanCharge: number;
    proratedAmount: number;
    fullNewPlanPrice: number;
  } {
    const currentPlan = SUBSCRIPTION_PLANS.find((p) => p.tier === currentTier);
    const newPlan = SUBSCRIPTION_PLANS.find((p) => p.tier === newTier);

    if (!newPlan) {
      throw new Error('Invalid new plan');
    }

    // Calculate days in current billing period (30 days standard)
    const daysInPeriod = 30;
    const now = new Date();
    const periodStart = new Date(currentPeriodStart);

    // Calculate days elapsed and remaining
    const msElapsed = now.getTime() - periodStart.getTime();
    const daysElapsed = Math.floor(msElapsed / (1000 * 60 * 60 * 24));
    const daysRemaining = Math.max(0, daysInPeriod - daysElapsed);

    // Calculate proration
    const currentPlanPrice = currentPlan?.priceKES || 0;
    const newPlanPrice = newPlan.priceKES;

    // Credit for unused portion of current plan
    const currentPlanCredit = Math.round(
      (currentPlanPrice / daysInPeriod) * daysRemaining,
    );

    // Charge for new plan for remaining days
    const newPlanCharge = Math.round(
      (newPlanPrice / daysInPeriod) * daysRemaining,
    );

    // Net amount to charge (difference)
    const proratedAmount = Math.max(0, newPlanCharge - currentPlanCredit);

    return {
      daysRemaining,
      daysInPeriod,
      currentPlanCredit,
      newPlanCharge,
      proratedAmount,
      fullNewPlanPrice: newPlanPrice,
    };
  }

  @Get('upgrade-preview/:newPlanId')
  async getUpgradePreview(
    @Request() req: any,
    @Param('newPlanId') newPlanId: string,
  ) {
    // Get current subscription
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId, status: SubscriptionStatus.ACTIVE },
    });

    const newPlan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === newPlanId.toLowerCase(),
    );

    if (!newPlan) {
      throw new Error('Invalid plan');
    }

    // If no active subscription or FREE tier, charge full price
    if (!subscription || subscription.tier === 'FREE') {
      return {
        isUpgrade: true,
        isProrated: false,
        currentTier: subscription?.tier || 'FREE',
        newTier: newPlan.tier,
        currentPlanName: 'Free',
        newPlanName: newPlan.name,
        amountToCharge: newPlan.priceKES,
        currency: 'KES',
        message: `Full monthly price for ${newPlan.name}`,
        breakdown: {
          daysRemaining: 30,
          currentPlanCredit: 0,
          newPlanCharge: newPlan.priceKES,
        },
      };
    }

    // Check if upgrade or downgrade
    const currentPlanIndex = SUBSCRIPTION_PLANS.findIndex(
      (p) => p.tier === subscription.tier,
    );
    const newPlanIndex = SUBSCRIPTION_PLANS.findIndex(
      (p) => p.tier === newPlan.tier,
    );

    if (newPlanIndex <= currentPlanIndex) {
      return {
        isUpgrade: false,
        isProrated: false,
        currentTier: subscription.tier,
        newTier: newPlan.tier,
        currentPlanName: SUBSCRIPTION_PLANS[currentPlanIndex].name,
        newPlanName: newPlan.name,
        amountToCharge: 0,
        currency: 'KES',
        message: 'Downgrade will take effect at next billing cycle',
      };
    }

    // Calculate proration for upgrade
    const proration = this.calculateProration(
      subscription.tier,
      newPlan.tier,
      subscription.startDate || new Date(),
    );

    return {
      isUpgrade: true,
      isProrated: true,
      currentTier: subscription.tier,
      newTier: newPlan.tier,
      currentPlanName: SUBSCRIPTION_PLANS[currentPlanIndex].name,
      newPlanName: newPlan.name,
      amountToCharge: proration.proratedAmount,
      fullMonthlyPrice: proration.fullNewPlanPrice,
      currency: 'KES',
      message: `Prorated for ${proration.daysRemaining} remaining days`,
      breakdown: {
        daysRemaining: proration.daysRemaining,
        daysInPeriod: proration.daysInPeriod,
        currentPlanCredit: proration.currentPlanCredit,
        newPlanCharge: proration.newPlanCharge,
      },
    };
  }

  @Get('current')
  async getCurrentSubscription(@Request() req: any) {
    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId: req.user.userId,
        status: SubscriptionStatus.ACTIVE,
      },
      relations: ['user'],
    });

    // Return free tier if no active subscription found
    if (!subscription) {
      // Get full user data
      const userData = await this.usersService.findOneById(req.user.userId);

      return {
        id: null,
        tier: userData?.tier || 'FREE',
        planName: 'Free Tier',
        price: 0,
        currency: 'KES',
        features: ['Up to 1 worker', 'Automatic tax calculations'],
        isActive: true,
        startDate: null,
        endDate: null,
        user: userData,
        autoRenew: false,
      };
    }

    return {
      ...subscription,
      autoRenew: subscription.autoRenewal,
      planName:
        SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier)?.name ||
        'Unknown Plan',
    };
  }

  @Post('auto-renew')
  async toggleAutoRenewal(
    @Request() req: any,
    @Body() body: { enable: boolean; reason?: string },
  ) {
    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId: req.user.userId,
        status: SubscriptionStatus.ACTIVE,
      },
    });

    if (!subscription) {
      throw new Error('No active subscription found');
    }

    subscription.autoRenewal = body.enable;

    if (!body.enable && body.reason) {
      const dateStr = new Date().toISOString().split('T')[0];
      const newNote = `[Cancellation Reason: ${body.reason} - ${dateStr}]`;
      subscription.notes = subscription.notes
        ? `${subscription.notes}\n${newNote}`
        : newNote;
    }

    const updatedSubscription = await this.subscriptionRepository.save(subscription);

    return {
      success: true,
      message: body.enable
        ? 'Auto-renewal enabled'
        : 'Auto-renewal disabled. Your plan will remain active until the end of the billing period.',
      subscription: {
        ...updatedSubscription,
        autoRenew: updatedSubscription.autoRenewal,
        planName:
          SUBSCRIPTION_PLANS.find((p) => p.tier === updatedSubscription.tier)?.name ||
          'Unknown Plan',
      },
    };
  }

  @Post('subscribe')
  async subscribe(
    @Request() req: any,
    @Body()
    body: {
      planId: string;
      paymentMethod?: string;
      billingPeriod?: 'monthly' | 'yearly';
    },
  ) {
    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan) {
      throw new Error('Invalid plan ID');
    }

    const billingPeriod = body.billingPeriod || 'monthly';
    const amountToCharge =
      billingPeriod === 'yearly' ? plan.priceKESYearly : plan.priceKES;

    // 1. Handle Stripe Payments
    if (body.paymentMethod === 'STRIPE' || body.paymentMethod === 'stripe') {
      const user = await this.usersService.findOneById(req.user.userId);
      if (!user) {
        throw new Error('User not found');
      }

      const checkoutResult = await this.stripeService.createCheckoutSession(
        req.user.userId,
        plan.tier,
        user.email,
        `${user.firstName || ''} ${user.lastName || ''}`.trim() || undefined,
        billingPeriod,
      );

      return {
        paymentMethod: 'STRIPE',
        checkoutUrl: checkoutResult.url,
        sessionId: checkoutResult.sessionId,
      };
    }

    // 2. Handle Bank Transfer Payments (IntaSend Checkout with PesaLink)
    if (body.paymentMethod === 'BANK' || body.paymentMethod === 'bank') {
      const user = await this.usersService.findOneById(req.user.userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Check for existing subscription to warn about grace period
      const existingSubscription = await this.subscriptionRepository.findOne({
        where: { userId: req.user.userId },
      });

      let gracePeriodWarning: string | null = null;
      let daysUntilDowngrade: number | null = null;

      if (existingSubscription?.gracePeriodEndDate) {
        const now = new Date();
        const gracePeriodEnd = new Date(existingSubscription.gracePeriodEndDate);
        const daysRemaining = Math.ceil((gracePeriodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

        if (daysRemaining <= 3 && daysRemaining > 0) {
          daysUntilDowngrade = daysRemaining;
          gracePeriodWarning = `Warning: Your grace period ends in ${daysRemaining} day(s). Bank transfers may take 1-3 business days to process.`;
        }
      }

      const reference = `SUB-${req.user.userId}-${plan.tier}-${billingPeriod}-${Date.now()}`;

      const checkoutResult = await this.intaSendService.createCheckoutUrl(
        amountToCharge,
        user.email,
        user.firstName || 'User',
        user.lastName || '',
        reference,
      );

      // Create or update subscription (PENDING until payment confirmed)
      let subscription = existingSubscription;
      if (!subscription) {
        subscription = this.subscriptionRepository.create({
          userId: req.user.userId,
          tier: plan.tier as SubscriptionTier,
          status: SubscriptionStatus.PENDING,
          startDate: new Date(),
        });
      } else {
        subscription.tier = plan.tier as SubscriptionTier;
        subscription.status = SubscriptionStatus.PENDING;
      }
      const savedSubscription = await this.subscriptionRepository.save(subscription);

      // Create pending payment record
      const now = new Date();
      const periodEnd = new Date(now);
      periodEnd.setMonth(periodEnd.getMonth() + (billingPeriod === 'yearly' ? 12 : 1));

      const payment = this.subscriptionPaymentRepository.create({
        subscriptionId: savedSubscription.id,
        userId: req.user.userId,
        amount: amountToCharge,
        currency: 'KES',
        status: PaymentStatus.PENDING,
        paymentMethod: PaymentMethod.BANK_TRANSFER,
        billingPeriod: billingPeriod,
        periodStart: now,
        periodEnd: periodEnd,
        dueDate: now,
        paymentProvider: 'INTASEND',
        transactionId: reference,
        metadata: {
          planId: plan.tier,
          billingPeriod,
          reference,
          checkoutUrl: checkoutResult.url,
        },
      });
      await this.subscriptionPaymentRepository.save(payment);

      return {
        success: true,
        message: 'Bank transfer checkout initiated',
        paymentMethod: 'BANK',
        checkoutUrl: checkoutResult.url,
        reference: reference,
        subscriptionId: savedSubscription.id,
        processingInfo: {
          estimatedTime: 'Instant (typically under 45 seconds)',
          note: 'Bank transfers via PesaLink are processed in real-time and typically complete within 45 seconds. Your subscription will be activated once payment is confirmed.',
          gracePeriodWarning,
          daysUntilDowngrade,
        },
      };
    }

    // 3. Handle Wallet Payments (Leveraging Internal Ledger)
    if (body.paymentMethod === 'WALLET') {
      const user = await this.usersService.findOneById(req.user.userId);
      if (!user) throw new Error('User not found');

      // Check Funds
      if (Number(user.walletBalance) < amountToCharge) {
        throw new Error(
          `Insufficient wallet balance. Required: KES ${amountToCharge}, Available: KES ${user.walletBalance}`,
        );
      }

      // Check for existing active subscription
      // Implementation Note: Upgrades/Proration logic not fully implemented for Wallet yet
      // For now, we assume simple monthly renewal or new subscription.

      // Deduct Funds
      await this.usersService.update(user.id, {
        walletBalance: Number(user.walletBalance) - amountToCharge,
      });

      // Create/Update Subscription
      let subscription = await this.subscriptionRepository.findOne({
        where: { userId: req.user.userId },
      });

      // Calculate period end date
      const now = new Date();
      const periodEnd = new Date(now);
      if (billingPeriod === 'yearly') {
        periodEnd.setFullYear(periodEnd.getFullYear() + 1);
      } else {
        periodEnd.setMonth(periodEnd.getMonth() + 1);
      }

      if (!subscription) {
        subscription = this.subscriptionRepository.create({
          userId: req.user.userId,
          tier: plan.tier as SubscriptionTier,
          status: SubscriptionStatus.ACTIVE,
          startDate: now,
          endDate: periodEnd,
          nextBillingDate: periodEnd,
          billingPeriod: billingPeriod,
          lockedPrice: amountToCharge,
        });
      } else {
        subscription.tier = plan.tier as SubscriptionTier;
        subscription.status = SubscriptionStatus.ACTIVE;
        subscription.updatedAt = new Date();
        subscription.billingPeriod = billingPeriod;
        subscription.endDate = periodEnd;
        subscription.nextBillingDate = periodEnd;
        subscription.lockedPrice = amountToCharge;
      }
      const savedSubscription =
        await this.subscriptionRepository.save(subscription);
      await this.usersService.update(req.user.userId, {
        tier: plan.tier as any,
      });

      // Record Payment

      const payment = this.subscriptionPaymentRepository.create({
        subscriptionId: savedSubscription.id,
        userId: req.user.userId,
        amount: amountToCharge,
        currency: 'KES',
        status: PaymentStatus.COMPLETED,
        paymentMethod: PaymentMethod.WALLET, // Ensure this enum exists or use 'WALLET' string
        billingPeriod: billingPeriod,
        periodStart: now,
        periodEnd: periodEnd,
        dueDate: now,
        paidDate: now,
        paymentProvider: 'INTERNAL_WALLET',
        metadata: {
          planId: plan.tier,
          billingPeriod: billingPeriod,
          description: `Subscription to ${plan.name} (${billingPeriod}) via Wallet`,
        },
      });
      await this.subscriptionPaymentRepository.save(payment);

      return {
        success: true,
        message: 'Subscription activated via Wallet',
        subscription: savedSubscription,
      };
    }


    // 3. Handle Bank Transfers (PesaLink via IntaSend)
    if (body.paymentMethod === 'BANK' && amountToCharge > 0) {
      const user = await this.usersService.findOneById(req.user.userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Generate Reference
      const reference = `SUB_${req.user.userId}_${Date.now()}`;

      // Initiate Checkout
      const checkout = await this.intaSendService.createCheckoutUrl(
        amountToCharge,
        user.email || 'no-email@paykey.com',
        user.firstName || 'Valued',
        user.lastName || 'Customer',
        reference
      );

      // Return Checkout Info
      return {
        success: true,
        message: 'Bank transfer initiated',
        checkoutUrl: checkout.url,
        reference: reference,
        processingInfo: { estimatedTime: 'Instant via PesaLink' }
      };
    }

    // 4. Handle Free Tier
    if (amountToCharge === 0) {
      let subscription = await this.subscriptionRepository.findOne({
        where: { userId: req.user.userId },
      });

      // Downgrade protection: If engaging Free tier while on an Active Paid plan, treat as cancellation
      if (
        subscription &&
        subscription.status === SubscriptionStatus.ACTIVE &&
        subscription.tier !== SubscriptionTier.FREE &&
        subscription.endDate &&
        subscription.endDate > new Date()
      ) {
        subscription.autoRenewal = false;
        const dateStr = new Date().toISOString().split('T')[0];
        const newNote = `[Downgrade to Free requested - ${dateStr}]`;
        subscription.notes = subscription.notes
          ? `${subscription.notes}\n${newNote}`
          : newNote;

        const updatedSub = await this.subscriptionRepository.save(subscription);

        return {
          success: true,
          message: `Downgrade scheduled. Your current plan will remain active until the end of the billing period (${subscription.endDate.toISOString().split('T')[0]}). You will be switched to the Free tier then.`,
          subscription: updatedSub
        };
      }

      if (!subscription) {
        subscription = this.subscriptionRepository.create({
          userId: req.user.userId,
          tier: plan.tier as SubscriptionTier,
          status: SubscriptionStatus.ACTIVE,
          startDate: new Date(),
          billingPeriod: billingPeriod,
        });
      } else {
        subscription.tier = plan.tier as SubscriptionTier;
        subscription.status = SubscriptionStatus.ACTIVE;
        subscription.updatedAt = new Date();
        subscription.billingPeriod = billingPeriod;
        // Ensure no trial logic is carried over if switching strictly to Free immediately
        subscription.startDate = new Date();
        subscription.endDate = null; // Free forever
        subscription.autoRenewal = false;
      }

      const savedSubscription =
        await this.subscriptionRepository.save(subscription);
      await this.usersService.update(req.user.userId, {
        tier: plan.tier as any,
      });

      return savedSubscription;
    }

    // 4. Fallback / Security Block
    throw new Error(
      'Payment method required for paid plans. Please select Card (Stripe) or M-Pesa.',
    );
  }

  @Get('subscription-payment-history')
  async getSubscriptionPaymentHistory(@Request() req: any) {
    // Get all subscription payments for the current user
    const payments = await this.subscriptionPaymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' },
    });

    // Return empty array if no payments found
    return payments || [];
  }

  // ============================================================================
  // M-PESA SUBSCRIPTION PAYMENT
  // ============================================================================

  @Post('mpesa-subscribe')
  async mpesaSubscribe(
    @Request() req: any,
    @Body() body: { planId: string; phoneNumber: string; billingPeriod?: 'monthly' | 'yearly' },
  ) {
    const { planId, phoneNumber } = body;
    const billingPeriod = body.billingPeriod || 'monthly';

    // Validate plan
    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === planId.toLowerCase(),
    );
    if (!plan) {
      throw new Error('Invalid plan ID');
    }

    // Format phone number (ensure it starts with 254)
    let formattedPhone = phoneNumber.replace(/\s+/g, '').replace(/^0/, '254');
    if (!formattedPhone.startsWith('254')) {
      formattedPhone = '254' + formattedPhone;
    }

    // Check for existing subscription to determine proration
    const existingSubscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId, status: SubscriptionStatus.ACTIVE },
    });

    // Use yearly pricing if applicable
    let amountToCharge = billingPeriod === 'yearly' ? plan.priceKESYearly : plan.priceKES;
    let isProrated = false;
    let prorationDetails: any = null;

    // Calculate proration if upgrading from an existing paid plan
    if (existingSubscription && existingSubscription.tier !== 'FREE') {
      const currentPlanIndex = SUBSCRIPTION_PLANS.findIndex(
        (p) => p.tier === existingSubscription.tier,
      );
      const newPlanIndex = SUBSCRIPTION_PLANS.findIndex(
        (p) => p.tier === plan.tier,
      );

      // Downgrade: Schedule for end of period (Safe Downgrade)
      if (newPlanIndex < currentPlanIndex) {
        existingSubscription.pendingTier = plan.tier as SubscriptionTier;
        existingSubscription.autoRenewal = true; // Ensure they verify renewal to switch

        const dateStr = new Date().toISOString().split('T')[0];
        const newNote = `[Downgrade to ${plan.name} scheduled - ${dateStr}]`;
        existingSubscription.notes = existingSubscription.notes
          ? `${existingSubscription.notes}\n${newNote}`
          : newNote;

        const savedSub = await this.subscriptionRepository.save(existingSubscription);

        return {
          success: true,
          message: `Plan change scheduled. You will stay on ${existingSubscription.tier} until the billing period ends, then automatically switch to ${plan.name}.`,
          subscription: savedSub,
          amountCharged: 0,
          isProrated: false
        };
      }

      // Only prorate for upgrades
      if (newPlanIndex > currentPlanIndex) {
        // Clear any pending downgrade if upgrading
        existingSubscription.pendingTier = null;

        const proration = this.calculateProration(
          existingSubscription.tier,
          plan.tier,
          existingSubscription.startDate || new Date(),
        );

        amountToCharge = proration.proratedAmount;
        isProrated = true;
        prorationDetails = {
          daysRemaining: proration.daysRemaining,
          currentPlanCredit: proration.currentPlanCredit,
          newPlanCharge: proration.newPlanCharge,
        };

        this.logger.log(`Proration calculated: ${JSON.stringify(proration)}`);
      }
    }

    this.logger.log(
      `Initiating M-Pesa subscription for ${formattedPhone}, plan: ${plan.name}, amount: KES ${amountToCharge} (prorated: ${isProrated})`,
    );

    // If amount is 0 (e.g., prorated upgrade with credit), activate immediately
    if (amountToCharge <= 0) {
      if (existingSubscription) {
        existingSubscription.tier = plan.tier as SubscriptionTier;
        existingSubscription.status = SubscriptionStatus.ACTIVE;
        await this.subscriptionRepository.save(existingSubscription);
        await this.usersService.update(req.user.userId, {
          tier: plan.tier as any,
        });
      }

      return {
        success: true,
        message: 'Upgrade applied immediately (no additional payment required)',
        paymentId: null,
        subscriptionId: existingSubscription?.id,
        amountCharged: 0,
        isProrated: true,
      };
    }

    // Create or update subscription (PENDING until payment confirmed)
    let subscription = existingSubscription;
    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        userId: req.user.userId,
        tier: plan.tier as SubscriptionTier,
        status: SubscriptionStatus.PENDING,
        startDate: new Date(),
      });
    } else {
      // Store old tier in metadata to restore if payment fails
      subscription.tier = plan.tier as SubscriptionTier;
      subscription.status = SubscriptionStatus.PENDING;
    }
    const savedSubscription =
      await this.subscriptionRepository.save(subscription);

    // Create pending payment record
    const now = new Date();
    const periodEnd = new Date(now);
    periodEnd.setMonth(periodEnd.getMonth() + 1);

    const payment = this.subscriptionPaymentRepository.create({
      subscriptionId: savedSubscription.id,
      userId: req.user.userId,
      amount: amountToCharge,
      currency: 'KES',
      status: PaymentStatus.PENDING,
      paymentMethod: PaymentMethod.MPESA,
      billingPeriod: 'monthly',
      periodStart: now,
      periodEnd: periodEnd,
      dueDate: now,
      paymentProvider: 'MPESA',
      metadata: {
        phoneNumber: formattedPhone,
        planId,
        isProrated,
        prorationDetails,
        originalAmount: plan.priceKES,
      },
    });
    const savedPayment = await this.subscriptionPaymentRepository.save(payment);

    // Initiate STK Push via IntaSend
    try {
      const stkResponse = await this.intaSendService.initiateStkPush(
        formattedPhone,
        amountToCharge,
        `PayKey-${plan.tier}`,
      );

      // IntaSend returns invoice details. We store invoice_id or tracking_id
      const invoiceId = stkResponse.invoice.invoice_id;
      const trackingId = stkResponse.tracking_id; // Check actual response structure

      // Update payment with checkout request ID
      await this.subscriptionPaymentRepository.update(savedPayment.id, {
        transactionId: invoiceId, // Store Invoice ID as Transaction ID
        metadata: {
          ...savedPayment.metadata,
          intaSendInvoiceId: invoiceId,
          intaSendTrackingId: trackingId,
          provider: 'INTASEND',
        },
      });

      // CREATE TRANSACTION RECORD FOR WEBHOOK HANDLING
      // The PaymentsController webhook handler looks for a Transaction entity with the providerRef.
      const transaction = this.transactionRepository.create({
        userId: req.user.userId,
        amount: amountToCharge,
        currency: 'KES',
        type: TransactionType.SUBSCRIPTION,
        status: TransactionStatus.PENDING,
        provider: 'INTASEND',
        providerRef: invoiceId, // THIS matches the invoice_id in the webhook
        accountReference: `PayKey-${plan.tier}`,
        recipientPhone: formattedPhone,
        metadata: {
          subscriptionPaymentId: savedPayment.id,
          planId: plan.tier,
          phoneNumber: formattedPhone,
        },
      });
      console.log(
        '🔹 Creating Transaction with Metadata:',
        transaction.metadata,
      );
      await this.transactionRepository.save(transaction);

      return {
        success: true,
        message: 'Info: Please check your phone to enter M-Pesa PIN.',
        paymentId: savedPayment.id,
        checkoutRequestId: invoiceId,
        subscriptionId: savedSubscription.id,
      };
    } catch (error) {
      this.logger.error('IntaSend STK Push failed:', error);

      // Mark payment as failed
      await this.subscriptionPaymentRepository.update(savedPayment.id, {
        status: PaymentStatus.FAILED,
        notes: error.message,
      });

      throw new Error(`Payment initiation failed: ${error.message}`);
    }
  }

  // ============================================================================
  // SUBSCRIPTION USAGE
  // ============================================================================

  @Get('usage')
  async getUsage(@Request() req: any) {
    // Get worker count for the current user
    const workerCount = await this.workersService.getWorkerCount(req.user.userId);

    // Get current subscription
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId, status: SubscriptionStatus.ACTIVE },
    });

    // Get plan limits
    const tier = subscription?.tier || 'FREE';
    const plan = SUBSCRIPTION_PLANS.find((p) => p.tier === tier);
    const workerLimit = plan?.workerLimit || 1;

    return {
      workers: {
        used: workerCount,
        limit: workerLimit,
        percentage: Math.min(100, Math.round((workerCount / workerLimit) * 100)),
      },
      tier: tier,
      planName: plan?.name || 'Free',
    };
  }

  @Get('mpesa-payment-status/:paymentId')
  async checkMpesaPaymentStatus(
    @Request() req: any,
    @Param('paymentId') paymentId: string,
  ) {
    const payment = await this.subscriptionPaymentRepository.findOne({
      where: { id: paymentId, userId: req.user.userId },
    });

    if (!payment) {
      throw new Error('Payment not found');
    }

    // If payment completed, ensure subscription is activated
    if (payment.status === PaymentStatus.COMPLETED) {
      const subscription = await this.subscriptionRepository.findOne({
        where: { id: payment.subscriptionId },
      });

      if (subscription && subscription.status !== SubscriptionStatus.ACTIVE) {
        subscription.status = SubscriptionStatus.ACTIVE;
        await this.subscriptionRepository.save(subscription);

        // Update user tier
        const plan = SUBSCRIPTION_PLANS.find(
          (p) => p.tier === subscription.tier,
        );
        if (plan) {
          await this.usersService.update(req.user.userId, {
            tier: plan.tier as any,
          });
        }
      }
    }

    return {
      paymentId: payment.id,
      status: payment.status,
      amount: payment.amount,
      currency: payment.currency,
      paidDate: payment.paidDate,
    };
  }
}
