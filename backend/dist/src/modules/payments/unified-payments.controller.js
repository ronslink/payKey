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
exports.UnifiedPaymentsController = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const stripe_service_1 = require("./stripe.service");
const mpesa_service_1 = require("./mpesa.service");
const transaction_entity_1 = require("./entities/transaction.entity");
const subscription_entity_1 = require("../subscriptions/entities/subscription.entity");
const subscription_payment_entity_1 = require("../subscriptions/entities/subscription-payment.entity");
const tax_payments_service_1 = require("../tax-payments/services/tax-payments.service");
const tax_payment_entity_1 = require("../tax-payments/entities/tax-payment.entity");
let UnifiedPaymentsController = class UnifiedPaymentsController {
    stripeService;
    mpesaService;
    taxPaymentsService;
    transactionRepository;
    subscriptionRepository;
    subscriptionPaymentRepository;
    static DEFAULT_STRIPE_ACCOUNT = {
        connected: false,
        charges_enabled: false,
        payouts_enabled: false,
        id: '',
    };
    constructor(stripeService, mpesaService, taxPaymentsService, transactionRepository, subscriptionRepository, subscriptionPaymentRepository) {
        this.stripeService = stripeService;
        this.mpesaService = mpesaService;
        this.taxPaymentsService = taxPaymentsService;
        this.transactionRepository = transactionRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.subscriptionPaymentRepository = subscriptionPaymentRepository;
    }
    async getDashboard(req) {
        const { userId } = req.user;
        const currentDate = new Date();
        const [transactionStats, recentTransactions, activeSubscriptionCount, currentSubscription, monthlyTaxSummary,] = await Promise.all([
            this.getTransactionStats(userId),
            this.getRecentTransactions(userId),
            this.getActiveSubscriptionCount(userId),
            this.getActiveSubscription(userId),
            this.taxPaymentsService.generateMonthlySummary(userId, currentDate.getFullYear(), currentDate.getMonth() + 1),
        ]);
        const pendingTaxPayments = this.countPendingTaxPayments(monthlyTaxSummary.taxes);
        return {
            overview: {
                totalTransactions: transactionStats.total,
                totalAmount: transactionStats.totalAmount,
                successfulTransactions: transactionStats.successful,
                pendingTransactions: transactionStats.pending,
                failedTransactions: transactionStats.failed,
                subscriptionsActive: activeSubscriptionCount,
                taxPaymentsPending: pendingTaxPayments,
            },
            recentTransactions,
            paymentMethods: this.buildPaymentMethodStatus(),
            subscription: this.buildSubscriptionInfo(currentSubscription),
            taxPayments: {
                totalDue: monthlyTaxSummary.totalDue,
                nextDeadline: monthlyTaxSummary.paymentInstructions.deadline,
                pendingPayments: pendingTaxPayments,
            },
        };
    }
    async createSubscription(req, body) {
        const { userId, email, name } = req.user;
        try {
            const checkoutSession = await this.stripeService.createCheckoutSession(userId, body.planId.toUpperCase(), email, name || email);
            return { checkoutUrl: checkoutSession.url };
        }
        catch (error) {
            this.throwBadRequest(error, 'Failed to create subscription');
        }
    }
    async cancelSubscription(req, subscriptionId) {
        const { userId } = req.user;
        const subscription = await this.subscriptionRepository.findOne({
            where: { id: subscriptionId, userId },
        });
        if (!subscription) {
            throw new common_1.HttpException('Subscription not found', common_1.HttpStatus.NOT_FOUND);
        }
        try {
            await this.stripeService.cancelSubscription(userId);
            return { message: 'Subscription cancelled successfully' };
        }
        catch (error) {
            this.throwBadRequest(error, 'Failed to cancel subscription');
        }
    }
    async initiateMpesaTopup(req, body) {
        const { userId } = req.user;
        try {
            const result = await this.mpesaService.initiateStkPush(userId, body.phoneNumber, body.amount);
            return {
                success: true,
                checkoutRequestId: result.CheckoutRequestID,
                message: 'STK push initiated successfully',
            };
        }
        catch (error) {
            this.throwBadRequest(error, 'Failed to initiate M-Pesa topup');
        }
    }
    async recordTaxPayment(req, body) {
        const { userId } = req.user;
        const now = new Date();
        try {
            const taxPayment = await this.taxPaymentsService.recordPayment(userId, {
                taxType: body.taxType,
                paymentYear: now.getFullYear(),
                paymentMonth: now.getMonth() + 1,
                amount: body.amount,
                paymentDate: body.paymentDate
                    ? new Date(body.paymentDate).toISOString().split('T')[0]
                    : undefined,
                paymentMethod: tax_payment_entity_1.PaymentMethod.BANK,
                receiptNumber: body.reference || 'manual-entry',
            });
            return {
                success: true,
                paymentId: taxPayment.id,
                message: 'Tax payment successful',
            };
        }
        catch (error) {
            this.throwBadRequest(error, 'Failed to record tax payment');
        }
    }
    async getTaxPaymentSummary(req) {
        const { userId } = req.user;
        const now = new Date();
        try {
            return await this.taxPaymentsService.generateMonthlySummary(userId, now.getFullYear(), now.getMonth() + 1);
        }
        catch (error) {
            this.throwBadRequest(error, 'Failed to get tax payment summary');
        }
    }
    async getPaymentMethods(req) {
        const { userId } = req.user;
        const activeSubscription = await this.getActiveSubscription(userId);
        return {
            stripe: {
                configured: false,
                accountId: '',
                chargesEnabled: false,
                payoutsEnabled: false,
            },
            mpesa: {
                configured: true,
                shortcode: process.env.MPESA_SHORTCODE || '174379',
            },
            subscription: {
                active: !!activeSubscription,
                tier: activeSubscription?.tier,
                status: activeSubscription?.status,
            },
        };
    }
    async getTransactionStats(userId) {
        const stats = await this.transactionRepository
            .createQueryBuilder('t')
            .select([
            'COUNT(*) as total',
            `SUM(CASE WHEN t.status = :success THEN 1 ELSE 0 END) as successful`,
            `SUM(CASE WHEN t.status = :pending THEN 1 ELSE 0 END) as pending`,
            `SUM(CASE WHEN t.status = :failed THEN 1 ELSE 0 END) as failed`,
            `COALESCE(SUM(CASE WHEN t.status = :success THEN t.amount ELSE 0 END), 0) as totalAmount`,
        ])
            .where('t.userId = :userId', { userId })
            .setParameters({
            success: transaction_entity_1.TransactionStatus.SUCCESS,
            pending: transaction_entity_1.TransactionStatus.PENDING,
            failed: transaction_entity_1.TransactionStatus.FAILED,
        })
            .getRawOne();
        return {
            total: parseInt(stats.total, 10) || 0,
            successful: parseInt(stats.successful, 10) || 0,
            pending: parseInt(stats.pending, 10) || 0,
            failed: parseInt(stats.failed, 10) || 0,
            totalAmount: parseFloat(stats.totalAmount) || 0,
        };
    }
    async getRecentTransactions(userId, limit = 10) {
        return this.transactionRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: limit,
        });
    }
    async getActiveSubscriptionCount(userId) {
        return this.subscriptionRepository.count({
            where: { userId, status: subscription_entity_1.SubscriptionStatus.ACTIVE },
        });
    }
    async getActiveSubscription(userId) {
        return this.subscriptionRepository.findOne({
            where: { userId, status: subscription_entity_1.SubscriptionStatus.ACTIVE },
        });
    }
    countPendingTaxPayments(taxes) {
        return taxes.filter((t) => t.status === subscription_payment_entity_1.PaymentStatus.PENDING.toString()).length;
    }
    buildPaymentMethodStatus() {
        return {
            mpesa: {
                status: 'connected',
                balance: 0,
            },
            stripe: {
                status: 'not_configured',
                accountConnected: false,
            },
        };
    }
    buildSubscriptionInfo(subscription) {
        return {
            currentPlan: subscription?.tier ?? subscription_entity_1.SubscriptionTier.FREE,
            nextBilling: subscription?.nextBillingDate ?? null,
            amount: subscription?.amount ?? 0,
        };
    }
    throwBadRequest(error, fallbackMessage) {
        const message = error instanceof Error ? error.message : fallbackMessage;
        throw new common_1.HttpException(message, common_1.HttpStatus.BAD_REQUEST);
    }
};
exports.UnifiedPaymentsController = UnifiedPaymentsController;
__decorate([
    (0, common_1.Get)('dashboard'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "getDashboard", null);
__decorate([
    (0, common_1.Post)('subscribe'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "createSubscription", null);
__decorate([
    (0, common_1.Put)('subscriptions/:id/cancel'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "cancelSubscription", null);
__decorate([
    (0, common_1.Post)('mpesa/topup'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "initiateMpesaTopup", null);
__decorate([
    (0, common_1.Post)('tax-payments/record'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "recordTaxPayment", null);
__decorate([
    (0, common_1.Get)('tax-payments/summary'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "getTaxPaymentSummary", null);
__decorate([
    (0, common_1.Get)('methods'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UnifiedPaymentsController.prototype, "getPaymentMethods", null);
exports.UnifiedPaymentsController = UnifiedPaymentsController = __decorate([
    (0, common_1.Controller)('payments/unified'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(3, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __param(4, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(5, (0, typeorm_1.InjectRepository)(subscription_payment_entity_1.SubscriptionPayment)),
    __metadata("design:paramtypes", [stripe_service_1.StripeService,
        mpesa_service_1.MpesaService,
        tax_payments_service_1.TaxPaymentsService,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], UnifiedPaymentsController);
//# sourceMappingURL=unified-payments.controller.js.map