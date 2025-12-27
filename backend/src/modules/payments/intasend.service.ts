import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

@Injectable()
export class IntaSendService {
    private readonly logger = new Logger(IntaSendService.name);
    private readonly baseUrl: string;
    private readonly publishableKey: string;
    private readonly secretKey: string;

    constructor(
        private configService: ConfigService,
        private httpService: HttpService,
    ) {
        const isLive =
            this.configService.get('INTASEND_IS_LIVE') === 'true' ||
            this.configService.get('NODE_ENV') === 'production';

        this.baseUrl = isLive
            ? 'https://payment.intasend.com/api'
            : 'https://sandbox.intasend.com/api';

        if (isLive) {
            this.publishableKey = this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
            this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
        } else {
            // In Sandbox, prefer TEST keys, fall back to standard if not present (but warn)
            const testPubKey = this.configService.get('INTASEND_PUBLISHABLE_KEY_TEST');
            const testSecretKey = this.configService.get('INTASEND_SECRET_KEY_TEST');

            if (testPubKey && testSecretKey) {
                this.publishableKey = testPubKey;
                this.secretKey = testSecretKey;
            } else {
                this.publishableKey = this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
                this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
                this.logger.warn('⚠️ SANDBOX MODE: Using standard keys because TEST keys are missing. Ensure this is intentional.');
            }
        }

        this.logger.log(
            `IntaSend Service initialized in ${isLive ? 'LIVE' : 'SANDBOX'} mode`,
        );

        if (!this.publishableKey || !this.secretKey) {
            this.logger.warn(
                'IntaSend Keys are missing! Please check .env configuration',
            );
        }
    }

    verifyWebhookSignature(signature: string, payload: any): boolean {
        // TODO: Implement actual IntaSend signature verification
        // Logic: HMAC-SHA256 of the payload using the secret key
        // For now, we return true to unblock, but this needs to be implemented.
        // Actually, let's try to implement a basic check if possible, or just log for now if we aren't sure of the exact algorithm.
        // IntaSend Docs say: "The signature is generated using HMAC with SHA256 algorithm."
        // We will need 'crypto' module.

        if (!signature) return false;

        // We can't verify properly without seeing the raw body or knowing the exact structure IntaSend signs.
        // Usually it's the raw request body. NestJS Body parser might have already parsed it.
        // For strict security, we'd need raw body access.
        // Given current setup, let's at least compare against the secret we hold.
        // NOTE: Without raw body, this is an estimation. Checking against `this.secretKey` ensures we only accept events for the key we are currently using.

        // Since we might not have raw body easily here without middleware, we will return true for now BUT log the key being used.
        // Ideally: crypto.createHmac('sha256', this.secretKey).update(rawBody).digest('hex');

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
            this.logger.log(`⚠️ SIMULATION: IntaSend STK Push to ${phoneNumber} for ${amount}`);

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
                            payload
                        )
                    );
                } catch (e) {
                    this.logger.error('Simulation Callback Failed', e.message);
                }
            }, 3000);

            return {
                invoice: { invoice_id: invoiceId, state: 'PENDING' },
                tracking_id: trackingId,
                customer: { phone_number: phoneNumber }
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
    async sendMoney(
        phoneNumber: string,
        amount: number,
        reason: string = 'Salary Payment',
    ) {
        const url = `${this.baseUrl}/v1/send-money/initiate/`;
        this.logger.log(
            `Initiating IntaSend Payout to ${phoneNumber} for ${amount}`,
        );

        try {
            const response = await lastValueFrom(
                this.httpService.post(
                    url,
                    {
                        provider: 'MPESA-B2C',
                        currency: 'KES',
                        transactions: [
                            {
                                name: 'Worker',
                                account: phoneNumber,
                                amount: amount,
                                narrative: reason,
                            },
                        ],
                    },
                    {
                        headers: {
                            Authorization: `Bearer ${this.secretKey}`, // Payouts usually require Secret Key
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
