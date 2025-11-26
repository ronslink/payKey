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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsController = void 0;
const common_1 = require("@nestjs/common");
const mpesa_service_1 = require("./mpesa.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const transaction_entity_1 = require("./entities/transaction.entity");
let PaymentsController = class PaymentsController {
    mpesaService;
    transactionsRepository;
    constructor(mpesaService, transactionsRepository) {
        this.mpesaService = mpesaService;
        this.transactionsRepository = transactionsRepository;
    }
    async handleStkCallback(callbackData) {
        const { stkCallback } = callbackData.Body;
        if (stkCallback.ResultCode === 0) {
            console.log('Payment successful:', stkCallback);
            if (stkCallback.CallbackMetadata) {
                const metadata = stkCallback.CallbackMetadata.Item.reduce((acc, item) => {
                    acc[item.Name] = item.Value;
                    return acc;
                }, {});
                console.log('Payment metadata:', metadata);
                const transaction = await this.transactionsRepository.findOne({
                    where: { providerRef: stkCallback.MerchantRequestID },
                });
                if (transaction) {
                    transaction.status = 'SUCCESS';
                    transaction.metadata = metadata;
                    await this.transactionsRepository.save(transaction);
                }
            }
        }
        else {
            console.log('Payment failed:', stkCallback.ResultDesc);
            const transaction = await this.transactionsRepository.findOne({
                where: { providerRef: stkCallback.MerchantRequestID },
            });
            if (transaction) {
                transaction.status = 'FAILED';
                transaction.metadata = { error: stkCallback.ResultDesc };
                await this.transactionsRepository.save(transaction);
            }
        }
        return { ResultCode: 0, ResultDesc: 'Success' };
    }
    async handleB2CCallback(callbackData) {
        const { Result } = callbackData;
        if (Result.ResultCode === 0) {
            console.log('B2C payment successful:', Result);
            const transactionId = Result.TransactionID;
            const conversationId = Result.ConversationID;
            const transaction = await this.transactionsRepository.findOne({
                where: { providerRef: conversationId },
            });
            if (transaction) {
                transaction.status = 'SUCCESS';
                transaction.metadata = {
                    transactionId,
                    conversationId,
                    resultCode: Result.ResultCode,
                };
                await this.transactionsRepository.save(transaction);
            }
        }
        else {
            console.log('B2C payment failed:', Result.ResultDesc);
            const transaction = await this.transactionsRepository.findOne({
                where: { providerRef: Result.ConversationID },
            });
            if (transaction) {
                transaction.status = 'FAILED';
                transaction.metadata = {
                    error: Result.ResultDesc,
                    conversationId: Result.ConversationID,
                };
                await this.transactionsRepository.save(transaction);
            }
        }
        return { ResultCode: 0, ResultDesc: 'Success' };
    }
    handleB2CTimeout(timeoutData) {
        console.log('B2C payment timeout:', timeoutData);
        return { ResultCode: 0, ResultDesc: 'Success' };
    }
    async initiateStkPush(req, body) {
        return this.mpesaService.initiateStkPush(req.user.userId, body.phoneNumber, body.amount);
    }
    async sendB2CPayment(req, body) {
        return this.mpesaService.sendB2C(body.transactionId, body.phoneNumber, body.amount, body.remarks);
    }
};
exports.PaymentsController = PaymentsController;
__decorate([
    (0, common_1.Post)('callback'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "handleStkCallback", null);
__decorate([
    (0, common_1.Post)('b2c/result'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "handleB2CCallback", null);
__decorate([
    (0, common_1.Post)('b2c/timeout'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], PaymentsController.prototype, "handleB2CTimeout", null);
__decorate([
    (0, common_1.Post)('initiate-stk'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "initiateStkPush", null);
__decorate([
    (0, common_1.Post)('send-b2c'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "sendB2CPayment", null);
exports.PaymentsController = PaymentsController = __decorate([
    (0, common_1.Controller)('payments'),
    __param(1, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __metadata("design:paramtypes", [mpesa_service_1.MpesaService,
        typeorm_2.Repository])
], PaymentsController);
//# sourceMappingURL=payments.controller.js.map