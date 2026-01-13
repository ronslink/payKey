import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import * as crypto from 'crypto';

// IntaSend sandbox requires this specific phone number for B2C payouts
const INTASEND_SANDBOX_TEST_PHONE = '254708374149';

@Injectable()
export class IntaSendService {
  private readonly logger = new Logger(IntaSendService.name);
  private readonly baseUrl: string;
  private readonly publishableKey: string;
  private readonly secretKey: string;
  private readonly isLive: boolean;

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
  ) {
    this.isLive =
      this.configService.get('INTASEND_IS_LIVE') === 'true' ||
      this.configService.get('NODE_ENV') === 'production';

    this.baseUrl = this.isLive
      ? 'https://payment.intasend.com/api'
      : 'https://sandbox.intasend.com/api';

    if (this.isLive) {
      this.publishableKey =
        this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
      this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
    } else {
      // In Sandbox, prefer TEST keys, fall back to standard if not present (but warn)
      const testPubKey = this.configService.get(
        'INTASEND_PUBLISHABLE_KEY_TEST',
      );
      const testSecretKey = this.configService.get('INTASEND_SECRET_KEY_TEST');

      if (testPubKey && testSecretKey) {
        this.publishableKey = testPubKey;
        this.secretKey = testSecretKey;
      } else {
        this.publishableKey =
          this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
        this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
        this.logger.warn(
          '⚠️ SANDBOX MODE: Using standard keys because TEST keys are missing. Ensure this is intentional.',
        );
      }
    }

    this.logger.log(
      `IntaSend Service initialized in ${this.isLive ? 'LIVE' : 'SANDBOX'} mode`,
    );

    if (!this.publishableKey || !this.secretKey) {
      this.logger.warn(
        'IntaSend Keys are missing! Please check .env configuration',
      );
    }
  }

  verifyWebhookSignature(signature: string, rawBody: Buffer): boolean {
    if (!signature) {
      this.logger.warn('⚠️ Webhook missing X-IntaSend-Signature header');
      return false; // Fail secure
    }

    if (!rawBody) {
      this.logger.warn(
        '⚠️ Webhook missing raw body. Ensure main.ts captures it.',
      );
      return false;
    }

    // Use current secret key (Sandbox or Live depending on init)
    const hmac = crypto
      .createHmac('sha256', this.secretKey)
      .update(rawBody)
      .digest('hex');

    if (hmac !== signature) {
      this.logger.warn(
        `⛔ Invalid Webhook Signature. Expected: ${hmac}, Received: ${signature}`,
      );
      return false;
    }

    return true;
  }

  /**
   * Initiate STK Push (Collection)
   */
  async initiateStkPush(
    phoneNumber: string,
    amount: number,
    apiRef: string = 'PayKey',
  ) {
    // SIMULATION MODE
    // Trigger if Env Var is true OR Magic Amount 777
    // We removed the blanket 'sandbox' check to allow testing against the REAL IntaSend Sandbox if desired.
    if (process.env.INTASEND_SIMULATE === 'true' || amount === 777) {
      this.logger.log(
        `⚠️ SIMULATION: IntaSend STK Push to ${phoneNumber} for ${amount}`,
      );

      const invoiceId = `INV_SIM_${Date.now()}`;
      const trackingId = `TRK_SIM_${Date.now()}`;

      // Simulate Webhook Callback
      setTimeout(async () => {
        try {
          this.logger.log('⚠️ SIMULATION: Sending IntaSend Webhook...');
          const payload = {
            invoice_id: invoiceId,
            state: 'COMPLETE',
            provider: 'MPESA',
            charges: '0.00',
            net_amount: amount,
            currency: 'KES',
            value: amount,
            account: phoneNumber,
            api_ref: apiRef,
            host: 'localhost',
            challenge: null,
          };

          await lastValueFrom(
            this.httpService.post(
              'http://localhost:3000/payments/intasend/webhook',
              payload,
            ),
          );
        } catch (e) {
          this.logger.error('Simulation Callback Failed', e.message);
        }
      }, 3000);

      return {
        invoice: { invoice_id: invoiceId, state: 'PENDING' },
        tracking_id: trackingId,
        customer: { phone_number: phoneNumber },
      };
    }

    const url = `${this.baseUrl}/v1/payment/mpesa-stk-push/`;
    this.logger.log(
      `Initiating IntaSend STK Push to ${phoneNumber} for ${amount}`,
    );

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            phone_number: phoneNumber,
            email: 'noreply@paykey.com', // Required by IntaSend sometimes
            amount: amount,
            api_ref: apiRef,
          },
          {
            headers: {
              Authorization: `Bearer ${this.secretKey}`, // Backend uses Secret Key matching Mobile impl
            },
          },
        ),
      );
      this.logger.log('IntaSend STK Push response:', response.data);
      return response.data;
    } catch (error) {
      this.logger.error(
        'IntaSend STK Push failed',
        error.response?.data || error.message,
      );
      throw new Error(
        `IntaSend STK Push failed: ${JSON.stringify(error.response?.data)}`,
      );
    }
  }

  /**
   * Send Money (B2C / Payroll)
   */
  /**
   * Send Money (B2C / Payroll) - Supports Bulk
   */
  async sendMoney(
    transactions: {
      account: string;
      amount: number;
      narrative?: string;
      name?: string;
    }[],
  ) {
    const url = `${this.baseUrl}/v1/send-money/initiate/`;
    this.logger.log(
      `Initiating IntaSend Payout for ${transactions.length} record(s)`,
    );

    // Sandbox override logic
    const formattedTransactions = transactions.map((t) => {
      const effectivePhone = this.isLive
        ? t.account
        : INTASEND_SANDBOX_TEST_PHONE;

      return {
        name: t.name || 'Worker',
        account: effectivePhone,
        amount: t.amount,
        narrative: t.narrative || 'Salary Payment',
      };
    });

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            provider: 'MPESA-B2C',
            currency: 'KES',
            transactions: formattedTransactions,
          },
          {
            headers: {
              Authorization: `Bearer ${this.secretKey}`,
            },
          },
        ),
      );
      this.logger.log('IntaSend Payout response:', response.data);
      return response.data;
    } catch (error) {
      this.logger.error(
        'IntaSend Payout failed',
        error.response?.data || error.message,
      );
      throw new Error(
        `IntaSend Payout failed: ${JSON.stringify(error.response?.data)}`,
      );
    }
  }

  /**
   * Check Payout Status
   */
  async checkPayoutStatus(trackingId: string) {
    const url = `${this.baseUrl}/v1/send-money/status/${trackingId}/`;
    try {
      const response = await lastValueFrom(
        this.httpService.get(url, {
          headers: {
            Authorization: `Bearer ${this.secretKey}`,
          },
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error(
        `Failed to check status for ${trackingId}`,
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  /**
   * Check Wallet Balance
   */
  async getWalletBalance() {
    const url = `${this.baseUrl}/v1/wallets/`;
    try {
      const response = await lastValueFrom(
        this.httpService.get(url, {
          headers: {
            Authorization: `Bearer ${this.secretKey}`,
          },
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error(
        'Failed to fetch IntaSend wallet',
        error.response?.data || error.message,
      );
      throw error;
    }
  }
}
