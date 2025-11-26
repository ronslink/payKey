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
exports.SubscriptionsController = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const subscription_entity_1 = require("./entities/subscription.entity");
const subscription_payment_entity_1 = require("./entities/subscription-payment.entity");
const subscription_plans_config_1 = require("./subscription-plans.config");
let SubscriptionsController = class SubscriptionsController {
    subscriptionRepository;
    subscriptionPaymentRepository;
    constructor(subscriptionRepository, subscriptionPaymentRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.subscriptionPaymentRepository = subscriptionPaymentRepository;
    }
    getPlans() {
        return subscription_plans_config_1.SUBSCRIPTION_PLANS.map((plan, index) => ({
            id: plan.tier.toLowerCase(),
            tier: plan.tier,
            name: plan.name,
            description: `${plan.name} plan - Up to ${plan.workerLimit} workers`,
            price_usd: plan.priceUSD,
            price_kes: plan.priceKES,
            currency: 'USD',
            active: true,
            features: this.convertFeaturesToMap(plan.features),
            sort_order: index + 1,
            worker_limit: plan.workerLimit,
            billing_period: 'monthly',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
        }));
    }
    convertFeaturesToMap(features) {
        const featureMap = {};
        features.forEach(feature => {
            const key = feature.toLowerCase()
                .replace(/\s+/g, '_')
                .replace(/[^a-z0-9_]/g, '')
                .replace(/_+/g, '_');
            featureMap[key] = true;
        });
        return featureMap;
    }
    async getCurrentSubscription(req) {
        const subscription = await this.subscriptionRepository.findOne({
            where: {
                userId: req.user.userId,
                status: subscription_entity_1.SubscriptionStatus.ACTIVE
            },
            relations: ['user']
        });
        if (!subscription) {
            const userData = await this.subscriptionRepository.manager.findOne('users', {
                where: { id: req.user.userId }
            });
            return {
                id: null,
                tier: 'FREE',
                planName: 'Free Tier',
                price: 0,
                currency: 'KES',
                features: ['Up to 1 worker', 'Automatic tax calculations'],
                isActive: true,
                startDate: null,
                endDate: null,
                user: userData,
            };
        }
        return {
            ...subscription,
            planName: subscription_plans_config_1.SUBSCRIPTION_PLANS.find(p => p.tier === subscription.tier)?.name || 'Unknown Plan'
        };
    }
    async subscribe(req, body) {
        const plan = subscription_plans_config_1.SUBSCRIPTION_PLANS.find(p => p.tier.toLowerCase() === body.planId.toLowerCase());
        if (!plan) {
            throw new Error('Invalid plan ID');
        }
        let subscription = await this.subscriptionRepository.findOne({
            where: { userId: req.user.userId }
        });
        if (!subscription) {
            subscription = this.subscriptionRepository.create({
                userId: req.user.userId,
                tier: plan.tier,
                status: subscription_entity_1.SubscriptionStatus.ACTIVE,
                startDate: new Date(),
            });
        }
        else {
            subscription.tier = plan.tier;
            subscription.status = subscription_entity_1.SubscriptionStatus.ACTIVE;
            subscription.updatedAt = new Date();
        }
        return this.subscriptionRepository.save(subscription);
    }
    async getSubscriptionPaymentHistory(req) {
        const payments = await this.subscriptionPaymentRepository.find({
            where: { userId: req.user.userId },
            order: { createdAt: 'DESC' }
        });
        return payments || [];
    }
};
exports.SubscriptionsController = SubscriptionsController;
__decorate([
    (0, common_1.Get)('plans'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SubscriptionsController.prototype, "getPlans", null);
__decorate([
    (0, common_1.Get)('current'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getCurrentSubscription", null);
__decorate([
    (0, common_1.Post)('subscribe'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "subscribe", null);
__decorate([
    (0, common_1.Get)('subscription-payment-history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getSubscriptionPaymentHistory", null);
exports.SubscriptionsController = SubscriptionsController = __decorate([
    (0, common_1.Controller)('subscriptions'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(subscription_payment_entity_1.SubscriptionPayment)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], SubscriptionsController);
//# sourceMappingURL=subscriptions.controller.js.map