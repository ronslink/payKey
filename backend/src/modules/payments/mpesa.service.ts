import { Injectable, Logger, Inject, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from './entities/transaction.entity';

const MPESA_TOKEN_CACHE_KEY = 'mpesa:access_token';
const MPESA_TOKEN_TTL = 55 * 60 * 1000; // 55 minutes (token valid for 1hr)

@Injectable()
export class MpesaService {
  private readonly logger = new Logger(MpesaService.name);
  private readonly baseUrl: string;

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    @Optional() @Inject(CACHE_MANAGER) private cacheManager?: Cache,
  ) {
    // Use MPESA_BASE_URL env var, fallback to sandbox for development
    this.baseUrl =
      this.configService.get('MPESA_BASE_URL') ||
      'https://sandbox.safaricom.co.ke';

    this.logger.log(`M-Pesa API configured for: ${this.baseUrl}`);
  }

  async getAccessToken(): Promise<string> {
    // Try to get cached token first
    if (this.cacheManager) {
      const cachedToken = await this.cacheManager.get<string>(
        MPESA_TOKEN_CACHE_KEY,
      );
      if (cachedToken) {
        this.logger.debug('Using cached M-Pesa access token');
        return cachedToken;
      }
    }

    const consumerKey = this.configService.get('MPESA_CONSUMER_KEY');
    const consumerSecret = this.configService.get('MPESA_CONSUMER_SECRET');
    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString(
      'base64',
    );

    try {
      const response = await lastValueFrom(
        this.httpService.get(
          `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
          {
            headers: { Authorization: `Basic ${auth}` },
          },
        ),
      );
      const token = response.data.access_token;

      // Cache the token
      if (this.cacheManager) {
        await this.cacheManager.set(
          MPESA_TOKEN_CACHE_KEY,
          token,
          MPESA_TOKEN_TTL,
        );
        this.logger.debug('Cached M-Pesa access token for 55 minutes');
      }

      return token;
    } catch (error) {
      this.logger.error('Failed to get M-Pesa access token', error);
      throw error;
    }
  }

  private readonly MPESA_MAX_AMOUNT = 150000;

  async initiateStkPush(
    userId: string,
    phoneNumber: string,
    amount: number,
    accountReference: string = 'PayKey',
    transactionDesc: string = 'Wallet Topup',
    metadata: any = {},
  ) {
    if (amount > this.MPESA_MAX_AMOUNT) {
      throw new Error(
        `Amount cannot exceed M-Pesa limit of KES ${this.MPESA_MAX_AMOUNT}`,
      );
    }

    // SIMULATION MODE for Sandbox/Dev
    if (
      this.baseUrl.includes('sandbox') ||
      process.env.NODE_ENV !== 'production'
    ) {
      this.logger.log(
        `⚠️ SIMULATION: M-Pesa STK Push for ${phoneNumber} - ${amount}`,
      );
      const checkoutRequestId = `ws_CO_SIM_${Date.now()}`;
      const merchantRequestId = `MR_SIM_${Date.now()}`;

      // Create pending transaction first
      const transaction = this.transactionsRepository.create({
        userId,
        amount,
        currency: 'KES',
        type: TransactionType.DEPOSIT,
        status: TransactionStatus.PENDING,
        provider: 'MPESA',
        accountReference,
        recipientPhone: phoneNumber,
        createdAt: new Date(),
        metadata, // Store metadata
        providerRef: merchantRequestId,
      });
      await this.transactionsRepository.save(transaction);

      // Simulate Callback after delay
      setTimeout(async () => {
        try {
          this.logger.log('⚠️ SIMULATION: Sending Success Callback...');
          const payload = {
            Body: {
              stkCallback: {
                MerchantRequestID: merchantRequestId,
                CheckoutRequestID: checkoutRequestId,
                ResultCode: 0,
                ResultDesc: 'The service request is processed successfully.',
                CallbackMetadata: {
                  Item: [
                    { Name: 'Amount', Value: amount },
                    { Name: 'MpesaReceiptNumber', Value: `SIM${Date.now()}` },
                    { Name: 'PhoneNumber', Value: phoneNumber },
                  ],
                },
              },
            },
          };
          // Post to local callback endpoint
          await lastValueFrom(
            this.httpService.post(
              'http://localhost:3000/payments/callback',
              payload,
            ),
          );
        } catch (e) {
          this.logger.error('Simulation Callback Failed', e);
        }
      }, 3000);

      // Return immediate success
      return {
        MerchantRequestID: merchantRequestId,
        CheckoutRequestID: checkoutRequestId,
        ResponseCode: '0',
        ResponseDescription: 'Success. Request accepted for processing',
        CustomerMessage: 'Success. Request accepted for processing',
      };
    }
    const token = await this.getAccessToken();
    const shortCode = this.configService.get('MPESA_SHORTCODE');
    const passkey = this.configService.get('MPESA_PASSKEY');
    const timestamp = new Date()
      .toISOString()
      .replace(/[^0-9]/g, '')
      .slice(0, 14);
    const password = Buffer.from(`${shortCode}${passkey}${timestamp}`).toString(
      'base64',
    );
    const callbackUrl = this.configService.get('MPESA_CALLBACK_URL');

    // Create a pending transaction record
    const transaction = this.transactionsRepository.create({
      userId,
      amount,
      currency: 'KES',
      type: TransactionType.DEPOSIT,
      status: TransactionStatus.PENDING,
      provider: 'MPESA',
      accountReference, // Store the reference
      recipientPhone: phoneNumber,
      metadata,
      createdAt: new Date(),
    });
    await this.transactionsRepository.save(transaction);

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          `${this.baseUrl}/mpesa/stkpush/v1/processrequest`,
          {
            BusinessShortCode: shortCode,
            Password: password,
            Timestamp: timestamp,
            TransactionType: 'CustomerPayBillOnline',
            Amount: Math.floor(amount), // M-Pesa accepts integers only
            PartyA: phoneNumber,
            PartyB: shortCode,
            PhoneNumber: phoneNumber,
            CallBackURL: `${callbackUrl}/payments/callback`,
            AccountReference: accountReference,
            TransactionDesc: transactionDesc,
          },
          {
            headers: { Authorization: `Bearer ${token}` },
          },
        ),
      );

      // Update transaction with MerchantRequestID if needed
      return response.data;
    } catch (error) {
      this.logger.error('STK Push failed', error);
      transaction.status = TransactionStatus.FAILED;
      await this.transactionsRepository.save(transaction);
      throw error;
    }
  }
  async sendB2C(
    transactionId: string,
    phoneNumber: string,
    amount: number,
    remarks: string,
  ): Promise<any> {
    // DEV MODE: Simulate success without calling actual M-Pesa API
    if (process.env.NODE_ENV !== 'production') {
      this.logger.log(
        `DEV MODE: Simulating B2C payment success for ${phoneNumber}, amount: ${amount}`,
      );

      // Simulate a short delay like real API
      await new Promise((resolve) => setTimeout(resolve, 500));

      // Update transaction as successful
      await this.transactionsRepository.update(transactionId, {
        status: TransactionStatus.SUCCESS,
        providerRef: `DEV_SIM_${Date.now()}`,
        metadata: {
          simulated: true,
          phoneNumber,
          amount,
          timestamp: new Date().toISOString(),
        } as any,
      });

      return {
        ConversationID: `DEV_${Date.now()}`,
        OriginatorConversationID: `DEV_ORIG_${Date.now()}`,
        ResponseCode: '0',
        ResponseDescription: 'DEV: Simulated success',
      };
    }

    const token = await this.getAccessToken();
    const shortCode = this.configService.get('MPESA_B2C_SHORTCODE') || '600981'; // Sandbox default
    const initiatorName =
      this.configService.get('MPESA_INITIATOR_NAME') || 'testapi';
    const securityCredential = this.configService.get(
      'MPESA_SECURITY_CREDENTIAL',
    ); // Encrypted password
    const callbackUrl = this.configService.get('MPESA_CALLBACK_URL');

    // In a real app, you'd generate the security credential properly.
    // For sandbox, we assume it's provided in env.

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          `${this.baseUrl}/mpesa/b2c/v1/paymentrequest`,
          {
            InitiatorName: initiatorName,
            SecurityCredential: securityCredential,
            CommandID: 'SalaryPayment',
            Amount: amount,
            PartyA: shortCode,
            PartyB: phoneNumber,
            Remarks: remarks,
            QueueTimeOutURL: `${callbackUrl}/payments/b2c/timeout`,
            ResultURL: `${callbackUrl}/payments/b2c/result`,
            Occasion: 'Salary',
          },
          {
            headers: { Authorization: `Bearer ${token}` },
          },
        ),
      );

      // Update transaction with ConversationID
      await this.transactionsRepository.update(transactionId, {
        providerRef: response.data.ConversationID,
        // We don't set status to SUCCESS yet; we wait for callback.
        // But for MVP without callbacks, we might optimistically set it or keep it PENDING.
        // Let's keep it PENDING.
      });

      return response.data;
    } catch (error) {
      this.logger.error('B2C Payment failed', error);
      await this.transactionsRepository.update(transactionId, {
        status: TransactionStatus.FAILED,
        metadata: { error: error.message },
      });
      // Don't throw, just return error so payroll process continues for others
      return { error: error.message };
    }
  }
}
