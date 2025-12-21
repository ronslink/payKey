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
import { SubscriptionPayment, PaymentStatus, PaymentMethod } from './entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';
import { UsersService } from '../users/users.service';
import { MpesaService } from '../payments/mpesa.service';

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
    private mpesaService: MpesaService,
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
    const currentPlanCredit = Math.round((currentPlanPrice / daysInPeriod) * daysRemaining);

    // Charge for new plan for remaining days
    const newPlanCharge = Math.round((newPlanPrice / daysInPeriod) * daysRemaining);

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
    const currentPlanIndex = SUBSCRIPTION_PLANS.findIndex((p) => p.tier === subscription.tier);
    const newPlanIndex = SUBSCRIPTION_PLANS.findIndex((p) => p.tier === newPlan.tier);

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
      };
    }

    return {
      ...subscription,
      planName:
        SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier)?.name ||
        'Unknown Plan',
    };
  }

  @Post('subscribe')
  async subscribe(@Request() req: any, @Body() body: { planId: string; paymentMethod?: string }) {
    // TODO: Implement actual payment integration (Stripe / M-Pesa)
    // For now, just update/create subscription record and User tier

    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan) {
      throw new Error('Invalid plan ID');
    }

    let subscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId },
    });

    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        userId: req.user.userId,
        tier: plan.tier as SubscriptionTier,
        status: SubscriptionStatus.ACTIVE,
        startDate: new Date(),
      });
    } else {
      subscription.tier = plan.tier as SubscriptionTier;
      subscription.status = SubscriptionStatus.ACTIVE;
      subscription.updatedAt = new Date();
    }

    const savedSubscription = await this.subscriptionRepository.save(subscription);

    // CRITICAL FIX: Also update the User entity's tier to ensure checks against User work
    await this.usersService.update(req.user.userId, { tier: plan.tier as any });

    return savedSubscription;
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
    @Body() body: { planId: string; phoneNumber: string },
  ) {
    const { planId, phoneNumber } = body;

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
    let existingSubscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId, status: SubscriptionStatus.ACTIVE },
    });

    let amountToCharge = plan.priceKES;
    let isProrated = false;
    let prorationDetails: any = null;

    // Calculate proration if upgrading from an existing paid plan
    if (existingSubscription && existingSubscription.tier !== 'FREE') {
      const currentPlanIndex = SUBSCRIPTION_PLANS.findIndex((p) => p.tier === existingSubscription.tier);
      const newPlanIndex = SUBSCRIPTION_PLANS.findIndex((p) => p.tier === plan.tier);

      // Only prorate for upgrades
      if (newPlanIndex > currentPlanIndex) {
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

    this.logger.log(`Initiating M-Pesa subscription for ${formattedPhone}, plan: ${plan.name}, amount: KES ${amountToCharge} (prorated: ${isProrated})`);

    // If amount is 0 (e.g., prorated upgrade with credit), activate immediately
    if (amountToCharge <= 0) {
      if (existingSubscription) {
        existingSubscription.tier = plan.tier as SubscriptionTier;
        existingSubscription.status = SubscriptionStatus.ACTIVE;
        await this.subscriptionRepository.save(existingSubscription);
        await this.usersService.update(req.user.userId, { tier: plan.tier as any });
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
    const savedSubscription = await this.subscriptionRepository.save(subscription);

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

    try {
      // Initiate STK Push
      const stkResult = await this.mpesaService.initiateStkPush(
        req.user.userId,
        formattedPhone,
        plan.priceKES,
        `PayKey-${plan.tier}`,
        `${plan.name} Subscription`,
      );

      // Update payment with checkout request ID
      await this.subscriptionPaymentRepository.update(savedPayment.id, {
        transactionId: stkResult.CheckoutRequestID,
        metadata: {
          ...savedPayment.metadata,
          checkoutRequestId: stkResult.CheckoutRequestID,
          merchantRequestId: stkResult.MerchantRequestID,
        },
      });

      return {
        success: true,
        message: 'STK Push sent to your phone. Please enter your M-Pesa PIN.',
        paymentId: savedPayment.id,
        checkoutRequestId: stkResult.CheckoutRequestID,
        subscriptionId: savedSubscription.id,
      };
    } catch (error) {
      this.logger.error('M-Pesa STK Push failed:', error);

      // Mark payment as failed
      await this.subscriptionPaymentRepository.update(savedPayment.id, {
        status: PaymentStatus.FAILED,
        notes: error.message,
      });

      throw new Error(`M-Pesa payment initiation failed: ${error.message}`);
    }
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
          await this.usersService.update(req.user.userId, { tier: plan.tier as any });
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

