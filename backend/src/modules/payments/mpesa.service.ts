import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from './entities/transaction.entity';

@Injectable()
export class MpesaService {
  private readonly logger = new Logger(MpesaService.name);
  private readonly baseUrl = 'https://sandbox.safaricom.co.ke'; // Use env for prod

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
  ) { }

  async getAccessToken(): Promise<string> {
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
      return response.data.access_token;
    } catch (error) {
      this.logger.error('Failed to get M-Pesa access token', error);
      throw error;
    }
  }

  private readonly MPESA_MAX_AMOUNT = 150000;

  async initiateStkPush(userId: string, phoneNumber: string, amount: number) {
    if (amount > this.MPESA_MAX_AMOUNT) {
      throw new Error(`Amount cannot exceed M-Pesa limit of KES ${this.MPESA_MAX_AMOUNT}`);
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

    // Create pending transaction
    const transaction = this.transactionsRepository.create({
      userId,
      amount,
      type: TransactionType.TOPUP,
      status: TransactionStatus.PENDING,
      metadata: { phoneNumber },
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
            Amount: amount,
            PartyA: phoneNumber,
            PartyB: shortCode,
            PhoneNumber: phoneNumber,
            CallBackURL: `${callbackUrl}/payments/callback`,
            AccountReference: 'PayKey',
            TransactionDesc: 'Wallet Topup',
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
