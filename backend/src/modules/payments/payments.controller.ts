import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Headers,
  UseGuards,
  Request,
  Req,
  UnauthorizedException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';

// Interface for Request with rawBody (added by middleware)
interface RawBodyRequest<T> extends ExpressRequest {
  rawBody: Buffer;
}
import { IntaSendService } from './intasend.service';
import { StripeService } from './stripe.service';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, DataSource, Not, IsNull } from 'typeorm';
import {
  SubscriptionPayment,
  PaymentMethod,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../subscriptions/entities/subscription.entity';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
  PaymentMethodType,
} from './entities/transaction.entity';
import { User, UserTier } from '../users/entities/user.entity';
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
import { paymentMetadata } from '../subscriptions/dto/subscription-payment-metadata';
import { PromotionalItem } from '../subscriptions/entities/promotional-item.entity';
import { redactProviderSecrets } from '../../common/security/provider-secrets';

@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Transaction)
    private readonly transactionsRepository: Repository<Transaction>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    private readonly payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(SubscriptionPayment)
    private readonly subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(DeviceToken)
    private readonly deviceTokenRepository: Repository<DeviceToken>,
    private readonly intaSendService: IntaSendService,
    private readonly stripeService: StripeService,
    private readonly notificationsService: NotificationsService,
  ) {}

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

  /**
   * Stripe Webhook Alias (Matches Stripe Dashboard Config)
   * The user has configured https://api.paydome.co/payments/subscriptions/webhook
   */
  @Post('subscriptions/webhook')
  async handleStripeWebhookAlias(
    @Headers('stripe-signature') signature: string,
    @Request() req: any,
  ) {
    console.log('🔵 Stripe Webhook Alias Received');
    return this.handleStripeWebhook(signature, req);
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
    if (
      process.env.NODE_ENV === 'production' ||
      process.env.INTASEND_IS_LIVE === 'true'
    ) {
      throw new BadRequestException(
        'Direct B2C payouts are disabled in production. Use payroll finalization.',
      );
    }

    if (!body.phoneNumber || !body.amount || Number(body.amount) <= 0) {
      throw new BadRequestException(
        'phoneNumber and positive amount are required',
      );
    }

    // Ensure user has a working wallet
    const walletId = await this._ensureWallet(req.user.userId);

    // IntaSend Logic
    // Note: This endpoint processes single payment legacy style.
    // Ideally should be updated to use bulk if needed, but keeping for backward compat.
    return this.intaSendService.sendMoney(
      [
        {
          account: body.phoneNumber,
          amount: body.amount,
          narrative: body.remarks || 'Payment',
        },
      ],
      walletId,
    ); // Draw from specific wallet
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
    if (
      process.env.NODE_ENV === 'production' ||
      process.env.INTASEND_IS_LIVE === 'true'
    ) {
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
    const intasendWallet =
      await this.intaSendService.getWalletBalance(walletId);

    // Fallback or Sync logic?
    // For now, let's return the IntaSend balance as primary source of truth if available
    // But we also maintain local state for "Clearing" visualization.

    // Fetch PENDING or CLEARING deposits from local DB to visualize "Clearing Funds"
    // This ensures that even if IntaSend API doesn't report them yet (or excludes held funds from current_balance),
    // the user sees them as pending/clearing in the App.
    const pendingDeposits = await this.transactionsRepository.find({
      where: {
        userId: userId,
        type: TransactionType.DEPOSIT,
        status: In([TransactionStatus.PENDING, TransactionStatus.CLEARING]),
      },
    });

    const pendingAmount = pendingDeposits.reduce(
      (sum, tx) => sum + Number(tx.amount || 0),
      0,
    );

    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['walletBalance', 'clearingBalance'],
    });

    // Calculate IntaSend reported clearing
    let intaSendClearing =
      Number(intasendWallet.current_balance) -
      Number(intasendWallet.available_balance);
    if (intaSendClearing < 0) intaSendClearing = 0;

    // Total Clearing = IntaSend Reported + Local Pending
    // We sum them to ensure visibility. (Note: slight risk of double counting if IntaSend includes it,
    // but better to show more than 0 for "missing" funds).
    const totalClearing = intaSendClearing + pendingAmount;

    return {
      success: true,
      // Fix 3: Standardize on the local ledger as the absolute source of truth
      available_balance: Number(user?.walletBalance ?? 0),
      // Use combined clearing balance
      clearing_balance: totalClearing,
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
      select: [
        'id',
        'email',
        'firstName',
        'lastName',
        'businessName',
        'intasendWalletId',
      ],
    });

    if (!user) {
      throw new Error('User not found');
    }

    if (user.intasendWalletId) {
      return user.intasendWalletId;
    }

    // Create Wallet
    const label =
      user.businessName ||
      `${user.firstName} ${user.lastName}`.trim() ||
      `User ${user.id}`;
    // Sanitize label (alphanumeric only ideally, but API might be flexible)

    try {
      const wallet = await this.intaSendService.createWallet('KES', label);
      if (wallet && wallet.wallet_id) {
        // Save to DB
        await this.usersRepository.update(userId, {
          intasendWalletId: wallet.wallet_id,
        });
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
  @UseGuards(JwtAuthGuard)
  async checkPayoutStatus(
    @Request() req: AuthenticatedRequest,
    @Param('trackingId') trackingId: string,
  ) {
    const transaction = await this.transactionsRepository.findOne({
      where: { userId: req.user.userId, providerRef: trackingId },
    });

    if (!transaction) {
      throw new UnauthorizedException('Payment reference not found');
    }

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
  async handleIntaSendWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-intasend-signature') signature: string,
    @Body() body: any,
  ) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw new BadRequestException('Invalid webhook payload');
    }
    const livePayments =
      process.env.NODE_ENV === 'production' ||
      process.env.INTASEND_IS_LIVE === 'true';
    // 0. Robust Signature Retrieval (Headers can be lowercase or different casing via proxies)
    const effectiveSignature =
      signature ||
      (req.headers['x-intasend-signature'] as string) ||
      (req.headers['X-IntaSend-Signature'] as string);

    // Debug Logging for Webhooks (Direct console.log to avoid NestJS logger suppression/truncation)
    console.log(
      `[DEBUG] Webhook Hit. Sig Present: ${!!effectiveSignature}. Body Size: ${req.rawBody?.length || 0}`,
    );

    if (!effectiveSignature) {
      console.warn('[DEBUG] Webhook signature header is absent.');
    }

    // Signature checks may only be bypassed in explicit non-production testing.
    const bypassRequested = process.env.INTASEND_DISABLE_SIG_CHECK === 'true';
    const isBypassed = bypassRequested && !livePayments;

    if (bypassRequested && livePayments) {
      this.logger.error('INTASEND_DISABLE_SIG_CHECK was ignored in live mode.');
    }

    if (isBypassed) {
      console.warn(
        '⚠️ SKIPPING SIGNATURE CHECK due to INTASEND_DISABLE_SIG_CHECK=true',
      );
      // Skip verification logic entirely
    } else {
      // Enforce Verification
      const challenge = body.challenge;

      // If it's a pure verification challenge (no invoice/tracking data), verify and return
      if (challenge && !body.invoice_id && !body.tracking_id) {
        if (
          !this.intaSendService.verifyWebhookSignature(
            effectiveSignature,
            req.rawBody,
            challenge,
          )
        ) {
          console.error('⛔ Challenge Verification Failed.');
          throw new BadRequestException('Invalid signature or challenge');
        }
        return { challenge: challenge };
      }

      // Check if this is a simulation FIRST
      const callbackInvoiceId: unknown = (body as Record<string, unknown>)
        .invoice_id;
      const callbackHost: unknown = (body as Record<string, unknown>).host;
      const simulationRequested =
        process.env.INTASEND_SIMULATE === 'true' ||
        (callbackHost === 'localhost' &&
          typeof callbackInvoiceId === 'string' &&
          callbackInvoiceId.startsWith('INV_SIM_'));
      const isSimulation = simulationRequested && !livePayments;

      if (simulationRequested && livePayments) {
        this.logger.error(
          'IntaSend simulation bypass was ignored in live mode.',
        );
      }

      if (isSimulation) {
        this.logger.log(
          '✅ Simulation mode detected - skipping signature verification',
        );
      } else {
        if (
          !this.intaSendService.verifyWebhookSignature(
            effectiveSignature,
            req.rawBody,
            challenge,
          )
        ) {
          console.error('⛔ Signature Verification Failed.');
          throw new BadRequestException('Invalid signature or challenge');
        }
      }
    }

    this.logger.log('🔹 IntaSend webhook payload verified.');

    let { invoice_id, tracking_id, state, api_ref, to_data } = body as {
      invoice_id?: string;
      tracking_id?: string;
      state?: string;
      api_ref?: string;
      to_data?: {
        transaction?: {
          transaction_id?: string;
          narrative?: string;
          status?: string;
        };
      };
    };

    // B2C batch webhooks use `status` at the top level (not `state`).
    // STK deposit webhooks use `state`. Normalise so both paths use `state`.
    if (!state && body.status) {
      state = body.status;
    }

    // HANDLE INTRA-WALLET TRANSFER EVENTS
    // These events don't have top-level invoice_id/tracking_id but have nested data
    if (to_data && to_data.transaction) {
      const tx = to_data.transaction;
      // Map fields from nested transaction object
      if (!tracking_id) tracking_id = tx.transaction_id;

      // Narrative often contains reference or account number
      if (!api_ref && tx.narrative) api_ref = tx.narrative;

      // Map Status: AVAILABLE -> SUCCESS
      if (tx.status === 'AVAILABLE') {
        state = 'COMPLETE';
      }

      this.logger.log(
        `🔹 Detected Intra-Wallet Transfer. ID: ${tracking_id}, Ref: ${api_ref}, Status: ${tx.status}`,
      );
    }

    // Subscription collections must resolve one stored invoice before the generic
    // batch handler, including old requests that shared an api_ref across users.
    const subscriptionCandidates =
      invoice_id || api_ref
        ? await this.transactionsRepository.find({
            where: [
              ...(invoice_id
                ? [
                    {
                      type: TransactionType.SUBSCRIPTION,
                      provider: 'INTASEND',
                      providerRef: invoice_id,
                    },
                  ]
                : []),
              ...(api_ref
                ? [
                    {
                      type: TransactionType.SUBSCRIPTION,
                      provider: 'INTASEND',
                      accountReference: api_ref,
                    },
                  ]
                : []),
            ],
          })
        : [];
    if (subscriptionCandidates.length) {
      return this.settleIntaSendSubscription(
        subscriptionCandidates,
        invoice_id,
        api_ref,
      );
    }

    // 1. Transaction Wrapper for Idempotency
    return await this.dataSource.transaction(async (manager) => {
      // Prefer our own IntaSend api_ref/accountReference. Provider refs are
      // useful fallback identifiers, but api_ref is the app-owned checkout key.
      const appReferenceCriteria: any[] = [
        ...(api_ref ? [{ accountReference: api_ref }] : []),
      ];

      // Only add api_ref if it looks like a UUID (to avoid matching random strings against ID)
      if (
        api_ref &&
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
          api_ref,
        )
      ) {
        appReferenceCriteria.push({ id: api_ref });
      }

      const providerReferenceCriteria: any[] = [
        ...(invoice_id ? [{ providerRef: invoice_id }] : []),
        ...(tracking_id ? [{ providerRef: tracking_id }] : []),
      ];

      const searchCriteria =
        appReferenceCriteria.length > 0
          ? appReferenceCriteria
          : providerReferenceCriteria;

      if (searchCriteria.length === 0) {
        console.warn('⚠️ No valid search criteria found for webhook');
        return { status: 'ignored', reason: 'No identifiers found' };
      }

      let transactions = await manager.find(Transaction, {
        where: searchCriteria,
        lock: { mode: 'pessimistic_write' }, // Lock the rows to prevent double webhook execution
      });

      if (
        transactions.length === 0 &&
        appReferenceCriteria.length > 0 &&
        providerReferenceCriteria.length > 0
      ) {
        transactions = await manager.find(Transaction, {
          where: providerReferenceCriteria,
          lock: { mode: 'pessimistic_write' },
        });
      }

      if (transactions.length === 0) {
        console.warn(
          `⚠️ Transaction not found for Invoice: ${invoice_id} / Tracking: ${tracking_id} / Ref: ${api_ref}`,
        );
        return { status: 'ignored', reason: 'Transaction not found' };
      }

      if (
        transactions.some(
          (transaction) => transaction.type === TransactionType.SUBSCRIPTION,
        )
      ) {
        throw new BadRequestException(
          'A subscription invoice is required for verification',
        );
      }

      // 2. Idempotency Check
      const firstTx = transactions[0];
      const hasOpenTransactions = transactions.some(
        (tx) =>
          !this.isFinalTransactionStatus(tx.status) &&
          !(
            tx.status === TransactionStatus.CLEARING &&
            body.clearing_status === 'CLEARING'
          ),
      );

      if (!hasOpenTransactions) {
        console.log(
          `🔹 Idempotency: Transaction(s) ${firstTx.providerRef} already final. Skipping.`,
        );
        return { status: 'ignored', reason: 'Already finalized' };
      }

      // 3. Determine New Status
      const batchStatus = this.resolveIntaSendWebhookStatus(body, state);
      let notificationStatus = TransactionStatus.PENDING;
      let updatedCount = 0;

      // 4. Update ALL matching transactions
      for (const tx of transactions) {
        const previousStatus = tx.status;
        if (
          this.isFinalTransactionStatus(previousStatus) ||
          (previousStatus === TransactionStatus.CLEARING &&
            body.clearing_status === 'CLEARING')
        ) {
          continue;
        }

        const itemizedStatus = this.resolveIntaSendItemStatusForTransaction(
          tx,
          body.transactions,
        );
        const newStatus = itemizedStatus || batchStatus;

        // CLEARING can arrive in state, status or clearing_status. Retries of
        // the same transition must never credit the clearing balance again.
        if (newStatus === previousStatus) continue;

        if (
          previousStatus === TransactionStatus.CLEARING &&
          newStatus === TransactionStatus.PENDING
        ) {
          continue;
        }

        tx.status = newStatus;
        notificationStatus = this.preferNotificationStatus(
          notificationStatus,
          newStatus,
        );

        // Detect payment method from IntaSend provider field
        const provider = (body.provider || body.transactions?.[0]?.provider) as
          | string
          | undefined;
        const detectedPaymentMethod =
          this.paymentMethodFromIntaSendProvider(provider);
        if (detectedPaymentMethod) {
          tx.paymentMethod = detectedPaymentMethod;
        }

        let previousMetadata: unknown = tx.metadata;
        if (typeof previousMetadata === 'string') {
          try {
            previousMetadata = JSON.parse(previousMetadata) as unknown;
          } catch {
            previousMetadata = {};
          }
        }
        tx.metadata = redactProviderSecrets({
          ...(previousMetadata &&
          typeof previousMetadata === 'object' &&
          !Array.isArray(previousMetadata)
            ? previousMetadata
            : {}),
          webhookEvent: body,
          updatedAt: new Date().toISOString(),
        });

        // Handle Deposit Logic (Only credit once per transaction)
        if (tx.type === TransactionType.DEPOSIT) {
          if (newStatus === TransactionStatus.CLEARING) {
            await manager.increment(
              User,
              { id: tx.userId },
              'clearingBalance',
              Number(tx.amount),
            );
          } else if (newStatus === TransactionStatus.SUCCESS) {
            await manager.increment(
              User,
              { id: tx.userId },
              'walletBalance',
              Number(tx.amount),
            );

            if (previousStatus === TransactionStatus.CLEARING) {
              await manager.decrement(
                User,
                { id: tx.userId },
                'clearingBalance',
                Number(tx.amount),
              );
            }
          } else if (
            newStatus === TransactionStatus.FAILED &&
            previousStatus === TransactionStatus.CLEARING
          ) {
            await manager.decrement(
              User,
              { id: tx.userId },
              'clearingBalance',
              Number(tx.amount),
            );
          }
        }

        // Handle B2C Payout Logic - Update PayrollRecord status
        if (
          tx.type === TransactionType.SALARY_PAYOUT &&
          tx.metadata?.payrollRecordId
        ) {
          const payrollRecordId = tx.metadata.payrollRecordId;
          const paymentStatus = this.toPayrollPaymentStatus(newStatus);

          await manager.update(PayrollRecord, payrollRecordId, {
            paymentStatus,
            paymentDate:
              newStatus === TransactionStatus.SUCCESS ? new Date() : undefined,
          });

          console.log(
            `📊 PayrollRecord ${payrollRecordId} updated to ${paymentStatus}`,
          );
        }

        updatedCount++;
      }

      if (updatedCount === 0) {
        return { status: 'ignored', reason: 'No status transition' };
      }
      await manager.save(Transaction, transactions);

      // 6. Send Push Notifications for status updates
      if (
        notificationStatus !== TransactionStatus.PENDING &&
        notificationStatus !== TransactionStatus.MANUAL_INTERVENTION
      ) {
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
            notificationStatus as 'CLEARING' | 'SUCCESS' | 'FAILED',
            transactionType,
          );
          console.log(`📱 Push notification sent for ${notificationStatus}`);
        }
      }

      return {
        status: 'success',
        updated: updatedCount,
        challenge: body.challenge, // Echo challenge if present (required by IntaSend)
      };
    });
  }

  private async settleIntaSendSubscription(
    candidates: Transaction[],
    invoiceId?: string,
    reference?: string,
  ) {
    if (!invoiceId)
      throw new BadRequestException(
        'A subscription invoice is required for verification',
      );
    const exact = candidates.filter(
      (transaction) => transaction.providerRef === invoiceId,
    );
    const matches = exact.length ? exact : candidates;
    if (matches.length !== 1)
      throw new BadRequestException('Ambiguous subscription payment reference');
    const candidate = matches[0];
    if (reference && reference !== candidate.accountReference)
      throw new BadRequestException('Subscription payment reference mismatch');
    return this.dataSource.transaction(async (manager) => {
      await manager.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
        `stripe-billing:${candidate.userId}`,
      ]);
      const transaction = await manager.findOne(Transaction, {
        where: { id: candidate.id },
        lock: { mode: 'pessimistic_write' },
      });
      const transactionMetadata = transaction?.metadata as
        | { subscriptionPaymentId?: string; planId?: string }
        | undefined;
      if (!transaction || !transactionMetadata?.subscriptionPaymentId)
        throw new BadRequestException('Subscription receipt not found');
      const payment = await manager.findOne(SubscriptionPayment, {
        where: { id: transactionMetadata.subscriptionPaymentId },
        lock: { mode: 'pessimistic_write' },
      });
      const subscription =
        payment &&
        (await manager.findOneBy(Subscription, { id: payment.subscriptionId }));
      if (
        !payment ||
        !subscription ||
        payment.userId !== transaction.userId ||
        subscription.userId !== transaction.userId ||
        payment.currency !== transaction.currency ||
        Number(payment.amount) !== Number(transaction.amount)
      ) {
        throw new BadRequestException(
          'Subscription payment ownership mismatch',
        );
      }
      if (this.isFinalTransactionStatus(transaction.status))
        return { status: 'ignored', reason: 'Already finalized' };
      const isMpesa = payment.paymentMethod === 'mpesa';
      if (
        isMpesa &&
        ((transaction.providerRef && transaction.providerRef !== invoiceId) ||
          (payment.transactionId && payment.transactionId !== invoiceId))
      )
        throw new BadRequestException('Subscription invoice mismatch');
      if (
        isMpesa &&
        !transaction.providerRef &&
        transaction.accountReference !== `SUB-${payment.id}`
      )
        throw new BadRequestException(
          'Subscription invoice binding is missing',
        );
      // Bank checkout IDs and M-Pesa invoice IDs are different provider references.
      // Retrieve using the reference saved by our initiation, never a caller's invoice alone.
      const result = await this.intaSendService.getPaymentStatus(
        transaction.providerRef || invoiceId,
        isMpesa ? 'invoice' : 'checkout',
      );
      const invoice = result?.invoice;
      const value = Number(invoice?.value);
      const amountMinor = Math.round(Number(payment.amount) * 100);
      if (
        !invoice ||
        invoice.invoice_id !== invoiceId ||
        invoice.api_ref !== transaction.accountReference ||
        invoice.currency !== payment.currency ||
        !Number.isFinite(value) ||
        value <= 0 ||
        !Number.isSafeInteger(amountMinor) ||
        Math.abs(value * 100 - amountMinor) > 0.000001
      ) {
        throw new BadRequestException(
          'Subscription invoice amount, currency or reference mismatch',
        );
      }
      const state = String(invoice.state).toUpperCase();
      if (state !== 'COMPLETE' && state !== 'FAILED')
        return { status: 'pending' };
      if (isMpesa && !transaction.providerRef) {
        transaction.providerRef = invoiceId;
        payment.transactionId = invoiceId;
      }
      const completed = state === 'COMPLETE';
      transaction.status = completed
        ? TransactionStatus.SUCCESS
        : TransactionStatus.FAILED;
      payment.status = completed
        ? PaymentStatus.COMPLETED
        : PaymentStatus.FAILED;
      const metadata = {
        ...paymentMetadata(payment.metadata),
        verifiedInvoiceId: invoiceId,
        entitlementApplied: false,
      };
      if (completed) {
        payment.paidDate = new Date();
        const stripeContracts = await manager.find(Subscription, {
          where: {
            userId: payment.userId,
            stripeSubscriptionId: Not(IsNull()),
          },
        });
        if (
          stripeContracts.some(
            (contract) => contract.status !== SubscriptionStatus.CANCELLED,
          )
        ) {
          payment.notes =
            'Payment received after Stripe billing was linked; reconciliation required. Stripe entitlement unchanged.';
        } else {
          const targetTier = String(
            metadata.targetTier ||
              metadata.planId ||
              transactionMetadata.planId ||
              subscription.tier,
          ).toUpperCase() as SubscriptionTier;
          if (
            !Object.values(SubscriptionTier).includes(targetTier) ||
            targetTier === SubscriptionTier.FREE ||
            !['monthly', 'yearly'].includes(payment.billingPeriod) ||
            !(payment.periodEnd > payment.periodStart)
          ) {
            throw new BadRequestException(
              'Invalid subscription payment period or plan',
            );
          }
          // A late callback must never shorten an entitlement already paid through.
          if (
            !subscription.endDate ||
            payment.periodEnd > subscription.endDate ||
            subscription.status !== SubscriptionStatus.ACTIVE
          ) {
            subscription.tier = targetTier;
            subscription.status = SubscriptionStatus.ACTIVE;
            subscription.billingPeriod = payment.billingPeriod;
            subscription.amount = Number(payment.amount);
            subscription.currency = payment.currency;
            subscription.lockedPrice = Number(payment.amount);
            subscription.startDate = payment.periodStart;
            subscription.endDate = payment.periodEnd;
            subscription.nextBillingDate = payment.periodEnd;
            subscription.gracePeriodEndDate = null;
            subscription.pendingTier = null;
            subscription.appliedPromoId = metadata.promoId || null;
            subscription.promoDiscountAmount = payment.promoDiscountAmount;
            if (isMpesa) subscription.autoRenewal = false;
            await manager.save(Subscription, subscription);
            await manager.update(User, payment.userId, {
              tier: targetTier as unknown as UserTier,
            });
            metadata.entitlementApplied = true;
          } else {
            payment.notes =
              'Verified payment has an older service period; current paid-through date preserved. Reconciliation required.';
          }
          if (metadata.promoId)
            await manager.increment(
              PromotionalItem,
              { id: metadata.promoId },
              'currentUses',
              1,
            );
        }
      }
      payment.metadata = metadata;
      await manager.save(Transaction, transaction);
      await manager.save(SubscriptionPayment, payment);
      return { status: 'success', updated: 1 };
    });
  }

  private isFinalTransactionStatus(status: TransactionStatus): boolean {
    return (
      status === TransactionStatus.SUCCESS ||
      status === TransactionStatus.FAILED ||
      status === TransactionStatus.MANUAL_INTERVENTION
    );
  }

  private resolveIntaSendWebhookStatus(
    body: any,
    state: unknown,
  ): TransactionStatus {
    const stateStatus = this.mapIntaSendStatusToTransactionStatus(
      state || body.status || body.state || body.status_code,
    );

    if (
      stateStatus === TransactionStatus.SUCCESS &&
      String(body.clearing_status || '').toUpperCase() === 'CLEARING'
    ) {
      return TransactionStatus.CLEARING;
    }

    const itemStatuses: TransactionStatus[] = Array.isArray(body.transactions)
      ? (body.transactions as any[]).map(
          (item: any): TransactionStatus =>
            this.mapIntaSendStatusToTransactionStatus(
              item.status || item.state || item.status_code,
            ),
        )
      : [];

    if (itemStatuses.length === 0) {
      return stateStatus;
    }

    const allSucceeded = itemStatuses.every(
      (status: TransactionStatus) => status === TransactionStatus.SUCCESS,
    );
    const allFailed = itemStatuses.every(
      (status: TransactionStatus) => status === TransactionStatus.FAILED,
    );
    const hasSuccess = itemStatuses.includes(TransactionStatus.SUCCESS);
    const hasFailure = itemStatuses.includes(TransactionStatus.FAILED);
    const hasPending = itemStatuses.includes(TransactionStatus.PENDING);

    if (allSucceeded) return TransactionStatus.SUCCESS;
    if (allFailed) return TransactionStatus.FAILED;
    if (hasSuccess && hasFailure) return TransactionStatus.MANUAL_INTERVENTION;
    if (
      hasFailure ||
      (hasPending && stateStatus === TransactionStatus.SUCCESS)
    ) {
      return TransactionStatus.MANUAL_INTERVENTION;
    }

    return stateStatus;
  }

  private resolveIntaSendItemStatusForTransaction(
    tx: Transaction,
    items: any,
  ): TransactionStatus | null {
    if (!Array.isArray(items) || items.length === 0) {
      return null;
    }

    const txAccount = this.normalizeAccount(
      tx.recipientPhone || tx.accountReference || tx.metadata?.recipientAccount,
    );
    const txAmount = Number(tx.amount);

    const matches = items.filter((item) => {
      const itemAmount = Number(item.amount);
      if (
        !Number.isFinite(itemAmount) ||
        Math.abs(itemAmount - txAmount) > 0.01
      ) {
        return false;
      }

      const itemAccount = this.normalizeAccount(
        item.account || item.account_reference,
      );

      if (!txAccount || !itemAccount) {
        return false;
      }

      return this.accountsMatch(txAccount, itemAccount);
    });

    if (matches.length !== 1) {
      return null;
    }

    return this.mapIntaSendStatusToTransactionStatus(
      matches[0].status || matches[0].state || matches[0].status_code,
    );
  }

  private mapIntaSendStatusToTransactionStatus(
    status: unknown,
  ): TransactionStatus {
    const normalized = String(status || '')
      .trim()
      .toUpperCase()
      .replace(/[\s_-]/g, '');

    if (
      [
        'AVAILABLE',
        'BC100',
        'COMPLETE',
        'COMPLETED',
        'SENT',
        'SUCCESS',
        'SUCCESSFUL',
        'TS100',
      ].includes(normalized)
    ) {
      return TransactionStatus.SUCCESS;
    }

    if (
      [
        'BE111',
        'BF102',
        'CANCELED',
        'CANCELLED',
        'DECLINED',
        'FAILED',
        'TF103',
        'TF106',
        'TC108',
      ].includes(normalized)
    ) {
      return TransactionStatus.FAILED;
    }

    if (normalized === 'CLEARING') {
      return TransactionStatus.CLEARING;
    }

    if (normalized === 'TF105' || normalized === 'TH107') {
      return TransactionStatus.MANUAL_INTERVENTION;
    }

    return TransactionStatus.PENDING;
  }

  private toPayrollPaymentStatus(status: TransactionStatus): string {
    if (status === TransactionStatus.SUCCESS) return 'paid';
    if (status === TransactionStatus.FAILED) return 'failed';
    if (status === TransactionStatus.MANUAL_INTERVENTION) return 'manual_check';
    return 'processing';
  }

  private paymentMethodFromIntaSendProvider(
    provider?: string,
  ): PaymentMethodType | null {
    switch ((provider || '').toUpperCase()) {
      case 'M-PESA':
      case 'MPESA':
      case 'MPESA-B2C':
        return PaymentMethodType.MPESA_STK;
      case 'CARD-PAYMENT':
        return PaymentMethodType.CARD;
      case 'BANK-PAYMENT':
      case 'PESALINK':
        return PaymentMethodType.PESALINK;
      default:
        return provider ? PaymentMethodType.UNKNOWN : null;
    }
  }

  private toSubscriptionPaymentMethod(
    paymentMethod: PaymentMethodType,
  ): PaymentMethod | PaymentMethodType | string {
    switch (paymentMethod) {
      case PaymentMethodType.CARD:
        return PaymentMethod.CREDIT_CARD;
      case PaymentMethodType.MPESA_STK:
        return PaymentMethod.MPESA;
      case PaymentMethodType.PESALINK:
        return PaymentMethod.BANK_TRANSFER;
      case PaymentMethodType.WALLET:
        return PaymentMethod.WALLET;
      default:
        return paymentMethod || 'Unknown';
    }
  }

  private preferNotificationStatus(
    current: TransactionStatus,
    next: TransactionStatus,
  ): TransactionStatus {
    const priority: Record<TransactionStatus, number> = {
      [TransactionStatus.PENDING]: 0,
      [TransactionStatus.CLEARING]: 1,
      [TransactionStatus.SUCCESS]: 2,
      [TransactionStatus.FAILED]: 3,
      [TransactionStatus.MANUAL_INTERVENTION]: 4,
    };

    return priority[next] > priority[current] ? next : current;
  }

  private normalizeAccount(account: unknown): string {
    return String(account || '').replace(/[^\d]/g, '');
  }

  private accountsMatch(left: string, right: string): boolean {
    if (left === right) return true;
    const shortestLength = Math.min(left.length, right.length);
    return (
      shortestLength >= 7 && (left.endsWith(right) || right.endsWith(left))
    );
  }
}

@Controller('webhooks')
export class IntaSendWebhooksController {
  private readonly paymentsController: PaymentsController;

  constructor(
    dataSource: DataSource,
    @InjectRepository(Transaction)
    transactionsRepository: Repository<Transaction>,
    @InjectRepository(User)
    usersRepository: Repository<User>,
    @InjectRepository(PayrollRecord)
    payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(PayPeriod)
    payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(SubscriptionPayment)
    subscriptionPaymentRepository: Repository<SubscriptionPayment>,
    @InjectRepository(Subscription)
    subscriptionRepository: Repository<Subscription>,
    @InjectRepository(DeviceToken)
    deviceTokenRepository: Repository<DeviceToken>,
    intaSendService: IntaSendService,
    stripeService: StripeService,
    notificationsService: NotificationsService,
  ) {
    this.paymentsController = new PaymentsController(
      dataSource,
      transactionsRepository,
      usersRepository,
      payrollRecordRepository,
      payPeriodRepository,
      subscriptionPaymentRepository,
      subscriptionRepository,
      deviceTokenRepository,
      intaSendService,
      stripeService,
      notificationsService,
    );
  }

  /**
   * IntaSend Webhook Alias (Matches IntaSend Dashboard Config)
   * The dashboard currently points at /webhooks/intasend.
   */
  @Post('intasend')
  async handleIntaSendWebhookAlias(
    @Headers('X-IntaSend-Signature') signature: string,
    @Body() body: any,
    @Req() req: RawBodyRequest<any>,
  ) {
    return this.paymentsController.handleIntaSendWebhook(req, signature, body);
  }
}
