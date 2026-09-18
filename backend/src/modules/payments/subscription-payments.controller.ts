import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  Request,
  Headers,
  UseGuards,
  Res,
  UnauthorizedException,
  Logger,
  BadRequestException,
  Header,
} from '@nestjs/common';
import type { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StripeService } from './stripe.service';
import { User } from '../users/entities/user.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from '../subscriptions/subscription-plans.config';
import { redactProviderSecrets } from '../../common/security/provider-secrets';

@Controller('payments/subscriptions')
export class SubscriptionPaymentsController {
  private readonly logger = new Logger(SubscriptionPaymentsController.name);

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
  @UseGuards(JwtAuthGuard)
  async getCurrentSubscription(@Request() req: { user: { userId: string } }) {
    const subscription = await this.subscriptionRepository.findOne({
      where: {
        userId: req.user.userId,
        status: 'ACTIVE' as any,
      },
      relations: ['user'],
    });

    if (!subscription) {
      const userData = await this.subscriptionRepository.manager.findOne(User, {
        where: { id: req.user.userId },
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
        user: this.publicUser(userData),
      };
    }

    return {
      ...subscription,
      user: this.publicUser(subscription.user),
      planName:
        SUBSCRIPTION_PLANS.find((p) => p.tier === subscription.tier)?.name ||
        'Unknown Plan',
    };
  }

  private publicUser(user: User | null | undefined) {
    if (!user) return undefined;
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      tier: user.tier,
    };
  }

  @Post('checkout')
  @UseGuards(JwtAuthGuard)
  async createCheckoutSession(
    @Request() req: { user: { userId: string } },
    @Body() body: { planId: string },
  ) {
    if (typeof body?.planId !== 'string')
      throw new BadRequestException('Invalid plan ID');
    const plan = SUBSCRIPTION_PLANS.find(
      (p) => p.tier.toLowerCase() === body.planId.toLowerCase(),
    );
    if (!plan) {
      throw new BadRequestException('Invalid plan ID');
    }

    const user = await this.subscriptionRepository.manager.findOne(User, {
      where: { id: req.user.userId },
    });
    if (!user) throw new UnauthorizedException('Account not found');
    const checkoutSession = await this.stripeService.createCheckoutSession(
      req.user.userId,
      plan.tier,
      user.email,
      [user.firstName, user.lastName].filter(Boolean).join(' '),
    );

    return {
      sessionId: checkoutSession.sessionId,
      checkoutUrl: checkoutSession.url,
    };
  }

  @Put(':id/cancel')
  @UseGuards(JwtAuthGuard)
  async cancelSubscription(
    @Request() req: { user: { userId: string } },
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
  @UseGuards(JwtAuthGuard)
  async getPaymentHistory(@Request() req: { user: { userId: string } }) {
    const payments = await this.paymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' },
    });

    return (payments || []).map((payment) => redactProviderSecrets(payment));
  }

  @Get('checkout-status/:sessionId')
  @UseGuards(JwtAuthGuard)
  @Header('Cache-Control', 'private, no-store')
  async getCheckoutStatus(
    @Request() req: { user: { userId: string } },
    @Param('sessionId') sessionId: string,
  ) {
    return this.stripeService.getCheckoutStatus(req.user.userId, sessionId);
  }

  @Get('usage')
  @UseGuards(JwtAuthGuard)
  async getUsage(@Request() req: { user: { userId: string } }) {
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

  /**
   * Stripe webhook — this route is registered in the Stripe Dashboard as:
   *   https://api.paydome.co/payments/subscriptions/webhook
   * Requires a valid stripe-signature header; delegates to the same
   * verified handler used by POST /payments/stripe/webhook.
   */
  @Post('webhook')
  async handleWebhook(
    @Headers('stripe-signature') signature: string,
    @Request() req: { rawBody: Buffer },
  ) {
    this.logger.log(
      '🔵 Stripe Webhook received at /payments/subscriptions/webhook',
    );

    if (!signature) {
      this.logger.warn('Missing stripe-signature header');
      throw new UnauthorizedException('Missing Stripe signature');
    }

    try {
      const event = this.stripeService.constructEvent(req.rawBody, signature);
      await this.stripeService.handleWebhook(event);
      return { received: true };
    } catch (error) {
      this.logger.error('Stripe Webhook Error:', error.message);
      throw new UnauthorizedException(`Webhook Error: ${error.message}`);
    }
  }

  @Get('success')
  handleSuccess(@Query('session_id') sessionId: string, @Res() res: Response) {
    return res.redirect(
      303,
      this.stripeService.billingReturnUrl(
        'success',
        typeof sessionId === 'string' ? sessionId : undefined,
      ),
    );
  }

  @Get('cancel')
  handleCancel(@Res() res: Response) {
    return res.redirect(303, this.stripeService.billingReturnUrl('cancel'));
  }
}
