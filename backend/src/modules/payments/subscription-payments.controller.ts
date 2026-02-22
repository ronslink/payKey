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
} from '@nestjs/common';
import type { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StripeService } from './stripe.service';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
import { SUBSCRIPTION_PLANS } from '../subscriptions/subscription-plans.config';

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
  @UseGuards(JwtAuthGuard)
  async getPaymentHistory(@Request() req: any) {
    const payments = await this.paymentRepository.find({
      where: { userId: req.user.userId },
      order: { createdAt: 'DESC' },
    });

    return payments || [];
  }

  @Get('usage')
  @UseGuards(JwtAuthGuard)
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

  /**
   * Stripe webhook — this route is registered in the Stripe Dashboard as:
   *   https://api.paydome.co/payments/subscriptions/webhook
   * Requires a valid stripe-signature header; delegates to the same
   * verified handler used by POST /payments/stripe/webhook.
   */
  @Post('webhook')
  async handleWebhook(
    @Headers('stripe-signature') signature: string,
    @Request() req: any,
  ) {
    this.logger.log('🔵 Stripe Webhook received at /payments/subscriptions/webhook');

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
  async handleSuccess(
    @Query('session_id') sessionId: string,
    @Res() res: Response,
  ) {
    // Deep-link back into the Flutter app via custom URI scheme.
    // The app registers paykey://subscription/success and handles
    // the session_id to confirm activation on the client side.
    const deepLink = `paykey://subscription/success?session_id=${sessionId || ''}`;

    const html = `
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Payment Successful — PayKey</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="refresh" content="3;url=${deepLink}">
          <style>
            *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              display: flex; justify-content: center; align-items: center;
              min-height: 100vh; background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
              padding: 20px;
            }
            .card {
              background: white; border-radius: 20px; padding: 48px 40px;
              box-shadow: 0 20px 60px rgba(0,0,0,0.08); max-width: 420px; width: 100%;
              text-align: center; animation: slideUp 0.4s ease;
            }
            @keyframes slideUp {
              from { opacity: 0; transform: translateY(20px); }
              to   { opacity: 1; transform: translateY(0); }
            }
            .icon-circle {
              width: 80px; height: 80px; border-radius: 50%;
              background: #dcfce7; display: flex; align-items: center;
              justify-content: center; margin: 0 auto 24px; font-size: 40px;
            }
            h1 { font-size: 24px; font-weight: 700; color: #111827; margin-bottom: 12px; }
            .sub { font-size: 15px; color: #6b7280; line-height: 1.6; margin-bottom: 32px; }
            .btn {
              display: inline-block; background: #16a34a; color: white;
              padding: 14px 32px; border-radius: 10px; text-decoration: none;
              font-size: 15px; font-weight: 600; transition: background 0.2s;
            }
            .btn:hover { background: #15803d; }
            .hint { font-size: 13px; color: #9ca3af; margin-top: 20px; }
            .brand { font-size: 13px; color: #9ca3af; margin-top: 32px; letter-spacing: 0.05em; font-weight: 600; }
          </style>
          <script>
            // Auto-attempt deep link on load; page will auto-close if the app handles it
            window.onload = function() {
              window.location.href = '${deepLink}';
            };
          </script>
        </head>
        <body>
          <div class="card">
            <div class="icon-circle">✅</div>
            <h1>Payment Successful!</h1>
            <p class="sub">
              Your subscription has been activated. You'll be redirected back
              to the PayKey app automatically.
            </p>
            <a href="${deepLink}" class="btn">Return to PayKey App</a>
            <p class="hint">If the app doesn't open, tap the button above.</p>
            <p class="brand">PAYKEY</p>
          </div>
        </body>
      </html>
    `;
    res.send(html);
  }

  @Get('cancel')
  async handleCancel(@Res() res: Response) {
    const deepLink = `paykey://subscription/cancel`;

    const html = `
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>Payment Cancelled — PayKey</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="refresh" content="3;url=${deepLink}">
          <style>
            *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              display: flex; justify-content: center; align-items: center;
              min-height: 100vh; background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
              padding: 20px;
            }
            .card {
              background: white; border-radius: 20px; padding: 48px 40px;
              box-shadow: 0 20px 60px rgba(0,0,0,0.08); max-width: 420px; width: 100%;
              text-align: center; animation: slideUp 0.4s ease;
            }
            @keyframes slideUp {
              from { opacity: 0; transform: translateY(20px); }
              to   { opacity: 1; transform: translateY(0); }
            }
            .icon-circle {
              width: 80px; height: 80px; border-radius: 50%;
              background: #fee2e2; display: flex; align-items: center;
              justify-content: center; margin: 0 auto 24px; font-size: 40px;
            }
            h1 { font-size: 24px; font-weight: 700; color: #111827; margin-bottom: 12px; }
            .sub { font-size: 15px; color: #6b7280; line-height: 1.6; margin-bottom: 32px; }
            .btn {
              display: inline-block; background: #374151; color: white;
              padding: 14px 32px; border-radius: 10px; text-decoration: none;
              font-size: 15px; font-weight: 600;
            }
            .hint { font-size: 13px; color: #9ca3af; margin-top: 20px; }
            .brand { font-size: 13px; color: #9ca3af; margin-top: 32px; letter-spacing: 0.05em; font-weight: 600; }
          </style>
          <script>
            window.onload = function() {
              window.location.href = '${deepLink}';
            };
          </script>
        </head>
        <body>
          <div class="card">
            <div class="icon-circle">❌</div>
            <h1>Payment Cancelled</h1>
            <p class="sub">
              No charges were made. You can return to PayKey and
              try again whenever you're ready.
            </p>
            <a href="${deepLink}" class="btn">Return to PayKey App</a>
            <p class="hint">If the app doesn't open, tap the button above.</p>
            <p class="brand">PAYKEY</p>
          </div>
        </body>
      </html>
    `;
    res.send(html);
  }
}
