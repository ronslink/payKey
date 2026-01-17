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
import { MpesaService } from './mpesa.service';
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

interface MpesaCallbackData {
  Body: {
    stkCallback: {
      MerchantRequestID: string;
      CheckoutRequestID: string;
      ResultCode: number;
      ResultDesc: string;
      CallbackMetadata?: {
        Item: Array<{
          Name: string;
          Value: string | number;
        }>;
      };
    };
  };
}

interface MpesaB2CCallbackData {
  Result: {
    ResultType: number;
    ResultCode: number;
    ResultDesc: string;
    OriginatorConversationID: string;
    ConversationID: string;
    TransactionID: string;
    ResultParameters: {
      ResultParameter: Array<{
        Key: string;
        Value: string | number;
      }>;
    };
    ReferenceData: {
      ReferenceItem: Array<{
        Key: string;
        Value: string;
      }>;
    };
  };
}

@Controller('payments')
export class PaymentsController {
  constructor(
    private mpesaService: MpesaService,
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
    private intaSendService: IntaSendService,
    private stripeService: StripeService,
  ) { }

  @Post('callback')
  async handleMpesaCallback(@Body() body: MpesaCallbackData) {
    console.log('M-Pesa Callback Received:', JSON.stringify(body));

    const callback = body.Body.stkCallback;
    if (!callback) {
      return { ResultCode: 1, ResultDesc: 'Invalid Payload' };
    }

    const { MerchantRequestID, ResultCode, ResultDesc } = callback;

    const transaction = await this.transactionsRepository.findOne({
      where: { providerRef: MerchantRequestID },
    });

    if (!transaction) {
      console.warn(`Transaction not found for M-Pesa Callback: ${MerchantRequestID}`);
      return { ResultCode: 0, ResultDesc: 'Transaction Not Found' };
    }

    if (transaction.status !== TransactionStatus.PENDING) {
      return { ResultCode: 0, ResultDesc: 'Already Processed' };
    }

    if (ResultCode === 0) {
      transaction.status = TransactionStatus.SUCCESS;

      // Credit User Wallet
      // Note: check for double crediting handled by status check above
      await this.usersRepository.increment(
        { id: transaction.userId },
        'walletBalance',
        Number(transaction.amount) // Ensure number
      );
    } else {
      transaction.status = TransactionStatus.FAILED;
    }

    transaction.metadata = {
      ...(typeof transaction.metadata === 'string'
        ? JSON.parse(transaction.metadata)
        : transaction.metadata),
      resultDesc: ResultDesc,
      callback: body,
    };

    await this.transactionsRepository.save(transaction);

    return { ResultCode: 0, ResultDesc: 'Success' };
  }

  @Post('b2c-callback')
  async handleB2CCallback(@Body() body: MpesaB2CCallbackData) {
    console.log('M-Pesa B2C Callback Received:', JSON.stringify(body));
    // Delegate to service if needed, or handle here
    // Currently PayKey uses IntaSend for B2C, so this might be legacy or direct M-Pesa.
    return { ResultCode: 0, ResultDesc: 'Accepted' };
  }

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
    // Generate a reference
    const apiRef = `TopUp-${req.user.userId}-${Date.now()}`;

    // Initiate IntaSend STK Push
    const result = await this.intaSendService.initiateStkPush(
      body.phoneNumber,
      body.amount,
      apiRef,
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
    // IntaSend Logic
    // Note: This endpoint processes single payment legacy style.
    // Ideally should be updated to use bulk if needed, but keeping for backward compat.
    return this.intaSendService.sendMoney([
      {
        account: body.phoneNumber,
        amount: body.amount,
        narrative: body.remarks || 'Payment',
      }
    ]);
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

    if (body.challenge) {
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
    // We search for ANY transaction matching invoice_id OR tracking_id
    const transactions = await this.transactionsRepository.find({
      where: [
        ...(invoice_id ? [{ providerRef: invoice_id }] : []),
        ...(tracking_id ? [{ providerRef: tracking_id }] : []),
      ],
    });

    if (transactions.length === 0) {
      console.warn(
        `⚠️ Transaction not found for Invoice: ${invoice_id} / Tracking: ${tracking_id}`,
      );
      return { status: 'ignored', reason: 'Transaction not found' };
    }

    // 2. Idempotency Check (Check first one)
    const firstTx = transactions[0];
    if (
      firstTx.status === TransactionStatus.SUCCESS ||
      firstTx.status === TransactionStatus.FAILED
    ) {
      console.log(`🔹 Idempotency: Transaction(s) ${firstTx.providerRef} already final. Skipping.`);
      return { status: 'ignored', reason: 'Already finalized' };
    }

    // 3. Determine New Status
    let newStatus = TransactionStatus.PENDING;
    if (state === 'COMPLETE' || state === 'COMPLETED') {
      newStatus = TransactionStatus.SUCCESS;
    } else if (state === 'FAILED') {
      newStatus = TransactionStatus.FAILED;
    }

    // 4. Update ALL matching transactions
    for (const tx of transactions) {
      tx.status = newStatus;
      tx.metadata = {
        ...(typeof tx.metadata === 'string' ? JSON.parse(tx.metadata) : tx.metadata),
        webhookEvent: body,
        updatedAt: new Date().toISOString(),
      };

      // Handle Deposit Logic (Only credit once per transaction)
      // Note: tracking_id based bulk payouts are usually TYPE=PAYOUT, not DEPOSIT.
      // DEPOSITS usually have unique invoice_id.
      if (
        tx.type === TransactionType.DEPOSIT &&
        newStatus === TransactionStatus.SUCCESS
      ) {
        await this.usersRepository.increment(
          { id: tx.userId },
          'walletBalance',
          Number(value || tx.amount),
        );
      }
    }

    await this.transactionsRepository.save(transactions);

    // 5. Subscription Logic (Legacy/Single handling)
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

    return { status: 'success', updated: transactions.length };
  }
}
