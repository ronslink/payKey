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
  private readonly webhookSecret: string;
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

    this.logger.debug(`INTASEND_IS_LIVE env: ${this.configService.get('INTASEND_IS_LIVE')}`);
    this.logger.debug(`Publishable Key Set: ${this.publishableKey ? 'Yes' : 'No'} (${this.publishableKey ? this.publishableKey.substring(0, 10) + '...' : 'None'})`);
    this.logger.debug(`Secret Key Set: ${this.secretKey ? 'Yes' : 'No'} (${this.secretKey ? this.secretKey.substring(0, 5) + '...' : 'None'})`);

    if (!this.publishableKey || !this.secretKey) {

      this.logger.warn(
        'IntaSend Keys are missing! Please check .env configuration',
      );
    }

    const configuredWebhookSecret = this.configService.get('INTASEND_WEBHOOK_SECRET');

    if (configuredWebhookSecret) {
      this.webhookSecret = configuredWebhookSecret;
    } else {
      this.logger.warn(
        '⚠️ INTASEND_WEBHOOK_SECRET not set. Falling back to INTASEND_SECRET_KEY for webhook verification.',
      );
      this.webhookSecret = this.secretKey;
    }
  }

  verifyWebhookSignature(signature: string, rawBody: Buffer, challenge?: string): boolean {
    const configuredChallenge = this.configService.get('INTASEND_CHALLENGE');

    // 1. Prioritize Challenge Verification (Official Docs Method)
    if (configuredChallenge && challenge) {
      if (configuredChallenge === challenge) {
        this.logger.log('✅ Webhook Challenge matched.');
        return true;
      }
      this.logger.warn(`⛔ Webhook Challenge Mismatch: Expected ${configuredChallenge}, got ${challenge}`);
      // Fallthrough to signature check? No, if challenge is mismatched, it's definitely invalid.
      return false;
    }

    // 2. Fallback to Signature Verification (Security Best Practice)
    if (!signature) {
      if (!configuredChallenge) {
        this.logger.warn('⚠️ Webhook missing both Signature and Challenge configuration. Rejecting.');
        return false;
      }
      this.logger.warn('⚠️ Webhook missing Signature, but Challenge not verified (missing in request or config). Rejecting.');
      return false;
    }

    if (!rawBody) {
      this.logger.warn(
        '⚠️ Webhook missing raw body. Ensure main.ts captures it.',
      );
      return false;
    }

    // Use dedicated webhook secret (or fallback to secret key)
    const hmac = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(rawBody)
      .digest('hex');

    if (hmac !== signature) {
      this.logger.warn(
        `⛔ Invalid Webhook Signature. Expected: ${hmac}, Received: ${signature}`,
      );
      return false;
    }

    this.logger.log('✅ Webhook Signature matched.');
    return true;
  }

  /**
   * Initiate STK Push (Collection)
   */
  async initiateStkPush(
    phoneNumber: string,
    amount: number,
    apiRef: string = 'PayKey',
    walletId?: string,
  ) {
    // SIMULATION MODE
    // Trigger if Env Var is true OR Magic Amount 777
    // We removed the blanket 'sandbox' check to allow testing against the REAL IntaSend Sandbox if desired.
    // FIX: Ensure we NEVER simulate in Live mode/Production
    const simulateVar = this.configService.get('INTASEND_SIMULATE');
    this.logger.log(`[DEBUG] Simulate Check: Var=${simulateVar} (${typeof simulateVar}), Amount=${amount}, IsLive=${this.isLive}`);

    if ((simulateVar === 'true' || amount === 777) && !this.isLive) {
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

          // Generate valid signature for simulation
          const payloadString = JSON.stringify(payload);
          const signature = crypto
            .createHmac('sha256', this.secretKey)
            .update(payloadString)
            .digest('hex');

          this.logger.log(`⚠️ SIMULATION: Sending webhook with signature`);

          const response = await lastValueFrom(
            this.httpService.post(
              'http://localhost:3000/payments/intasend/webhook',
              payloadString,  // Send as string for signature verification
              {
                headers: {
                  'Content-Type': 'application/json',
                  'X-IntaSend-Signature': signature,
                },
              },
            ),
          );
          this.logger.log('✅ SIMULATION: Webhook sent successfully', response.data);
        } catch (e) {
          this.logger.error('❌ Simulation Callback Failed:', e.response?.data || e.message);
        }
      }, 3000);

      return {
        invoice: { invoice_id: invoiceId, state: 'PENDING' },
        tracking_id: trackingId,
        customer: { phone_number: phoneNumber },
      };
    }

    // Use the provided phone number directly. 
    // IntaSend Sandbox supports real STK pushes to real numbers for verification.
    const effectivePhone = phoneNumber;

    const url = `${this.baseUrl}/v1/payment/mpesa-stk-push/`;
    this.logger.log(
      `Initiating IntaSend STK Push to ${effectivePhone} (Original: ${phoneNumber}) for ${amount} at URL: ${url}`,
    );

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            phone_number: effectivePhone,
            email: 'noreply@paykey.com', // Required by IntaSend sometimes
            amount: amount,
            api_ref: apiRef,
            wallet_id: walletId,
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
   * Create a new Wallet
   */
  async createWallet(currency: 'KES' | 'USD' | 'EUR' | 'GBP', label: string, canDisburse = true) {
    const url = `${this.baseUrl}/v1/wallets/`;
    this.logger.log(`Creating IntaSend Wallet: ${label} (${currency})`);

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            label: label,
            wallet_type: 'WORKING',
            currency: currency,
            can_disburse: canDisburse,
          },
          {
            headers: {
              Authorization: `Bearer ${this.secretKey}`,
            },
          },
        ),
      );
      this.logger.log('IntaSend Create Wallet response:', response.data);
      return response.data;
    } catch (error) {
      this.logger.error(
        'IntaSend Create Wallet failed',
        error.response?.data || error.message,
      );
      throw new Error(
        `IntaSend Create Wallet failed: ${JSON.stringify(error.response?.data)}`,
      );
    }
  }

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
    walletId?: string,
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

    // Validating Config
    const simulateVar = this.configService.get('INTASEND_SIMULATE');
    const isTestAmount = transactions.some(t => t.amount === 777);

    // Simulation Block
    if ((simulateVar === 'true' || isTestAmount) && !this.isLive) {
      this.logger.log(`⚠️ SIMULATION: IntaSend Payout (B2C) for ${transactions.length} txns`);

      const trackingId = `TRK_SIM_B2C_${Date.now()}`;
      const invoiceId = `INV_SIM_B2C_${Date.now()}`;

      // Simulate Webhook for EACH transaction? 
      // IntaSend B2C sends one webhook per request or per transaction? 
      // Usually per batch request (tracking_id) or per line item.
      // For simplicity, let's assume we match by tracking_id for the batch.

      setTimeout(async () => {
        try {
          this.logger.log('⚠️ SIMULATION: Sending B2C Webhook...');
          const payload = {
            tracking_id: trackingId,
            invoice_id: invoiceId, // Sometimes B2C uses tracking_id as ref
            state: 'COMPLETE',
            provider: 'MPESA-B2C',
            charges: '10.00',
            net_amount: transactions.reduce((sum, t) => sum + t.amount, 0),
            currency: 'KES',
            value: transactions.reduce((sum, t) => sum + t.amount, 0),
            account: transactions[0].account,
            api_ref: null, // B2C might not return the api_ref we want? check docs.
            host: 'localhost',
            challenge: null,
          };

          const payloadString = JSON.stringify(payload);
          const signature = crypto
            .createHmac('sha256', this.webhookSecret || this.secretKey)
            .update(payloadString)
            .digest('hex');

          await lastValueFrom(
            this.httpService.post(
              'http://localhost:3000/payments/intasend/webhook',
              payloadString,
              { headers: { 'X-IntaSend-Signature': signature, 'Content-Type': 'application/json' } }
            )
          );
          this.logger.log('✅ SIMULATION: B2C Webhook sent');
        } catch (e) {
          this.logger.error('❌ Simulation Callback Failed:', e.message);
        }
      }, 3000);

      return {
        tracking_id: trackingId,
        status: 'Processing',
        transactions: transactions.map(t => ({
          status: 'Pending',
          ...t
        }))
      };
    }

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            provider: 'MPESA-B2C',
            currency: 'KES',
            transactions: formattedTransactions,
            wallet_id: walletId,
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
      throw error;
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
  async getWalletBalance(walletId?: string) {
    let url = `${this.baseUrl}/v1/wallets/`;
    if (walletId) {
      url += `${walletId}/`;
    }

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

  /**
   * Static fallback list of Kenyan banks (used when API is unavailable)
   */
  private static readonly KENYAN_BANKS = [
    { bank_code: '1', bank_name: 'Kenya Commercial Bank' },
    { bank_code: '2', bank_name: 'Standard Chartered Bank Kenya' },
    { bank_code: '3', bank_name: 'Barclays Bank of Kenya' },
    { bank_code: '7', bank_name: 'Commercial Bank of Africa' },
    { bank_code: '10', bank_name: 'Prime Bank' },
    { bank_code: '11', bank_name: 'Co-operative Bank of Kenya' },
    { bank_code: '12', bank_name: 'National Bank of Kenya' },
    { bank_code: '14', bank_name: 'Oriental Commercial Bank' },
    { bank_code: '16', bank_name: 'Citibank N.A. Kenya' },
    { bank_code: '18', bank_name: 'Middle East Bank Kenya' },
    { bank_code: '19', bank_name: 'Bank of Africa Kenya' },
    { bank_code: '23', bank_name: 'Consolidated Bank of Kenya' },
    { bank_code: '25', bank_name: 'Credit Bank' },
    { bank_code: '26', bank_name: 'Trans-National Bank' },
    { bank_code: '30', bank_name: 'Chase Bank Kenya' },
    { bank_code: '31', bank_name: 'Stanbic Bank Kenya' },
    { bank_code: '35', bank_name: 'African Banking Corporation' },
    { bank_code: '39', bank_name: 'Imperial Bank' },
    { bank_code: '41', bank_name: 'NIC Bank' },
    { bank_code: '43', bank_name: 'Ecobank Kenya' },
    { bank_code: '49', bank_name: 'Equity Bank Kenya' },
    { bank_code: '50', bank_name: 'Paramount Universal Bank' },
    { bank_code: '51', bank_name: 'Jamii Bora Bank' },
    { bank_code: '53', bank_name: 'Guaranty Trust Bank Kenya' },
    { bank_code: '54', bank_name: 'Victoria Commercial Bank' },
    { bank_code: '55', bank_name: 'Guardian Bank' },
    { bank_code: '57', bank_name: 'I&M Bank' },
    { bank_code: '61', bank_name: 'HFC Limited' },
    { bank_code: '63', bank_name: 'Diamond Trust Bank Kenya' },
    { bank_code: '66', bank_name: 'Sidian Bank' },
    { bank_code: '68', bank_name: 'Family Bank' },
    { bank_code: '70', bank_name: 'Gulf African Bank' },
    { bank_code: '72', bank_name: 'First Community Bank' },
    { bank_code: '74', bank_name: 'KWFT Bank' },
    { bank_code: '76', bank_name: 'UBA Kenya Bank' },
    { bank_code: '78', bank_name: 'Kingdom Bank' },
    { bank_code: '79', bank_name: 'Mayfair Bank' },
    { bank_code: '98', bank_name: 'NCBA Bank Kenya' },
  ];

  /**
   * Get list of supported Kenyan bank codes
   * Falls back to static list if API is unavailable
   */
  async getBankCodes() {
    const url = `${this.baseUrl}/v1/send-money/bank-codes/ke/`;
    try {
      const response = await lastValueFrom(
        this.httpService.get(url, {
          headers: {
            Authorization: `Bearer ${this.secretKey}`,
          },
        }),
      );
      this.logger.log(`Fetched ${response.data.length || 0} bank codes from API`);
      return response.data;
    } catch (error) {
      this.logger.warn(
        'Failed to fetch bank codes from API, using fallback list',
        error.response?.data || error.message,
      );
      // Return static fallback list
      return IntaSendService.KENYAN_BANKS;
    }
  }

  /**
   * Send Money to Bank Account (PesaLink)
   */
  async sendToBank(
    transactions: {
      name: string;
      account: string; // Bank account number
      bankCode: string; // IntaSend bank code
      amount: number;
      narrative?: string;
    }[],
    walletId?: string,
  ) {
    const url = `${this.baseUrl}/v1/send-money/initiate/`;
    this.logger.log(
      `Initiating IntaSend Bank Payout for ${transactions.length} record(s)`,
    );

    const formattedTransactions = transactions.map((t) => ({
      name: t.name,
      account: t.account,
      bank_code: t.bankCode,
      amount: t.amount,
      narrative: t.narrative || 'Salary Payment',
    }));

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            provider: 'PESALINK',
            currency: 'KES',
            transactions: formattedTransactions,
            wallet_id: walletId,
          },
          {
            headers: {
              Authorization: `Bearer ${this.secretKey}`,
            },
          },
        ),
      );
      this.logger.log('IntaSend Bank Payout response:', response.data);
      return response.data;
    } catch (error) {
      this.logger.error(
        'IntaSend Bank Payout failed',
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  /**
   * Create Checkout URL for Collection (Card/PesaLink)
   */
  async createCheckoutUrl(
    amount: number,
    email: string,
    firstName: string,
    lastName: string,
    reference: string,
    walletId?: string,
  ) {
    // Docs: https://developers.intasend.com/docs/working-wallets/collect-payments/#initiate-collection
    const url = `${this.baseUrl}/v1/checkout/`;
    try {
      const response = await lastValueFrom(
        this.httpService.post(
          url,
          {
            public_key: this.publishableKey,
            amount: amount,
            currency: 'KES',
            email: email,
            first_name: firstName,
            last_name: lastName,
            api_ref: reference,
            redirect_url: 'https://paydome.co/payment/success', // Or mobile deep link
            method: 'M-PESA-STK-PUSH,CARD-PAYMENT,BANK-PAYMENT', // Enable PesaLink (BANK-PAYMENT)
            wallet_id: walletId,
          },
          {
            headers: {
              Authorization: `Bearer ${this.secretKey}`,
            },
          },
        ),
      );
      this.logger.log('Checkout URL created:', response.data);
      return response.data; // Expected: { url: "...", signature: "...", ... }
    } catch (error) {
      this.logger.error(
        'Failed to create checkout URL',
        error.response?.data || error.message,
      );
      throw error;
    }
  }
}
