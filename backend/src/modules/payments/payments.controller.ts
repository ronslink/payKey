import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Headers,
  UseGuards,
  Request,
  UnauthorizedException,
} from '@nestjs/common';
import { IntaSendService } from './intasend.service';
import { StripeService } from './stripe.service';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  SubscriptionPayment,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';
import {
  Subscription,
  SubscriptionStatus,
} from '../subscriptions/entities/subscription.entity';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from './entities/transaction.entity';
import { User } from '../users/entities/user.entity';
import {
  PayrollRecord,
  PayrollStatus,
} from '../payroll/entities/payroll-record.entity';
import {
  PayPeriod,
  PayPeriodStatus,
} from '../payroll/entities/pay-period.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { DeviceToken } from '../notifications/entities/device-token.entity';



@Controller('payments')
export class PaymentsController {
  constructor(
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(SubscriptionPayment)
    private subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    @InjectRepository(DeviceToken)
    private deviceTokenRepository: Repository<DeviceToken>,
    private intaSendService: IntaSendService,
    private stripeService: StripeService,
    private notificationsService: NotificationsService,
  ) { }



  /**
   * Stripe Webhook Endpoint
   * Receives events from Stripe (checkout.session.completed, invoice.payment_succeeded, etc.)
   */
  @Post('stripe/webhook')
  async handleStripeWebhook(
    @Headers('stripe-signature') signature: string,
    @Request() req: any,
  ) {
    console.log('🔵 Stripe Webhook Received');

    if (!signature) {
      throw new UnauthorizedException('Missing Stripe signature');
    }

    try {
      const event = this.stripeService.constructEvent(req.rawBody, signature);
      await this.stripeService.handleWebhook(event);
      return { received: true };
    } catch (error) {
      console.error('⛔ Stripe Webhook Error:', error.message);
      throw new UnauthorizedException(`Webhook Error: ${error.message}`);
    }
  }

  @Post('initiate-stk')
  @UseGuards(JwtAuthGuard)
  async initiateStkPush(
    @Request() req: AuthenticatedRequest,
    @Body() body: { phoneNumber: string; amount: number },
  ) {
    // Ensure user has a working wallet
    const walletId = await this._ensureWallet(req.user.userId);

    // Generate a reference
    const apiRef = `TopUp-${req.user.userId}-${Date.now()}`;

    // Initiate IntaSend STK Push
    const result = await this.intaSendService.initiateStkPush(
      body.phoneNumber,
      body.amount,
      apiRef,
      walletId, // Fund specific wallet
    );

    // Create Transaction Record for webhook to find
    const transaction = this.transactionsRepository.create({
      userId: req.user.userId,
      amount: body.amount,
      currency: 'KES',
      type: TransactionType.DEPOSIT,
      status: TransactionStatus.PENDING,
      providerRef: result.invoice?.invoice_id || result.tracking_id,
      provider: 'INTASEND',
      recipientPhone: body.phoneNumber,
      accountReference: apiRef,
      metadata: {
        initiatedAt: new Date().toISOString(),
        stkResponse: result,
      },
    });

    await this.transactionsRepository.save(transaction);

    return result;
  }

  @Post('send-b2c')
  @UseGuards(JwtAuthGuard)
  async sendB2CPayment(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: {
      transactionId: string;
      phoneNumber: string;
      amount: number;
      remarks: string;
    },
  ) {
    // Ensure user has a working wallet
    const walletId = await this._ensureWallet(req.user.userId);

    // IntaSend Logic
    // Note: This endpoint processes single payment legacy style.
    // Ideally should be updated to use bulk if needed, but keeping for backward compat.
    return this.intaSendService.sendMoney([
      {
        account: body.phoneNumber,
        amount: body.amount,
        narrative: body.remarks || 'Payment',
      }
    ], walletId); // Draw from specific wallet
  }

  /**
   * DEV ONLY: Manually top up wallet balance for testing.
   * This bypasses M-Pesa and directly credits the user's wallet.
   */
  @Post('dev/topup')
  @UseGuards(JwtAuthGuard)
  async devTopup(
    @Request() req: AuthenticatedRequest,
    @Body() body: { amount: number },
  ) {
    // Only allow in development mode
    if (process.env.NODE_ENV === 'production') {
      throw new Error('This endpoint is only available in development mode');
    }

    const result = await this.usersRepository.increment(
      { id: req.user.userId },
      'walletBalance',
      body.amount,
    );

    // Get updated balance
    const user = await this.usersRepository.findOne({
      where: { id: req.user.userId },
      select: ['id', 'walletBalance'],
    });

    return {
      success: true,
      message: `DEV: Topped up wallet by KES ${body.amount}`,
      newBalance: user?.walletBalance ?? 0,
    };
  }

  @Get('wallet-balance')
  @UseGuards(JwtAuthGuard)
  async getWalletBalance(@Request() req: AuthenticatedRequest) {
    const userId = req.user.userId;
    // ensure wallet logic might check DB, but here we want to fetch FROM IntaSend
    const walletId = await this._ensureWallet(userId);

    // Fetch REAL balance from IntaSend
    const intasendWallet = await this.intaSendService.getWalletBalance(walletId);

    // Fallback or Sync logic?
    // For now, let's return the IntaSend balance as primary source of truth if available
    // But we also maintain local state for "Clearing" visualization.

    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['walletBalance', 'clearingBalance'],
    });

    return {
      success: true,
      // Use IntaSend's available_balance as the truth for "Ready to Spend"
      available_balance: Number(intasendWallet.available_balance ?? user?.walletBalance ?? 0),
      // Use local clearing balance as "Pending Logic" (since IntaSend API might just say pending)
      clearing_balance: Number(intasendWallet.current_balance) - Number(intasendWallet.available_balance) > 0
        ? Number(intasendWallet.current_balance) - Number(intasendWallet.available_balance) // Calculate pending from IntaSend
        : user?.clearingBalance ?? 0,
      currency: 'KES',
      can_disburse: true,
    };
  }

  /**
   * HELPER: Ensure user has a dedicated IntaSend Wallet
   */
  private async _ensureWallet(userId: string): Promise<string> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['id', 'email', 'firstName', 'lastName', 'businessName', 'intasendWalletId'],
    });

    if (!user) {
      throw new Error('User not found');
    }

    if (user.intasendWalletId) {
      return user.intasendWalletId;
    }

    // Create Wallet
    const label = user.businessName || `${user.firstName} ${user.lastName}`.trim() || `User ${user.id}`;
    // Sanitize label (alphanumeric only ideally, but API might be flexible)

    try {
      const wallet = await this.intaSendService.createWallet(label);
      if (wallet && wallet.wallet_id) {
        // Save to DB
        await this.usersRepository.update(userId, { intasendWalletId: wallet.wallet_id });
        return wallet.wallet_id;
      }
      throw new Error('Wallet creation response missing ID');
    } catch (e) {
      console.error('Failed to auto-create wallet:', e);
      // Fallback: Return undefined (will use Master Wallet) OR throw error?
      // For migration safety, we might mistakenly use master wallet if we don't throw.
      // BUT for now, let's throw to ensure we don't mix funds.
      throw new Error('Failed to Initialize Client Wallet');
    }
  }

  @Get('intasend/status/:trackingId')
  async checkPayoutStatus(@Param('trackingId') trackingId: string) {
    const status = await this.intaSendService.checkPayoutStatus(trackingId);
    return status;
  }

  /**
   * Get list of supported Kenyan banks for PesaLink transfers
   */
  @Get('intasend/banks')
  async getBankCodes() {
    return this.intaSendService.getBankCodes();
  }

  @Post('intasend/webhook')
  async handleIntaSendWebhook(@Request() req: any, @Body() body: any) {
    console.log('🔹 IntaSend Webhook Received:', JSON.stringify(body, null, 2));

    // If it's a pure verification challenge (no invoice/tracking data), return immediately
    if (body.challenge && !body.invoice_id && !body.tracking_id) {
      return { challenge: body.challenge };
    }

    // Check if this is a simulation FIRST (before attempting signature verification)
    const isSimulation =
      process.env.INTASEND_SIMULATE === 'true' ||
      (body.host === 'localhost' && body.invoice_id?.startsWith('INV_SIM_'));

    if (isSimulation) {
      console.log('✅ Simulation mode detected - skipping signature verification');
    } else {
      // Only verify signature for non-simulation webhooks
      const signature = (req.headers['x-intasend-signature'] as string) || '';
      if (!this.intaSendService.verifyWebhookSignature(signature, req.rawBody)) {
        console.error('⛔ Invalid Webhook Signature');
        throw new UnauthorizedException('Invalid Signature');
      }
    }

    const { invoice_id, tracking_id, state, api_ref, value } = body;

    // 1. Find Transactions (Handing Bulk by tracking_id)
    // We search for ANY transaction matching:
    // - providerRef == invoice_id
    // - providerRef == tracking_id
    // - id == api_ref (Use Transaction ID as matching key)
    const searchCriteria: any[] = [
      ...(invoice_id ? [{ providerRef: invoice_id }] : []),
      ...(tracking_id ? [{ providerRef: tracking_id }] : []),
    ];

    // Only add api_ref if it looks like a UUID (to avoid matching random strings against ID)
    if (api_ref && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(api_ref)) {
      searchCriteria.push({ id: api_ref });
    }

    if (searchCriteria.length === 0) {
      console.warn('⚠️ No valid search criteria found for webhook');
      return { status: 'ignored', reason: 'No identifiers found' };
    }

    const transactions = await this.transactionsRepository.find({
      where: searchCriteria,
    });

    if (transactions.length === 0) {
      console.warn(
        `⚠️ Transaction not found for Invoice: ${invoice_id} / Tracking: ${tracking_id} / Ref: ${api_ref}`,
      );
      return { status: 'ignored', reason: 'Transaction not found' };
    }

    // 2. Idempotency Check (Check first one)
    const firstTx = transactions[0];
    if (
      firstTx.status === TransactionStatus.SUCCESS ||
      firstTx.status === TransactionStatus.FAILED ||
      (firstTx.status === TransactionStatus.CLEARING && body.clearing_status === 'CLEARING')
    ) {
      console.log(`🔹 Idempotency: Transaction(s) ${firstTx.providerRef} already final. Skipping.`);
      return { status: 'ignored', reason: 'Already finalized' };
    }

    // 3. Determine New Status
    let newStatus = TransactionStatus.PENDING;
    const { clearing_status } = body;

    if (state === 'COMPLETE' || state === 'COMPLETED') {
      if (clearing_status === 'CLEARING') {
        newStatus = TransactionStatus.CLEARING;
      } else {
        newStatus = TransactionStatus.SUCCESS;
      }
    } else if (state === 'FAILED') {
      newStatus = TransactionStatus.FAILED;
    }

    // 4. Update ALL matching transactions
    for (const tx of transactions) {
      const previousStatus = tx.status;
      tx.status = newStatus;
      tx.metadata = {
        ...(typeof tx.metadata === 'string' ? JSON.parse(tx.metadata) : tx.metadata),
        webhookEvent: body,
        updatedAt: new Date().toISOString(),
      };

      // Handle Deposit Logic (Only credit once per transaction)
      // Note: tracking_id based bulk payouts are usually TYPE=PAYOUT, not DEPOSIT.
      // DEPOSITS usually have unique invoice_id.
      // Handle Deposit Logic (Only credit once per transaction)
      if (tx.type === TransactionType.DEPOSIT) {
        if (newStatus === TransactionStatus.CLEARING) {
          // If we are moving TO clearing, add to clearing balance
          // But check if we were already in clearing? Idempotency handles that.
          // What if we were PENDING? Add to clearing.
          await this.usersRepository.increment(
            { id: tx.userId },
            'clearingBalance',
            Number(value || tx.amount),
          );
        } else if (newStatus === TransactionStatus.SUCCESS) {
          await this.usersRepository.increment(
            { id: tx.userId },
            'walletBalance',
            Number(value || tx.amount),
          );

          // If it was previously in clearing, remove from clearing balance
          if (previousStatus === TransactionStatus.CLEARING) {
            await this.usersRepository.decrement(
              { id: tx.userId },
              'clearingBalance',
              Number(value || tx.amount),
            );
          }
        }
      }
    }


    await this.transactionsRepository.save(transactions);

    // 6. Send Push Notifications for status updates
    if (newStatus !== TransactionStatus.PENDING) {
      const userId = firstTx.userId;
      const deviceToken = await this.deviceTokenRepository.findOne({
        where: { userId, isActive: true },
        order: { lastUsedAt: 'DESC' },
      });

      if (deviceToken) {
        const transactionType =
          firstTx.type === TransactionType.DEPOSIT ? 'TOPUP' : 'PAYOUT';
        const workerName = firstTx.metadata?.workerName || 'Worker';
        const amount = Number(firstTx.amount);

        await this.notificationsService.sendPaymentStatusNotification(
          deviceToken.token,
          workerName,
          amount,
          newStatus as 'PENDING' | 'CLEARING' | 'SUCCESS' | 'FAILED',
          transactionType,
        );
        console.log(`📱 Push notification sent for ${newStatus}`);
      }
    }

    // 7. Subscription Logic (Legacy/Single handling)
    if (firstTx.metadata?.subscriptionPaymentId) {
      const subPaymentId = firstTx.metadata.subscriptionPaymentId;
      const isSuccess = newStatus === TransactionStatus.SUCCESS;
      const status = isSuccess ? PaymentStatus.COMPLETED : PaymentStatus.FAILED;

      await this.subscriptionPaymentRepository.update(subPaymentId, {
        status,
        transactionId: invoice_id || tracking_id,
        paidDate: isSuccess ? new Date() : undefined,
      });

      if (isSuccess) {
        const payment = await this.subscriptionPaymentRepository.findOne({ where: { id: subPaymentId } });
        if (payment) {
          const subscription = await this.subscriptionRepository.findOne({ where: { id: payment.subscriptionId } });
          if (subscription) {
            subscription.status = SubscriptionStatus.ACTIVE;
            await this.subscriptionRepository.save(subscription);
            await this.usersRepository.update(payment.userId, { tier: subscription.tier as any });
            console.log(`🎉 Subscription Activated for User ${payment.userId}`);
          }
        }
      }
    }

    return {
      status: 'success',
      updated: transactions.length,
      challenge: body.challenge // Echo challenge if present (required by IntaSend)
    };
  }
}
