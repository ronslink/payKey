import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StripeService } from './stripe.service';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from '../subscriptions/subscription-plans.config';

@Controller('payments/subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionPaymentsController {
  constructor(
    private stripeService: StripeService,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private paymentRepository: Repository<SubscriptionPayment>,
  ) {}

  @Get('plans')
  getPlans() {
    return SUBSCRIPTION_PLANS.map((plan, index) => ({
      id: plan.tier.toLowerCase(),
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

  @Get('current')
  async getCurrentSubscription(@Request() req: any) {
    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId: req.user.userId,
        status: 'ACTIVE' as any,
      },
      relations: ['user'],
    });

    if (!subscription) {
      const userData = await this.subscriptionRepository.manager.findOne(
        'users',
        {
          where: { id: req.user.userId },
        },
      );

      return {
        id: null,
        tier: 'FREE',
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

  @Post('checkout')
  async createCheckoutSession(
    @Request() req: any,
    @Body() body: { planId: string },
  ) {
    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan) {
      throw new Error('Invalid plan ID');
    }

    const checkoutSession = await this.stripeService.createCheckoutSession(
      req.user.userId,
      plan.tier,
      req.user.email,
      req.user.name || req.user.email,
    );

    return {
      sessionId: checkoutSession.sessionId,
      checkoutUrl: checkoutSession.url,
    };
  }

  @Put(':id/cancel')
  async cancelSubscription(
    @Request() req: any,
    @Param('id') subscriptionId: string,
  ) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { id: subscriptionId, userId: req.user.userId },
    });

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    await this.stripeService.cancelSubscription(req.user.userId);

    return {
      message: 'Subscription cancelled successfully',
    };
  }

  @Get('payment-history')
  async getPaymentHistory(@Request() req: any) {
    const payments = await this.paymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' },
    });

    return payments || [];
  }

  @Get('usage')
  async getUsage(@Request() req: any) {
    const subscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId, status: 'ACTIVE' as any },
    });

    if (!subscription) {
      return {
        currentPlan: 'FREE',
        workerUsage: 1,
        workerLimit: 1,
        usagePercentage: 100,
      };
    }

    // Get current worker count (this would come from actual worker table)
    const currentWorkers = 1; // Mock data
    const plan = SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier);
    const limit = plan?.workerLimit || 1;

    return {
      currentPlan: subscription.tier,
      workerUsage: currentWorkers,
      workerLimit: limit,
      usagePercentage: Math.round((currentWorkers / limit) * 100),
    };
  }

  @Get('stripe-status')
  async getStripeStatus() {
    const accountInfo = await this.stripeService.getAccountInfo();
    return accountInfo;
  }

  @Post('webhook')
  async handleWebhook(@Body() body: any) {
    try {
      const event = body;
      await this.stripeService.handleWebhook(event);
      return { received: true };
    } catch (error) {
      return { error: error.message };
    }
  }
}
