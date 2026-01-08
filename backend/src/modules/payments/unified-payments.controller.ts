import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Request,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StripeService } from './stripe.service';
import { MpesaService } from './mpesa.service';
import { IntaSendService } from './intasend.service';
import { Transaction, TransactionStatus } from './entities/transaction.entity';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { PaymentMethod } from '../tax-payments/entities/tax-payment.entity';
import { TaxType } from '../tax-config/entities/tax-config.entity';

// ============================================================================
// Types & Interfaces
// ============================================================================

interface AuthenticatedRequest {
  user: {
    userId: string;
    email: string;
    name?: string;
  };
}

interface TransactionStats {
  total: number;
  successful: number;
  pending: number;
  failed: number;
  totalAmount: number;
}

interface PaymentMethodStatus {
  mpesa: {
    status: 'connected' | 'disconnected';
    balance: number;
  };
  stripe: {
    status: 'connected' | 'not_configured';
    accountConnected: boolean;
  };
}

interface SubscriptionInfo {
  currentPlan: SubscriptionTier;
  nextBilling: Date | null;
  amount: number;
}

interface TaxPaymentInfo {
  totalDue: number;
  nextDeadline: string;
  pendingPayments: number;
}

interface PaymentDashboardData {
  overview: {
    totalTransactions: number;
    totalAmount: number;
    successfulTransactions: number;
    pendingTransactions: number;
    failedTransactions: number;
    subscriptionsActive: number;
    taxPaymentsPending: number;
  };
  recentTransactions: Transaction[];
  paymentMethods: PaymentMethodStatus;
  subscription: SubscriptionInfo;
  taxPayments: TaxPaymentInfo;
}

interface CreateSubscriptionDto {
  planId: string;
  paymentMethod: 'stripe';
}

interface MpesaTopupDto {
  phoneNumber: string;
  amount: number;
  accountReference?: string;
  transactionDesc?: string;
}

interface RecordTaxPaymentDto {
  taxType: TaxType;
  amount: number;
  paymentDate?: string;
  reference: string;
}

interface StripeAccountInfo {
  connected: boolean;
  charges_enabled: boolean;
  payouts_enabled: boolean;
  id: string;
}

// ============================================================================
// Controller
// ============================================================================

@Controller('payments/unified')
@UseGuards(JwtAuthGuard)
export class UnifiedPaymentsController {
  private static readonly DEFAULT_STRIPE_ACCOUNT: StripeAccountInfo = {
    connected: false,
    charges_enabled: false,
    payouts_enabled: false,
    id: '',
  };

  constructor(
    private readonly stripeService: StripeService,
    private readonly mpesaService: MpesaService,
    private readonly taxPaymentsService: TaxPaymentsService,
    @InjectRepository(Transaction)
    private readonly transactionRepository: Repository<Transaction>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(SubscriptionPayment)
    private readonly subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    private readonly intaSendService: IntaSendService,
  ) {}

  // ==========================================================================
  // Public Endpoints
  // ==========================================================================

  @Get('dashboard')
  async getDashboard(
    @Request() req: AuthenticatedRequest,
  ): Promise<PaymentDashboardData> {
    const { userId } = req.user;
    const currentDate = new Date();

    // Execute all queries in parallel
    const [
      transactionStats,
      recentTransactions,
      activeSubscriptionCount,
      currentSubscription,
      monthlyTaxSummary,
    ] = await Promise.all([
      this.getTransactionStats(userId),
      this.getRecentTransactions(userId),
      this.getActiveSubscriptionCount(userId),
      this.getActiveSubscription(userId),
      this.taxPaymentsService.generateMonthlySummary(
        userId,
        currentDate.getFullYear(),
        currentDate.getMonth() + 1,
      ),
    ]);

    const pendingTaxPayments = this.countPendingTaxPayments(
      monthlyTaxSummary.taxes,
    );

    return {
      overview: {
        totalTransactions: transactionStats.total,
        totalAmount: transactionStats.totalAmount,
        successfulTransactions: transactionStats.successful,
        pendingTransactions: transactionStats.pending,
        failedTransactions: transactionStats.failed,
        subscriptionsActive: activeSubscriptionCount,
        taxPaymentsPending: pendingTaxPayments,
      },
      recentTransactions,
      paymentMethods: this.buildPaymentMethodStatus(),
      subscription: this.buildSubscriptionInfo(currentSubscription),
      taxPayments: {
        totalDue: monthlyTaxSummary.totalDue,
        nextDeadline: monthlyTaxSummary.paymentInstructions.deadline,
        pendingPayments: pendingTaxPayments,
      },
    };
  }

  @Post('subscribe')
  async createSubscription(
    @Request() req: AuthenticatedRequest,
    @Body() body: CreateSubscriptionDto,
  ): Promise<{ checkoutUrl: string }> {
    const { userId, email, name } = req.user;

    try {
      const normalizedPlanId = body.planId.toUpperCase();
      const checkoutSession = await this.stripeService.createCheckoutSession(
        userId,
        normalizedPlanId,
        email,
        name || email,
      );

      return { checkoutUrl: checkoutSession.url };
    } catch (error) {
      this.throwBadRequest(error, 'Failed to create subscription');
    }
  }

  @Put('subscriptions/:id/cancel')
  async cancelSubscription(
    @Request() req: AuthenticatedRequest,
    @Param('id') subscriptionId: string,
  ): Promise<{ message: string }> {
    const { userId } = req.user;

    const subscription = await this.subscriptionRepository.findOne({
      where: { id: subscriptionId, userId },
    });

    if (!subscription) {
      throw new HttpException('Subscription not found', HttpStatus.NOT_FOUND);
    }

    try {
      await this.stripeService.cancelSubscription(userId);
      return { message: 'Subscription cancelled successfully' };
    } catch (error) {
      this.throwBadRequest(error, 'Failed to cancel subscription');
    }
  }

  @Post('mpesa/topup')
  async initiateMpesaTopup(
    @Request() req: AuthenticatedRequest,
    @Body() body: MpesaTopupDto,
  ): Promise<{ success: boolean; checkoutRequestId: string; message: string }> {
    const { userId } = req.user;

    try {
      const result = await this.mpesaService.initiateStkPush(
        userId,
        body.phoneNumber,
        body.amount,
        body.accountReference,
        body.transactionDesc,
      );

      return {
        success: true,
        checkoutRequestId: result.CheckoutRequestID,
        message: 'STK push initiated successfully',
      };
    } catch (error) {
      this.throwBadRequest(error, 'Failed to initiate M-Pesa topup');
    }
  }

  @Post('tax-payments/record')
  async recordTaxPayment(
    @Request() req: AuthenticatedRequest,
    @Body() body: RecordTaxPaymentDto,
  ): Promise<{ success: boolean; paymentId: string; message: string }> {
    const { userId } = req.user;
    const now = new Date();

    try {
      const taxPayment = await this.taxPaymentsService.recordPayment(userId, {
        taxType: body.taxType,
        paymentYear: now.getFullYear(),
        paymentMonth: now.getMonth() + 1,
        amount: body.amount,
        paymentDate: body.paymentDate
          ? new Date(body.paymentDate).toISOString().split('T')[0]
          : undefined,
        paymentMethod: PaymentMethod.BANK,
        receiptNumber: body.reference || 'manual-entry',
      });

      return {
        success: true,
        paymentId: taxPayment.id,
        message: 'Tax payment successful',
      };
    } catch (error) {
      this.throwBadRequest(error, 'Failed to record tax payment');
    }
  }

  @Get('tax-payments/summary')
  async getTaxPaymentSummary(@Request() req: AuthenticatedRequest) {
    const { userId } = req.user;
    const now = new Date();

    try {
      return await this.taxPaymentsService.generateMonthlySummary(
        userId,
        now.getFullYear(),
        now.getMonth() + 1,
      );
    } catch (error) {
      this.throwBadRequest(error, 'Failed to get tax payment summary');
    }
  }

  @Get('methods')
  async getPaymentMethods(@Request() req: AuthenticatedRequest) {
    const { userId } = req.user;

    const activeSubscription = await this.getActiveSubscription(userId);

    return {
      stripe: {
        configured: false,
        accountId: '',
        chargesEnabled: false,
        payoutsEnabled: false,
      },
      mpesa: {
        configured: true,
        shortcode: process.env.MPESA_SHORTCODE || '174379',
      },
      subscription: {
        active: !!activeSubscription,
        tier: activeSubscription?.tier,
        status: activeSubscription?.status,
      },
    };
  }

  @Get('wallet')
  async getWalletBalance(@Request() req: AuthenticatedRequest) {
    // In production or if configured, use IntaSend wallet
    try {
      const wallet = await this.intaSendService.getWalletBalance();
      // Transform if necessary to match expected frontend structure, or return generic
      return wallet;
    } catch (error) {
      // Fallback to M-Pesa dummy if IntaSend fails or not configured?
      // For now, return error or dummy.
      return {
        available_balance: 0,
        currency: 'KES',
        can_disburse: true,
      };
    }
  }

  // ==========================================================================
  // Private Helper Methods
  // ==========================================================================

  private async getTransactionStats(userId: string): Promise<TransactionStats> {
    const stats = await this.transactionRepository
      .createQueryBuilder('t')
      .select([
        'COUNT(*) as total',
        `SUM(CASE WHEN t.status = :success THEN 1 ELSE 0 END) as successful`,
        `SUM(CASE WHEN t.status = :pending THEN 1 ELSE 0 END) as pending`,
        `SUM(CASE WHEN t.status = :failed THEN 1 ELSE 0 END) as failed`,
        `COALESCE(SUM(CASE WHEN t.status = :success THEN t.amount ELSE 0 END), 0) as totalAmount`,
      ])
      .where('t.userId = :userId', { userId })
      .setParameters({
        success: TransactionStatus.SUCCESS,
        pending: TransactionStatus.PENDING,
        failed: TransactionStatus.FAILED,
      })
      .getRawOne();

    return {
      total: parseInt(stats.total, 10) || 0,
      successful: parseInt(stats.successful, 10) || 0,
      pending: parseInt(stats.pending, 10) || 0,
      failed: parseInt(stats.failed, 10) || 0,
      totalAmount: parseFloat(stats.totalAmount) || 0,
    };
  }

  private async getRecentTransactions(
    userId: string,
    limit = 10,
  ): Promise<Transaction[]> {
    return this.transactionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  private async getActiveSubscriptionCount(userId: string): Promise<number> {
    return this.subscriptionRepository.count({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });
  }

  private async getActiveSubscription(
    userId: string,
  ): Promise<Subscription | null> {
    return this.subscriptionRepository.findOne({
      where: { userId, status: SubscriptionStatus.ACTIVE },
    });
  }

  /**
   * Count pending tax payments from the tax summary.
   * Accepts status as string since TaxSummaryDto uses string type.
   */
  private countPendingTaxPayments(taxes: Array<{ status: string }>): number {
    return taxes.filter((t) => t.status === PaymentStatus.PENDING.toString())
      .length;
  }

  private buildPaymentMethodStatus(): PaymentMethodStatus {
    return {
      mpesa: {
        status: 'connected',
        balance: 0,
      },
      stripe: {
        status: 'not_configured',
        accountConnected: false,
      },
    };
  }

  private buildSubscriptionInfo(
    subscription: Subscription | null,
  ): SubscriptionInfo {
    return {
      currentPlan: subscription?.tier ?? SubscriptionTier.FREE,
      nextBilling: subscription?.nextBillingDate ?? null,
      amount: subscription?.amount ?? 0,
    };
  }

  private throwBadRequest(error: unknown, fallbackMessage: string): never {
    const message = error instanceof Error ? error.message : fallbackMessage;
    throw new HttpException(message, HttpStatus.BAD_REQUEST);
  }
}
