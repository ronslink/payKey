"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var MpesaService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MpesaService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const axios_1 = require("@nestjs/axios");
const rxjs_1 = require("rxjs");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const transaction_entity_1 = require("./entities/transaction.entity");
let MpesaService = MpesaService_1 = class MpesaService {
    configService;
    httpService;
    transactionsRepository;
    logger = new common_1.Logger(MpesaService_1.name);
    baseUrl = 'https://sandbox.safaricom.co.ke';
    constructor(configService, httpService, transactionsRepository) {
        this.configService = configService;
        this.httpService = httpService;
        this.transactionsRepository = transactionsRepository;
    }
    async getAccessToken() {
        const consumerKey = this.configService.get('MPESA_CONSUMER_KEY');
        const consumerSecret = this.configService.get('MPESA_CONSUMER_SECRET');
        const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
        try {
            const response = await (0, rxjs_1.lastValueFrom)(this.httpService.get(`${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`, {
                headers: { Authorization: `Basic ${auth}` },
            }));
            return response.data.access_token;
        }
        catch (error) {
            this.logger.error('Failed to get M-Pesa access token', error);
            throw error;
        }
    }
    async initiateStkPush(userId, phoneNumber, amount) {
        const token = await this.getAccessToken();
        const shortCode = this.configService.get('MPESA_SHORTCODE');
        const passkey = this.configService.get('MPESA_PASSKEY');
        const timestamp = new Date()
            .toISOString()
            .replace(/[^0-9]/g, '')
            .slice(0, 14);
        const password = Buffer.from(`${shortCode}${passkey}${timestamp}`).toString('base64');
        const callbackUrl = this.configService.get('MPESA_CALLBACK_URL');
        const transaction = this.transactionsRepository.create({
            userId,
            amount,
            type: transaction_entity_1.TransactionType.TOPUP,
            status: transaction_entity_1.TransactionStatus.PENDING,
            metadata: { phoneNumber },
        });
        await this.transactionsRepository.save(transaction);
        try {
            const response = await (0, rxjs_1.lastValueFrom)(this.httpService.post(`${this.baseUrl}/mpesa/stkpush/v1/processrequest`, {
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
            }, {
                headers: { Authorization: `Bearer ${token}` },
            }));
            return response.data;
        }
        catch (error) {
            this.logger.error('STK Push failed', error);
            transaction.status = transaction_entity_1.TransactionStatus.FAILED;
            await this.transactionsRepository.save(transaction);
            throw error;
        }
    }
    async sendB2C(transactionId, phoneNumber, amount, remarks) {
        const token = await this.getAccessToken();
        const shortCode = this.configService.get('MPESA_B2C_SHORTCODE') || '600981';
        const initiatorName = this.configService.get('MPESA_INITIATOR_NAME') || 'testapi';
        const securityCredential = this.configService.get('MPESA_SECURITY_CREDENTIAL');
        const callbackUrl = this.configService.get('MPESA_CALLBACK_URL');
        try {
            const response = await (0, rxjs_1.lastValueFrom)(this.httpService.post(`${this.baseUrl}/mpesa/b2c/v1/paymentrequest`, {
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
            }, {
                headers: { Authorization: `Bearer ${token}` },
            }));
            await this.transactionsRepository.update(transactionId, {
                providerRef: response.data.ConversationID,
            });
            return response.data;
        }
        catch (error) {
            this.logger.error('B2C Payment failed', error);
            await this.transactionsRepository.update(transactionId, {
                status: transaction_entity_1.TransactionStatus.FAILED,
                metadata: { error: error.message },
            });
            return { error: error.message };
        }
    }
};
exports.MpesaService = MpesaService;
exports.MpesaService = MpesaService = MpesaService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(2, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        axios_1.HttpService,
        typeorm_2.Repository])
], MpesaService);
//# sourceMappingURL=mpesa.service.js.map