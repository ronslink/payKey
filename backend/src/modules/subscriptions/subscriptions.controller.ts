import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
  Logger,
  BadRequestException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { InjectRepository } from '@nestjs/typeorm';
import {
  Repository,
  In,
  IsNull,
  LessThanOrEqual,
  MoreThanOrEqual,
  Or,
  Not,
  EntityManager,
} from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  Subscription,
  RenewalMethod,
  SubscriptionStatus,
  SubscriptionTier,
} from './entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
  PaymentMethod,
} from './entities/subscription-payment.entity';
import {
  Campaign,
  CampaignStatus,
  CampaignType,
} from './entities/campaign.entity';
import {
  PromotionalItem,
  PromoStatus,
} from './entities/promotional-item.entity';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';
import { UsersService } from '../users/users.service';
import {
  IntaSendService,
  IntaSendStkPushError,
} from '../payments/intasend.service';
import { StripeService } from '../payments/stripe.service';
import {
  Transaction,
  PaymentMethodType,
  TransactionStatus,
  TransactionType,
} from '../payments/entities/transaction.entity';
import { WorkersService } from '../workers/workers.service';
import { SubscribeDto } from './dto/subscribe.dto';
import { User, UserTier } from '../users/entities/user.entity';
import { paymentMetadata } from './dto/subscription-payment-metadata';
import { AutoRenewDto, MpesaSubscribeDto } from './dto/billing-mutations.dto';
import { redactProviderSecrets } from '../../common/security/provider-secrets';

@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  private readonly logger = new Logger(SubscriptionsController.name);

  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private readonly subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(Campaign)
    private readonly campaignRepository: Repository<Campaign>,
    @InjectRepository(PromotionalItem)
    private readonly promoRepository: Repository<PromotionalItem>,
    private readonly usersService: UsersService,
    private readonly intaSendService: IntaSendService,
    private readonly stripeService: StripeService,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    private readonly workersService: WorkersService,
  ) {}

  private publicBillingUser(user?: User | null) {
    if (!user) return null;
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      businessName: user.businessName,
      tier: user.tier,
    };
  }

  private async withNonStripeBilling<T>(
    userId: string,
    work: (manager: EntityManager) => Promise<T>,
  ): Promise<T> {
    return this.subscriptionRepository.manager.transaction(async (manager) => {
      // Use the same account lock as Stripe checkout and invoice settlement.
      await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
        `stripe-billing:${userId}`,
      ]);
      const linked = await manager.find(Subscription, {
        where: { userId, stripeSubscriptionId: Not(IsNull()) },
      });
      if (
        linked.some(
          (subscription) =>
            subscription.status !== SubscriptionStatus.CANCELLED,
        )
      ) {
        throw new BadRequestException(
          'Manage or cancel the existing Stripe subscription before changing payment methods or plans',
        );
      }
      // A confirmed cancelled provider contract must not manage a replacement plan.
      for (const subscription of linked) {
        await manager.update(
          Subscription,
          { id: subscription.id },
          { stripeSubscriptionId: null as unknown as string },
        );
      }
      return work(manager);
    });
  }

  private async assertNoCompetingPayment(manager: EntityManager, user: User) {
    const pending = await manager.findOne(SubscriptionPayment, {
      where: {
        userId: user.id,
        paymentProvider: 'INTASEND',
        status: PaymentStatus.PENDING,
      },
    });
    if (pending)
      throw new BadRequestException(
        'An M-Pesa or bank subscription payment is still pending. Wait for its result before starting another payment.',
      );
    await this.stripeService.assertNoPayableSubscriptionCheckout(
      user.id,
      user.email,
      user.stripeCustomerId,
    );
  }

  /**
   * GET /subscriptions/campaigns/active
   *
   * Returns the active campaigns relevant to the calling user's subscription tier.
   * Called by the mobile app on login / dashboard load.
   *
   * Filtering rules:
   *  - status = ACTIVE
   *  - scheduledFrom <= now  OR  scheduledFrom IS NULL
   *  - scheduledUntil >= now  OR  scheduledUntil IS NULL
   *  - targetAudience.tiers contains the user's tier  OR  no tiers set (broad campaign)
   *  - Campaign type must be BANNER, POPUP, or SIDEBAR (push/email are server-dispatched)
   *
   * Results are ordered by priority DESC so the app always renders the most important one first.
   */
  @Get('campaigns/active')
  async getActiveCampaigns(@Request() req: { user: { userId: string } }) {
    const now = new Date();

    // Fetch the calling user's current tier
    const user = await this.usersService.findOneById(req.user.userId);
    const userTier = user?.tier || 'FREE';

    // Pull all ACTIVE campaigns within the time window
    const campaigns = await this.campaignRepository
      .createQueryBuilder('c')
      .leftJoinAndSelect('c.promotionalItem', 'promo')
      .where('c.status = :status', { status: CampaignStatus.ACTIVE })
      .andWhere('(c.scheduledFrom IS NULL OR c.scheduledFrom <= :now)', { now })
      .andWhere('(c.scheduledUntil IS NULL OR c.scheduledUntil >= :now)', {
        now,
      })
      .andWhere('c.type IN (:...types)', {
        types: [CampaignType.BANNER, CampaignType.POPUP, CampaignType.SIDEBAR],
      })
      .orderBy('c.priority', 'DESC', 'NULLS LAST')
      .getMany();

    // Filter by audience tier in application code (JSON column query is DB-specific)
    const relevant = campaigns.filter((c) => {
      const tiers = c.targetAudience?.tiers;
      // No tier targeting = show to everyone
      if (!tiers || tiers.length === 0) return true;
      return tiers.includes(userTier);
    });

    return {
      campaigns: relevant.map((c) => ({
        id: c.id,
        type: c.type,
        title: c.title,
        message: c.message,
        imageUrl: c.imageUrl,
        callToAction: c.callToAction,
        callToActionUrl: c.callToActionUrl,
        displaySettings: c.displaySettings,
        priority: c.priority,
        promotionalItem: c.promotionalItem
          ? {
              id: c.promotionalItem.id,
              name: c.promotionalItem.name,
              type: c.promotionalItem.type,
              discountPercentage: c.promotionalItem.discountPercentage,
              discountAmount: c.promotionalItem.discountAmount,
              freeTrialDays: c.promotionalItem.freeTrialDays,
              validUntil: c.promotionalItem.validUntil,
              termsAndConditions: c.promotionalItem.termsAndConditions,
            }
          : null,
      })),
      userTier,
      fetchedAt: now.toISOString(),
    };
  }

  /**
   * POST /subscriptions/validate-promo
   *
   * Validates a promo code and returns discount details without redeeming it.
   * The Flutter app calls this to preview the discounted price before checkout.
   *
   * Body: { promoCode: string; planId: string; billingPeriod?: 'monthly' | 'yearly' }
   * Returns: { valid, promoId, discountType, discountValue, originalAmount, discountedAmount, savings }
   */
  @Post('validate-promo')
  async validatePromo(
    @Request() req: { user: { userId: string } },
    @Body()
    body: {
      promoCode: string;
      planId: string;
      billingPeriod?: 'monthly' | 'yearly';
    },
  ) {
    const { promoCode, planId } = body;
    const billingPeriod = body.billingPeriod || 'monthly';

    if (!promoCode || !planId) {
      throw new BadRequestException('promoCode and planId are required');
    }

    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === planId.toLowerCase(),
    );
    if (!plan) {
      throw new BadRequestException('Invalid plan ID');
    }

    const originalAmount =
      billingPeriod === 'yearly' ? plan.priceKESYearly : plan.priceKES;

    // Fetch the user's current tier for tier eligibility check
    const user = await this.usersService.findOneById(req.user.userId);
    const userTier = user?.tier || 'FREE';

    const { promo, error } = await this.resolvePromoCode(
      promoCode.trim().toUpperCase(),
      plan.tier,
      userTier,
    );

    if (error || !promo) {
      return { valid: false, error: error || 'Invalid promo code' };
    }

    const { discountedAmount, savings } = this.applyPromoDiscount(
      originalAmount,
      promo,
    );

    return {
      valid: true,
      promoId: promo.id,
      promoName: promo.name,
      discountType: promo.discountPercentage ? 'PERCENTAGE' : 'FIXED',
      discountValue: promo.discountPercentage ?? promo.discountAmount,
      originalAmount,
      discountedAmount,
      savings,
      currency: 'KES',
      validUntil: promo.validUntil,
      termsAndConditions: promo.termsAndConditions,
    };
  }

  /**
   * Looks up and validates a promo code against the given target tier and user tier.
   * Does NOT redeem (increment currentUses). Returns the promo entity or an error string.
   */
  private async resolvePromoCode(
    promoCode: string,
    targetTier: string,
    userTier: string,
    promoRepository = this.promoRepository,
  ): Promise<{ promo?: PromotionalItem; error?: string }> {
    const promo = await promoRepository.findOne({
      where: { promoCode },
    });

    if (!promo) return { error: 'Promo code not found' };
    if (promo.status !== PromoStatus.ACTIVE)
      return { error: 'Promo code is not active' };

    const now = new Date();
    if (promo.validFrom && promo.validFrom > now)
      return { error: 'Promo code is not yet valid' };
    if (promo.validUntil && promo.validUntil < now)
      return { error: 'Promo code has expired' };

    if (promo.maxUses !== null && promo.currentUses >= promo.maxUses) {
      return { error: 'Promo code usage limit reached' };
    }

    // Tier eligibility: check both the plan being purchased and the user's current tier
    if (promo.applicableTiers && promo.applicableTiers.length > 0) {
      if (
        !promo.applicableTiers.includes(targetTier) &&
        !promo.applicableTiers.includes(userTier)
      ) {
        return {
          error: 'Promo code is not applicable to your subscription tier',
        };
      }
    }

    return { promo };
  }

  /**
   * Applies a promo discount to an amount. Returns discounted amount and savings.
   * Percentage takes priority; fixed amount is fallback.
   */
  private applyPromoDiscount(
    originalAmount: number,
    promo: PromotionalItem,
  ): { discountedAmount: number; savings: number } {
    let savings = 0;

    if (promo.discountPercentage) {
      savings = Math.round(
        (originalAmount * Number(promo.discountPercentage)) / 100,
      );
    } else if (promo.discountAmount) {
      savings = Math.min(
        Math.round(Number(promo.discountAmount)),
        originalAmount,
      );
    }

    const discountedAmount = Math.max(0, originalAmount - savings);
    return { discountedAmount, savings };
  }

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
    @Request() req: { user: { userId: string } },
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
  async getCurrentSubscription(@Request() req: { user: { userId: string } }) {
    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId: req.user.userId,
        status: In([SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE]),
      },
      relations: ['user'],
      order: { updatedAt: 'DESC' },
    });
    const pendingPayment = await this.getPendingSubscriptionPayment(
      req.user.userId,
    );

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
        user: this.publicBillingUser(userData),
        provider: null,
        paymentMethod: null,
        renewalMode: null,
        billingPeriod: null,
        autoRenew: false,
        autoRenewalAvailable: false,
        autoRenewalMode: RenewalMethod.NOTIFICATION,
        autoRenewalDescription:
          'Auto-renewal creates a secure payment request when your plan renews.',
        paymentDue: !!pendingPayment,
        pendingPayment,
      };
    }

    const latestPaid = await this.subscriptionPaymentRepository.findOne({
      where: {
        subscriptionId: subscription.id,
        userId: req.user.userId,
        status: PaymentStatus.COMPLETED,
      },
      order: { paidDate: 'DESC', createdAt: 'DESC' },
    });
    const isManualMpesa =
      !subscription.stripeSubscriptionId &&
      latestPaid?.paymentMethod === 'mpesa';
    return {
      ...subscription,
      provider: subscription.stripeSubscriptionId
        ? 'STRIPE'
        : latestPaid
          ? 'INTASEND'
          : null,
      paymentMethod: subscription.stripeSubscriptionId
        ? PaymentMethod.STRIPE
        : latestPaid?.paymentMethod || null,
      renewalMode: subscription.stripeSubscriptionId
        ? 'automatic'
        : latestPaid
          ? 'manual'
          : null,
      user: this.publicBillingUser(subscription.user),
      autoRenew: subscription.autoRenewal,
      planName:
        SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier)?.name ||
        'Unknown Plan',
      autoRenewalAvailable: !isManualMpesa,
      autoRenewalMode: subscription.renewalMethod,
      autoRenewalDescription: subscription.stripeSubscriptionId
        ? 'Stripe subscriptions renew automatically using the saved billing method.'
        : isManualMpesa
          ? 'Approve each renewal with your M-Pesa PIN. Access expires at the paid-through date unless you renew.'
          : 'Auto-renewal creates a secure IntaSend payment request and notifies you when your plan renews.',
      paymentDue: !!pendingPayment,
      pendingPayment,
    };
  }

  @Get('pending-payment')
  async getPendingPayment(@Request() req: { user: { userId: string } }) {
    const pendingPayment = await this.getPendingSubscriptionPayment(
      req.user.userId,
    );

    return {
      hasPendingPayment: !!pendingPayment,
      pendingPayment,
    };
  }

  @Post('auto-renew')
  async toggleAutoRenewal(
    @Request() req: { user: { userId: string } },
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    )
    body: AutoRenewDto,
  ) {
    const subscription = await this.subscriptionRepository.findOne({
      where: [
        {
          userId: req.user.userId,
          status: SubscriptionStatus.ACTIVE,
        },
        {
          userId: req.user.userId,
          status: SubscriptionStatus.PAST_DUE,
        },
      ],
      order: { updatedAt: 'DESC' },
    });

    if (!subscription) {
      throw new Error('No active subscription found');
    }

    let updatedSubscription: Subscription;

    if (subscription.stripeSubscriptionId) {
      updatedSubscription = await this.stripeService.setCancelAtPeriodEnd(
        req.user.userId,
        !body.enable,
      );
    } else {
      updatedSubscription = await this.withNonStripeBilling(
        req.user.userId,
        async (manager) => {
          // Settlement may have extended the paid period after the initial
          // provider lookup. Read and save the current row under its billing lock.
          const current = await manager.findOne(Subscription, {
            where: [
              { userId: req.user.userId, status: SubscriptionStatus.ACTIVE },
              { userId: req.user.userId, status: SubscriptionStatus.PAST_DUE },
            ],
            order: { updatedAt: 'DESC' },
          });
          if (!current)
            throw new BadRequestException('No active subscription found');
          const latestPaid = await manager.findOne(SubscriptionPayment, {
            where: {
              subscriptionId: current.id,
              status: PaymentStatus.COMPLETED,
            },
            order: { paidDate: 'DESC', createdAt: 'DESC' },
          });
          if (body.enable && latestPaid?.paymentMethod === 'mpesa')
            throw new BadRequestException(
              'M-Pesa requires your approval for each renewal. Renew from your account when ready.',
            );
          current.autoRenewal = body.enable;
          current.renewalMethod =
            body.renewalMethod || RenewalMethod.NOTIFICATION;

          if (!body.enable && body.reason) {
            const dateStr = new Date().toISOString().split('T')[0];
            const newNote = `[Cancellation Reason: ${body.reason} - ${dateStr}]`;
            current.notes = current.notes
              ? `${current.notes}\n${newNote}`
              : newNote;
          }
          return manager.save(Subscription, current);
        },
      );
    }

    const message = body.enable
      ? subscription.stripeSubscriptionId
        ? 'Auto-renewal enabled. Stripe will continue billing this subscription automatically.'
        : 'Auto-renewal enabled. For IntaSend plans, PayDome will create a secure payment request and notify you at renewal time.'
      : 'Auto-renewal disabled. Your plan will remain active until the end of the billing period.';

    return {
      success: true,
      message,
      subscription: {
        ...updatedSubscription,
        autoRenew: updatedSubscription.autoRenewal,
        autoRenewalAvailable: true,
        autoRenewalMode: updatedSubscription.renewalMethod,
        autoRenewalDescription: updatedSubscription.stripeSubscriptionId
          ? 'Stripe subscriptions renew automatically using the saved billing method.'
          : 'Auto-renewal creates a secure IntaSend payment request and notifies you when your plan renews.',
        planName:
          SUBSCRIPTION_PLANS.find((p) => p.tier === updatedSubscription.tier)
            ?.name || 'Unknown Plan',
      },
    };
  }

  @Post('subscribe')
  async subscribe(
    @Request() req: { user: { userId: string } },
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    )
    body: SubscribeDto,
  ) {
    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan) {
      throw new BadRequestException('Invalid plan ID');
    }

    const billingPeriod = body.billingPeriod || 'monthly';
    let amountToCharge =
      billingPeriod === 'yearly' ? plan.priceKESYearly : plan.priceKES;

    // --- Promo code resolution ---
    let appliedPromo: PromotionalItem | null = null;
    let promoSavings = 0;

    if (body.promoCode) {
      const user = await this.usersService.findOneById(req.user.userId);
      const { promo, error } = await this.resolvePromoCode(
        body.promoCode.trim().toUpperCase(),
        plan.tier,
        user?.tier || 'FREE',
      );
      if (error || !promo) {
        throw new BadRequestException(error || 'Invalid promo code');
      }
      const result = this.applyPromoDiscount(amountToCharge, promo);
      amountToCharge = result.discountedAmount;
      promoSavings = result.savings;
      appliedPromo = promo;
      this.logger.log(
        `Promo "${promo.promoCode}" applied: -${promoSavings} KES → ${amountToCharge} KES`,
      );
    }

    // 1. Handle Stripe Payments
    if (body.paymentMethod === 'STRIPE' || body.paymentMethod === 'stripe') {
      if (plan.tier === 'FREE')
        throw new BadRequestException(
          'Free plans do not require card checkout',
        );
      if (body.promoCode)
        throw new BadRequestException(
          'Apply card promotion codes on the secure checkout page',
        );
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

    return this.withNonStripeBilling(req.user.userId, async (manager) => {
      // 2. Handle Bank Transfer Payments (IntaSend Checkout with PesaLink)
      if (body.paymentMethod === 'BANK' || body.paymentMethod === 'bank') {
        const user = await manager.findOne(User, {
          where: { id: req.user.userId },
          lock: { mode: 'pessimistic_write' },
        });
        if (!user) {
          throw new Error('User not found');
        }

        // Check for existing subscription to warn about grace period
        await this.assertNoCompetingPayment(manager, user);

        const existingSubscription = await manager
          .getRepository(Subscription)
          .findOne({
            where: { userId: req.user.userId },
          });

        if (
          existingSubscription &&
          existingSubscription.tier !== SubscriptionTier.FREE &&
          [SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE].includes(
            existingSubscription.status,
          )
        )
          throw new BadRequestException(
            'Your paid plan is still active. Renew with its existing payment method, or change payment methods after it expires.',
          );

        let gracePeriodWarning: string | null = null;
        let daysUntilDowngrade: number | null = null;

        if (existingSubscription?.gracePeriodEndDate) {
          const now = new Date();
          const gracePeriodEnd = new Date(
            existingSubscription.gracePeriodEndDate,
          );
          const daysRemaining = Math.ceil(
            (gracePeriodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
          );

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
          undefined,
          { method: 'PESALINK', comment: 'Paydome subscription payment' },
        );

        // Create or update subscription (PENDING until payment confirmed)
        let subscription = existingSubscription;
        if (!subscription) {
          subscription = manager.getRepository(Subscription).create({
            userId: req.user.userId,
            tier: plan.tier as SubscriptionTier,
            status: SubscriptionStatus.PENDING,
            startDate: new Date(),
          });
        } else {
          subscription.tier = plan.tier as SubscriptionTier;
          subscription.status = SubscriptionStatus.PENDING;
        }
        const savedSubscription = await manager
          .getRepository(Subscription)
          .save(subscription);

        // Create pending payment record
        const now = new Date();
        const periodEnd = new Date(now);
        periodEnd.setMonth(
          periodEnd.getMonth() + (billingPeriod === 'yearly' ? 12 : 1),
        );

        const payment = manager.getRepository(SubscriptionPayment).create({
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
        const savedPayment = await manager
          .getRepository(SubscriptionPayment)
          .save(payment);

        const checkoutProviderRef =
          checkoutResult.invoice?.invoice_id ||
          checkoutResult.invoice_id ||
          checkoutResult.id ||
          reference;

        const transaction = manager.getRepository(Transaction).create({
          userId: req.user.userId,
          amount: amountToCharge,
          currency: 'KES',
          type: TransactionType.SUBSCRIPTION,
          status: TransactionStatus.PENDING,
          provider: 'INTASEND',
          providerRef: checkoutProviderRef,
          paymentMethod: PaymentMethodType.PESALINK,
          accountReference: reference,
          metadata: {
            subscriptionPaymentId: savedPayment.id,
            planId: plan.tier,
            billingPeriod,
            reference,
            checkoutProviderRef,
            checkoutUrl: checkoutResult.url,
          },
        });
        await manager.getRepository(Transaction).save(transaction);

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
        const user = await manager.findOne(User, {
          where: { id: req.user.userId },
          lock: { mode: 'pessimistic_write' },
        });
        if (!user) throw new Error('User not found');

        await this.assertNoCompetingPayment(manager, user);

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
        await manager.getRepository(User).update(user.id, {
          walletBalance: Number(user.walletBalance) - amountToCharge,
        });

        // Create/Update Subscription
        let subscription = await manager.getRepository(Subscription).findOne({
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
          subscription = manager.getRepository(Subscription).create({
            userId: req.user.userId,
            tier: plan.tier as SubscriptionTier,
            status: SubscriptionStatus.ACTIVE,
            startDate: now,
            endDate: periodEnd,
            nextBillingDate: periodEnd,
            billingPeriod: billingPeriod,
            lockedPrice: amountToCharge,
            appliedPromoId: appliedPromo?.id ?? null,
            promoDiscountAmount: promoSavings > 0 ? promoSavings : null,
          });
        } else {
          subscription.tier = plan.tier as SubscriptionTier;
          subscription.status = SubscriptionStatus.ACTIVE;
          subscription.updatedAt = new Date();
          subscription.billingPeriod = billingPeriod;
          subscription.endDate = periodEnd;
          subscription.nextBillingDate = periodEnd;
          subscription.lockedPrice = amountToCharge;
          subscription.appliedPromoId = appliedPromo?.id ?? null;
          subscription.promoDiscountAmount =
            promoSavings > 0 ? promoSavings : null;
        }
        const savedSubscription = await manager
          .getRepository(Subscription)
          .save(subscription);
        await manager.getRepository(User).update(req.user.userId, {
          tier: plan.tier as any,
        });

        // Increment promo usage
        if (appliedPromo) {
          await manager
            .getRepository(PromotionalItem)
            .increment({ id: appliedPromo.id }, 'currentUses', 1);
        }

        // Record Payment
        const payment = manager.getRepository(SubscriptionPayment).create({
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
          promoCodeUsed: appliedPromo?.promoCode ?? null,
          promoDiscountAmount: promoSavings > 0 ? promoSavings : null,
          metadata: {
            planId: plan.tier,
            billingPeriod: billingPeriod,
            description: `Subscription to ${plan.name} (${billingPeriod}) via Wallet`,
            promoApplied: appliedPromo
              ? { code: appliedPromo.promoCode, savings: promoSavings }
              : null,
          },
        });
        await manager.getRepository(SubscriptionPayment).save(payment);

        return {
          success: true,
          message: 'Subscription activated via Wallet',
          subscription: savedSubscription,
          promoApplied: appliedPromo
            ? { code: appliedPromo.promoCode, savings: promoSavings }
            : null,
        };
      }

      // 3. Handle Bank Transfers (PesaLink via IntaSend)
      if (body.paymentMethod === 'BANK' && amountToCharge > 0) {
        const user = await manager.findOne(User, {
          where: { id: req.user.userId },
          lock: { mode: 'pessimistic_write' },
        });
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
          reference,
          undefined,
          { method: 'PESALINK', comment: 'Paydome subscription payment' },
        );

        // Return Checkout Info
        return {
          success: true,
          message: 'Bank transfer initiated',
          checkoutUrl: checkout.url,
          reference: reference,
          processingInfo: { estimatedTime: 'Instant via PesaLink' },
        };
      }

      // 4. Handle Free Tier
      if (amountToCharge === 0) {
        let subscription = await manager.getRepository(Subscription).findOne({
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

          const updatedSub = await manager
            .getRepository(Subscription)
            .save(subscription);

          return {
            success: true,
            message: `Downgrade scheduled. Your current plan will remain active until the end of the billing period (${subscription.endDate.toISOString().split('T')[0]}). You will be switched to the Free tier then.`,
            subscription: updatedSub,
          };
        }

        if (!subscription) {
          subscription = manager.getRepository(Subscription).create({
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

        const savedSubscription = await manager
          .getRepository(Subscription)
          .save(subscription);
        await manager.getRepository(User).update(req.user.userId, {
          tier: plan.tier as any,
        });

        return savedSubscription;
      }

      // 4. Fallback / Security Block
      throw new Error(
        'Payment method required for paid plans. Please select Card (Stripe) or M-Pesa.',
      );
    });
  }

  @Get('subscription-payment-history')
  async getSubscriptionPaymentHistory(
    @Request() req: { user: { userId: string } },
  ) {
    // Get all subscription payments for the current user
    const payments = await this.subscriptionPaymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' },
    });

    // Return empty array if no payments found
    return (payments || []).map((payment) => redactProviderSecrets(payment));
  }

  private async getPendingSubscriptionPayment(userId: string) {
    const payment = await this.subscriptionPaymentRepository.findOne({
      where: {
        userId,
        status: PaymentStatus.PENDING,
        paymentProvider: 'INTASEND',
      },
      order: { createdAt: 'DESC' },
    });

    if (!payment) {
      return null;
    }

    return {
      id: payment.id,
      subscriptionId: payment.subscriptionId,
      planId: paymentMetadata(payment.metadata).planId || null,
      amount: Number(payment.amount),
      currency: payment.currency,
      status: payment.status,
      paymentMethod: payment.paymentMethod,
      billingPeriod: payment.billingPeriod,
      dueDate: payment.dueDate,
      periodStart: payment.periodStart,
      periodEnd: payment.periodEnd,
      checkoutUrl: payment.metadata?.checkoutUrl || null,
      reference: payment.metadata?.reference || payment.transactionId,
      isRenewal: !!payment.metadata?.renewal,
      createdAt: payment.createdAt,
    };
  }

  // ============================================================================
  // M-PESA SUBSCRIPTION PAYMENT
  // ============================================================================

  private async buildMpesaQuote(
    userId: string,
    body: SubscribeDto,
    manager: EntityManager,
  ) {
    const plan = SUBSCRIPTION_PLANS.find(
      (candidate) => candidate.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan || plan.tier === 'FREE')
      throw new BadRequestException('Select a paid plan for M-Pesa');
    const linked = await manager.find(Subscription, {
      where: { userId, stripeSubscriptionId: Not(IsNull()) },
    });
    if (
      linked.some(
        (subscription) => subscription.status !== SubscriptionStatus.CANCELLED,
      )
    ) {
      throw new BadRequestException(
        'Manage or cancel the existing Stripe subscription before changing payment methods or plans',
      );
    }
    const subscription = await manager.findOne(Subscription, {
      where: { userId },
      order: { updatedAt: 'DESC' },
    });
    const now = new Date();
    const paidThrough =
      subscription?.endDate &&
      subscription.endDate > now &&
      subscription.tier !== SubscriptionTier.FREE &&
      [SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE].includes(
        subscription.status,
      )
        ? subscription.endDate
        : null;
    if (paidThrough && String(subscription?.tier) !== plan.tier) {
      throw new BadRequestException(
        'Your current paid plan remains active. Choose the same plan to renew, or change plans after it expires.',
      );
    }
    const billingPeriod = body.billingPeriod || 'monthly';
    const originalAmount =
      billingPeriod === 'yearly' ? plan.priceKESYearly : plan.priceKES;
    let amount = originalAmount;
    let promo: PromotionalItem | undefined;
    let savings = 0;
    if (body.promoCode) {
      const user = await manager.findOneBy(User, { id: userId });
      const resolved = await this.resolvePromoCode(
        body.promoCode.trim().toUpperCase(),
        plan.tier,
        user?.tier || 'FREE',
        manager.getRepository(PromotionalItem),
      );
      if (resolved.error || !resolved.promo)
        throw new BadRequestException(resolved.error || 'Invalid promo code');
      promo = resolved.promo;
      const discount = this.applyPromoDiscount(amount, promo);
      amount = discount.discountedAmount;
      savings = discount.savings;
    }
    const periodStart = new Date(paidThrough || now);
    const periodEnd = new Date(periodStart);
    // Clamp month ends, including leap years, to preserve a full billing period.
    const day = periodEnd.getUTCDate();
    periodEnd.setUTCDate(1);
    periodEnd.setUTCMonth(
      periodEnd.getUTCMonth() + (billingPeriod === 'yearly' ? 12 : 1),
    );
    const lastDay = new Date(
      Date.UTC(periodEnd.getUTCFullYear(), periodEnd.getUTCMonth() + 1, 0),
    ).getUTCDate();
    periodEnd.setUTCDate(Math.min(day, lastDay));
    return {
      plan,
      subscription,
      promo,
      savings,
      originalAmount,
      quote: {
        planId: plan.tier,
        billingPeriod,
        amount,
        currency: 'KES',
        periodStart,
        periodEnd,
        renewalMode: 'manual',
      },
    };
  }

  @Post('mpesa-quote')
  async quoteMpesaSubscription(
    @Request() req: { user: { userId: string } },
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    )
    body: SubscribeDto,
  ) {
    const { quote } = await this.buildMpesaQuote(
      req.user.userId,
      body,
      this.subscriptionRepository.manager,
    );
    return quote;
  }

  @Post('mpesa-subscribe')
  async mpesaSubscribe(
    @Request() req: { user: { userId: string } },
    @Body(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    )
    body: MpesaSubscribeDto,
  ) {
    const prepared = await this.withNonStripeBilling(
      req.user.userId,
      async (manager) => {
        const {
          quote,
          subscription: existing,
          promo,
          savings,
          originalAmount,
        } = await this.buildMpesaQuote(req.user.userId, body, manager);
        if (body.expectedAmount !== quote.amount)
          throw new BadRequestException(
            'The amount changed. Review a new M-Pesa quote before paying.',
          );
        const pending = await manager.findOne(SubscriptionPayment, {
          where: {
            userId: req.user.userId,
            status: PaymentStatus.PENDING,
            paymentProvider: 'INTASEND',
          },
          order: { createdAt: 'DESC' },
        });
        if (pending) {
          if (
            pending.paymentMethod !== 'mpesa' ||
            paymentMetadata(pending.metadata).planId !== quote.planId ||
            pending.billingPeriod !== quote.billingPeriod ||
            Number(pending.amount) !== quote.amount
          ) {
            throw new BadRequestException(
              'A subscription payment is already pending. Wait for its result before starting another payment.',
            );
          }
          return {
            initiate: false,
            success: true,
            paymentId: pending.id,
            subscriptionId: pending.subscriptionId,
            amount: Number(pending.amount),
            currency: pending.currency,
            billingPeriod: pending.billingPeriod,
            message:
              'An M-Pesa payment is already pending. Check your phone and payment status.',
          };
        }
        const account = await manager.findOneBy(User, { id: req.user.userId });
        if (!account) throw new NotFoundException('Account not found');
        await this.stripeService.assertNoPayableSubscriptionCheckout(
          req.user.userId,
          account.email,
          account.stripeCustomerId,
        );
        // Keep existing paid access unchanged while the customer approves payment.
        const subscription =
          existing ||
          (await manager.save(
            Subscription,
            manager.create(Subscription, {
              userId: req.user.userId,
              tier: SubscriptionTier.FREE,
              status: SubscriptionStatus.PENDING,
              autoRenewal: false,
              currency: 'KES',
            }),
          ));
        const paymentId = randomUUID();
        const reference = `SUB-${paymentId}`;
        let phoneNumber = body.phoneNumber
          .replace(/^\+/, '')
          .replace(/^0/, '254');
        if (!phoneNumber.startsWith('254')) phoneNumber = `254${phoneNumber}`;
        const payment = manager.create(SubscriptionPayment, {
          id: paymentId,
          subscriptionId: subscription.id,
          userId: req.user.userId,
          amount: quote.amount,
          currency: 'KES',
          status: PaymentStatus.PENDING,
          paymentMethod: PaymentMethod.MPESA,
          billingPeriod: quote.billingPeriod,
          periodStart: quote.periodStart,
          periodEnd: quote.periodEnd,
          dueDate: new Date(),
          paymentProvider: 'INTASEND',
          promoCodeUsed: promo?.promoCode ?? null,
          promoDiscountAmount: savings || null,
          metadata: {
            planId: quote.planId,
            targetTier: quote.planId,
            reference,
            renewalMode: 'manual',
            originalAmount,
            promoId: promo?.id,
            phoneNumber,
          },
        });
        if (quote.amount === 0 && promo) {
          payment.status = PaymentStatus.COMPLETED;
          payment.paidDate = new Date();
          payment.metadata = {
            ...paymentMetadata(payment.metadata),
            entitlementApplied: true,
          };
          Object.assign(subscription, {
            tier: quote.planId,
            status: SubscriptionStatus.ACTIVE,
            billingPeriod: quote.billingPeriod,
            amount: 0,
            lockedPrice: 0,
            currency: 'KES',
            startDate: quote.periodStart,
            endDate: quote.periodEnd,
            nextBillingDate: quote.periodEnd,
            autoRenewal: false,
            pendingTier: null,
            gracePeriodEndDate: null,
            appliedPromoId: promo.id,
            promoDiscountAmount: savings,
          });
          await manager.save(Subscription, subscription);
          await manager.update(User, req.user.userId, {
            tier: quote.planId as UserTier,
          });
          await manager.increment(
            PromotionalItem,
            { id: promo.id },
            'currentUses',
            1,
          );
          await manager.save(SubscriptionPayment, payment);
          return {
            initiate: false,
            success: true,
            paymentId,
            subscriptionId: subscription.id,
            ...quote,
            message: 'Subscription activated with your promotion.',
          };
        }
        // Commit correlation before the provider side effect. A timeout must not
        // erase a request that may already be on the customer's phone.
        await manager.save(SubscriptionPayment, payment);
        await manager.save(
          Transaction,
          manager.create(Transaction, {
            id: paymentId,
            userId: req.user.userId,
            amount: quote.amount,
            currency: 'KES',
            type: TransactionType.SUBSCRIPTION,
            status: TransactionStatus.PENDING,
            provider: 'INTASEND',
            accountReference: reference,
            paymentMethod: PaymentMethodType.MPESA_STK,
            recipientPhone: phoneNumber,
            metadata: {
              subscriptionPaymentId: paymentId,
              planId: quote.planId,
              billingPeriod: quote.billingPeriod,
            },
          }),
        );
        return {
          initiate: true,
          success: true,
          paymentId,
          subscriptionId: subscription.id,
          amount: quote.amount,
          currency: 'KES',
          billingPeriod: quote.billingPeriod,
          message:
            'Check your phone and approve the M-Pesa payment with your PIN.',
        };
      },
    );
    const { initiate, ...response } = prepared;
    if (!initiate) return response;
    let phoneNumber = body.phoneNumber.replace(/^\+/, '').replace(/^0/, '254');
    if (!phoneNumber.startsWith('254')) phoneNumber = `254${phoneNumber}`;
    try {
      const result: unknown = await this.intaSendService.initiateStkPush(
        phoneNumber,
        response.amount,
        `SUB-${response.paymentId}`,
      );
      const invoiceId = (
        result as { invoice?: { invoice_id?: unknown } } | null
      )?.invoice?.invoice_id;
      if (typeof invoiceId !== 'string' || !invoiceId)
        throw new Error('Missing provider invoice');
      await this.subscriptionRepository.manager.transaction(async (manager) => {
        await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
          `stripe-billing:${req.user.userId}`,
        ]);
        const payment = await manager.findOneByOrFail(SubscriptionPayment, {
          id: response.paymentId,
        });
        const transaction = await manager.findOneByOrFail(Transaction, {
          id: response.paymentId,
        });
        if (transaction.providerRef && transaction.providerRef !== invoiceId)
          throw new Error('Provider invoice mismatch');
        transaction.providerRef = invoiceId;
        payment.transactionId = invoiceId;
        payment.metadata = {
          ...paymentMetadata(payment.metadata),
          intaSendInvoiceId: invoiceId,
        };
        await manager.save(Transaction, transaction);
        await manager.save(SubscriptionPayment, payment);
      });
      return response;
    } catch (error: unknown) {
      if (error instanceof IntaSendStkPushError && error.definitiveFailure) {
        await this.subscriptionRepository.manager.transaction(
          async (manager) => {
            await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
              `stripe-billing:${req.user.userId}`,
            ]);
            await manager.update(
              SubscriptionPayment,
              { id: response.paymentId, status: PaymentStatus.PENDING },
              { status: PaymentStatus.FAILED },
            );
            await manager.update(
              Transaction,
              { id: response.paymentId, status: TransactionStatus.PENDING },
              { status: TransactionStatus.FAILED },
            );
          },
        );
        throw new BadRequestException(
          'The M-Pesa request was rejected. Your current subscription is unchanged. Review your phone number and try again.',
        );
      }
      this.logger.warn(
        'M-Pesa subscription initiation outcome is unknown; awaiting provider confirmation',
      );
      return {
        ...response,
        message:
          'Awaiting M-Pesa confirmation. Check your phone and payment status before trying again.',
      };
    }
  }

  // ============================================================================
  // SUBSCRIPTION USAGE
  // ============================================================================

  @Get('usage')
  async getUsage(@Request() req: { user: { userId: string } }) {
    // Get worker count for the current user
    const workerCount = await this.workersService.getWorkerCount(
      req.user.userId,
    );

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
        percentage: Math.min(
          100,
          Math.round((workerCount / workerLimit) * 100),
        ),
      },
      tier: tier,
      planName: plan?.name || 'Free',
    };
  }

  @Get('mpesa-payment-status/:paymentId')
  async checkMpesaPaymentStatus(
    @Request() req: { user: { userId: string } },
    @Param('paymentId') paymentId: string,
  ) {
    const payment = await this.subscriptionPaymentRepository.findOne({
      where: { id: paymentId, userId: req.user.userId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    const subscription = await this.subscriptionRepository.findOneBy({
      id: payment.subscriptionId,
      userId: req.user.userId,
    });
    // Polling is read-only; only verified provider settlement grants entitlement.
    return {
      entitlementActive:
        payment.status === PaymentStatus.COMPLETED &&
        paymentMetadata(payment.metadata).entitlementApplied === true &&
        subscription?.status === SubscriptionStatus.ACTIVE &&
        !!subscription.endDate &&
        subscription.endDate > new Date(),
      paymentId: payment.id,
      status: payment.status,
      amount: Number(payment.amount),
      currency: payment.currency,
      paidDate: payment.paidDate,
    };
  }
}
