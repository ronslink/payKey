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

        this.publishableKey = this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
        this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';

        this.logger.log(
            `IntaSend Service initialized in ${isLive ? 'LIVE' : 'SANDBOX'} mode`,
        );

        if (!this.publishableKey || !this.secretKey) {
            this.logger.warn(
                'IntaSend Keys are missing! Please check INTASEND_PUBLISHABLE_KEY and INTASEND_SECRET_KEY in .env',
            );
        }
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
