import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Subscription, SubscriptionStatus } from './entities/subscription.entity';
import { SubscriptionPayment } from './entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';

@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  constructor(
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private subscriptionPaymentRepository: Repository<SubscriptionPayment>,
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
    features.forEach(feature => {
      const key = feature.toLowerCase()
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
        status: SubscriptionStatus.ACTIVE
      },
      relations: ['user']
    });

    // Return free tier if no active subscription found
    if (!subscription) {
      // Get full user data
      const userData = await this.subscriptionRepository.manager.findOne('users', {
        where: { id: req.user.userId }
      });

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
      planName: SUBSCRIPTION_PLANS.find(p => p.tier === subscription.tier)?.name || 'Unknown Plan'
    };
  }

  @Post('subscribe')
  async subscribe(@Request() req: any, @Body() body: { planId: string }) {
    // TODO: Implement actual payment integration
    // For now, just update/create subscription record

    const plan = SUBSCRIPTION_PLANS.find(p => p.tier.toLowerCase() === body.planId.toLowerCase());
    if (!plan) {
      throw new Error('Invalid plan ID');
    }

    let subscription = await this.subscriptionRepository.findOne({
      where: { userId: req.user.userId }
    });

    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        userId: req.user.userId,
        tier: plan.tier,
        status: SubscriptionStatus.ACTIVE,
        startDate: new Date(),
      });
    } else {
      subscription.tier = plan.tier;
      subscription.status = SubscriptionStatus.ACTIVE;
      subscription.updatedAt = new Date();
    }

    return this.subscriptionRepository.save(subscription);
  }

  @Get('subscription-payment-history')
  async getSubscriptionPaymentHistory(@Request() req: any) {
    // Get all subscription payments for the current user
    const payments = await this.subscriptionPaymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' }
    });

    // Return empty array if no payments found
    return payments || [];
  }
}
