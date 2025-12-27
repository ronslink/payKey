import {
  Controller,
  Post,
  Body,
  Headers,
  UseGuards,
  Request,
} from '@nestjs/common';
import { MpesaService } from './mpesa.service';
import { IntaSendService } from './intasend.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SubscriptionPayment, PaymentStatus } from '../subscriptions/entities/subscription-payment.entity';
import { Subscription, SubscriptionStatus } from '../subscriptions/entities/subscription.entity';
import { Transaction, TransactionStatus, TransactionType } from './entities/transaction.entity';
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
  ) { }

  // ... (existing callbacks) ...

  @Post('initiate-stk')
  @UseGuards(JwtAuthGuard)
  async initiateStkPush(
    @Request() req: AuthenticatedRequest,
    @Body() body: { phoneNumber: string; amount: number },
  ) {
    // Generate a reference
    const apiRef = `TopUp-${req.user.userId}-${Date.now()}`;
    // IntaSend Logic
    return this.intaSendService.initiateStkPush(
      body.phoneNumber,
      body.amount,
      apiRef,
    );
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
    return this.intaSendService.sendMoney(
      body.phoneNumber,
      body.amount,
      body.remarks || 'Payment',
    );
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
  @Post('intasend/webhook')
  async handleIntaSendWebhook(@Body() body: any) {
    console.log('🔹 IntaSend Webhook Received:', JSON.stringify(body, null, 2));

    // Handle Challenge (if IntaSend sends one, though usually it's direct POST)
    if (body.challenge) {
      return { challenge: body.challenge };
    }

    const { invoice_id, state, api_ref, value, account } = body;

    // 1. Find Transaction by Provider Ref (Invoice ID) OR API Ref
    // Note: We stored invoice_id as providerRef in some places, or api_ref as accountReference
    let transaction = await this.transactionsRepository.findOne({
      where: [{ providerRef: invoice_id }, { accountReference: api_ref }],
    });

    if (!transaction) {
      console.warn(`⚠️ Transaction not found for Invoice: ${invoice_id} / Ref: ${api_ref}`);
      return { status: 'ignored', reason: 'Transaction not found' };
    }

    // 2. Update Status
    if (state === 'COMPLETE' || state === 'COMPLETED') {
      transaction.status = TransactionStatus.SUCCESS;

      // If it's a TopUp (Deposit), credit the wallet
      if (transaction.type === TransactionType.DEPOSIT && transaction.status !== TransactionStatus.SUCCESS) {
        // Prevent double credit if already successful?
        // We should check previous status.
        await this.usersRepository.increment(
          { id: transaction.userId },
          'walletBalance',
          Number(value)
        );
      }
    } else if (state === 'FAILED') {
      transaction.status = TransactionStatus.FAILED;
    } else if (state === 'PROCESSING') {
      transaction.status = TransactionStatus.PENDING;
    }

    // 3. Update Transaction Metadata
    transaction.metadata = {
      ...transaction.metadata,
      webhookEvent: body,
      updatedAt: new Date().toISOString(),
    };

    await this.transactionsRepository.save(transaction);

    // 4. Handle Subscription Logic if relevant
    // If this transaction is linked to a SubscriptionPayment
    if (transaction.metadata?.subscriptionPaymentId) {
      const subPaymentId = transaction.metadata.subscriptionPaymentId;
      const status = state === 'COMPLETE' ? PaymentStatus.COMPLETED : PaymentStatus.FAILED;

      await this.subscriptionPaymentRepository.update(subPaymentId, {
        status,
        transactionId: invoice_id,
        paidDate: state === 'COMPLETE' ? new Date() : undefined
      });

      // Use UsersService or SubscriptionService to activate subscription?
      // Logic already exists in checkMpesaPaymentStatus, but we should do it here ideally.
    }

    return { status: 'received' };
  }
}
