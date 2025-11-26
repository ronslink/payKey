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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var StripeService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.StripeService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const stripe_1 = __importDefault(require("stripe"));
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("../subscriptions/entities/subscription.entity");
const subscription_payment_entity_1 = require("../subscriptions/entities/subscription-payment.entity");
let StripeService = StripeService_1 = class StripeService {
    configService;
    subscriptionRepository;
    paymentRepository;
    logger = new common_1.Logger(StripeService_1.name);
    stripe = null;
    constructor(configService, subscriptionRepository, paymentRepository) {
        this.configService = configService;
        this.subscriptionRepository = subscriptionRepository;
        this.paymentRepository = paymentRepository;
        const secretKey = this.configService.get('STRIPE_SECRET_KEY');
        if (!secretKey) {
            this.logger.warn('Stripe secret key not configured');
        }
        else {
            this.stripe = new stripe_1.default(secretKey, { apiVersion: '2024-06-20' });
        }
    }
    ensureStripeConfigured() {
        if (!this.stripe) {
            throw new common_1.BadRequestException('Stripe not configured');
        }
        return this.stripe;
    }
    async createCustomer(email, name) {
        const stripe = this.ensureStripeConfigured();
        return await stripe.customers.create({
            email,
            name,
            metadata: {
                source: 'PayKey Payroll System',
            },
        });
    }
    async createCheckoutSession(userId, planTier, customerEmail, customerName, successUrl, cancelUrl) {
        const stripe = this.ensureStripeConfigured();
        if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(planTier.toUpperCase())) {
            throw new common_1.BadRequestException('Invalid subscription plan');
        }
        try {
            const customers = await stripe.customers.list({
                email: customerEmail,
                limit: 1,
            });
            let customer = customers.data[0];
            if (!customer) {
                customer = await this.createCustomer(customerEmail, customerName);
            }
            const session = await stripe.checkout.sessions.create({
                customer: customer.id,
                mode: 'subscription',
                payment_method_types: ['card'],
                line_items: [
                    {
                        price_data: {
                            currency: 'usd',
                            product_data: {
                                name: `${planTier.toUpperCase()} Plan - PayKey Payroll`,
                                description: `Monthly subscription for ${planTier} plan`,
                            },
                            recurring: {
                                interval: 'month',
                            },
                            unit_amount: this.getPlanPrice(planTier.toUpperCase()),
                        },
                        quantity: 1,
                    },
                ],
                metadata: {
                    userId,
                    planTier: planTier.toUpperCase(),
                    source: 'PayKey',
                },
                success_url: successUrl ||
                    `${this.configService.get('FRONTEND_URL')}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
                cancel_url: cancelUrl ||
                    `${this.configService.get('FRONTEND_URL')}/subscription/cancel`,
                allow_promotion_codes: true,
            });
            return {
                sessionId: session.id,
                url: session.url || '',
            };
        }
        catch (error) {
            this.logger.error('Failed to create checkout session', error);
            throw new common_1.BadRequestException('Failed to create checkout session');
        }
    }
    getPlanPrice(planTier) {
        const prices = {
            FREE: 0,
            BASIC: 2000,
            GOLD: 5000,
            PLATINUM: 10000,
        };
        return prices[planTier] || prices.BASIC;
    }
    async handleWebhook(event) {
        this.ensureStripeConfigured();
        this.logger.log(`Processing Stripe webhook: ${event.type}`);
        try {
            switch (event.type) {
                case 'checkout.session.completed':
                    await this.handleCheckoutCompleted(event.data.object);
                    break;
                case 'invoice.payment_succeeded':
                    await this.handlePaymentSucceeded(event.data.object);
                    break;
                case 'invoice.payment_failed':
                    await this.handlePaymentFailed(event.data.object);
                    break;
                case 'customer.subscription.deleted':
                    await this.handleSubscriptionCancelled(event.data.object);
                    break;
                case 'customer.subscription.updated':
                    await this.handleSubscriptionUpdated(event.data.object);
                    break;
                default:
                    this.logger.log(`Unhandled event type: ${event.type}`);
            }
        }
        catch (error) {
            this.logger.error(`Error handling webhook ${event.type}`, error);
            throw error;
        }
    }
    async handleCheckoutCompleted(session) {
        const metadata = session.metadata || {};
        const userId = metadata.userId;
        const planTier = metadata.planTier;
        if (!userId || !planTier) {
            this.logger.error('Missing metadata in checkout session');
            return;
        }
        let subscription = await this.subscriptionRepository.findOne({
            where: { userId },
        });
        if (!subscription) {
            subscription = this.subscriptionRepository.create({
                userId,
                tier: planTier,
                status: subscription_entity_1.SubscriptionStatus.ACTIVE,
                startDate: new Date(),
                stripeSubscriptionId: session.subscription,
            });
        }
        else {
            subscription.tier = planTier;
            subscription.status = subscription_entity_1.SubscriptionStatus.ACTIVE;
            subscription.startDate = new Date();
            subscription.stripeSubscriptionId = session.subscription;
        }
        await this.subscriptionRepository.save(subscription);
        this.logger.log(`Subscription activated for user ${userId} with plan ${planTier}`);
    }
    async handlePaymentSucceeded(invoice) {
        if (!invoice.subscription)
            return;
        const subscription = await this.subscriptionRepository.findOne({
            where: { stripeSubscriptionId: invoice.subscription },
        });
        if (!subscription) {
            this.logger.error(`Subscription not found for Stripe ID: ${invoice.subscription}`);
            return;
        }
        const payment = this.paymentRepository.create({
            subscriptionId: subscription.id,
            userId: subscription.userId,
            amount: (invoice.amount_paid || 0) / 100,
            currency: invoice.currency.toUpperCase(),
            status: subscription_payment_entity_1.PaymentStatus.COMPLETED,
            paymentMethod: subscription_payment_entity_1.PaymentMethod.STRIPE,
            billingPeriod: 'monthly',
            periodStart: new Date(invoice.period_start * 1000),
            periodEnd: new Date(invoice.period_end * 1000),
            dueDate: new Date((invoice.due_date || Date.now()) * 1000),
            paidDate: new Date(),
            invoiceNumber: invoice.number || `inv_${invoice.id}`,
            paymentProvider: 'stripe',
            transactionId: invoice.payment_intent,
            metadata: {
                stripeInvoiceId: invoice.id,
                stripeSubscriptionId: invoice.subscription,
            },
        });
        await this.paymentRepository.save(payment);
        this.logger.log(`Payment recorded for subscription ${subscription.id}`);
    }
    async handlePaymentFailed(invoice) {
        if (!invoice.subscription)
            return;
        const subscription = await this.subscriptionRepository.findOne({
            where: { stripeSubscriptionId: invoice.subscription },
        });
        if (subscription) {
            const payment = this.paymentRepository.create({
                subscriptionId: subscription.id,
                userId: subscription.userId,
                amount: (invoice.amount_due || 0) / 100,
                currency: invoice.currency.toUpperCase(),
                status: subscription_payment_entity_1.PaymentStatus.FAILED,
                paymentMethod: subscription_payment_entity_1.PaymentMethod.STRIPE,
                billingPeriod: 'monthly',
                periodStart: new Date(invoice.period_start * 1000),
                periodEnd: new Date(invoice.period_end * 1000),
                dueDate: new Date((invoice.due_date || Date.now()) * 1000),
                invoiceNumber: invoice.number || `inv_${invoice.id}`,
                paymentProvider: 'stripe',
                transactionId: invoice.payment_intent,
                metadata: {
                    stripeInvoiceId: invoice.id,
                    error: invoice.last_finalization_error?.message,
                },
            });
            await this.paymentRepository.save(payment);
            if (invoice.attempt_count > 3) {
                subscription.status = subscription_entity_1.SubscriptionStatus.PAST_DUE;
                await this.subscriptionRepository.save(subscription);
            }
        }
    }
    async handleSubscriptionCancelled(stripeSubscription) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { stripeSubscriptionId: stripeSubscription.id },
        });
        if (subscription) {
            subscription.status = subscription_entity_1.SubscriptionStatus.CANCELLED;
            subscription.endDate = new Date();
            await this.subscriptionRepository.save(subscription);
            this.logger.log(`Subscription cancelled for user ${subscription.userId}`);
        }
    }
    async handleSubscriptionUpdated(stripeSubscription) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { stripeSubscriptionId: stripeSubscription.id },
        });
        if (subscription) {
            switch (stripeSubscription.status) {
                case 'active':
                    subscription.status = subscription_entity_1.SubscriptionStatus.ACTIVE;
                    break;
                case 'past_due':
                    subscription.status = subscription_entity_1.SubscriptionStatus.PAST_DUE;
                    break;
                case 'canceled':
                    subscription.status = subscription_entity_1.SubscriptionStatus.CANCELLED;
                    subscription.endDate = new Date();
                    break;
                case 'unpaid':
                    subscription.status = subscription_entity_1.SubscriptionStatus.PAST_DUE;
                    break;
            }
            await this.subscriptionRepository.save(subscription);
        }
    }
    async cancelSubscription(userId) {
        const stripe = this.ensureStripeConfigured();
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: subscription_entity_1.SubscriptionStatus.ACTIVE },
        });
        if (!subscription || !subscription.stripeSubscriptionId) {
            throw new common_1.NotFoundException('Active subscription not found');
        }
        try {
            await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);
            subscription.status = subscription_entity_1.SubscriptionStatus.CANCELLED;
            subscription.endDate = new Date();
            await this.subscriptionRepository.save(subscription);
            this.logger.log(`Subscription cancelled for user ${userId}`);
        }
        catch (error) {
            this.logger.error('Failed to cancel subscription', error);
            throw new common_1.BadRequestException('Failed to cancel subscription');
        }
    }
    async updateSubscription(userId, newPlanTier) {
        const stripe = this.ensureStripeConfigured();
        const subscription = await this.subscriptionRepository.findOne({
            where: { userId, status: subscription_entity_1.SubscriptionStatus.ACTIVE },
        });
        if (!subscription || !subscription.stripeSubscriptionId) {
            throw new common_1.NotFoundException('Active subscription not found');
        }
        if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(newPlanTier.toUpperCase())) {
            throw new common_1.BadRequestException('Invalid subscription plan');
        }
        try {
            await stripe.subscriptions.cancel(subscription.stripeSubscriptionId);
            subscription.tier = newPlanTier;
            subscription.status = subscription_entity_1.SubscriptionStatus.ACTIVE;
            subscription.startDate = new Date();
            await this.subscriptionRepository.save(subscription);
            this.logger.log(`Subscription updated for user ${userId} to ${newPlanTier}`);
        }
        catch (error) {
            this.logger.error('Failed to update subscription', error);
            throw new common_1.BadRequestException('Failed to update subscription');
        }
    }
    async getAccountInfo() {
        if (!this.stripe) {
            return {
                connected: false,
                message: 'Stripe not configured',
            };
        }
        try {
            const account = await this.stripe.accounts.retrieve();
            return {
                connected: true,
                id: account.id,
                charges_enabled: account.charges_enabled,
                payouts_enabled: account.payouts_enabled,
                details_submitted: account.details_submitted,
            };
        }
        catch (error) {
            this.logger.error('Failed to get Stripe account info', error);
            return {
                connected: false,
                message: 'Failed to retrieve account information',
            };
        }
    }
};
exports.StripeService = StripeService;
exports.StripeService = StripeService = StripeService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(2, (0, typeorm_1.InjectRepository)(subscription_payment_entity_1.SubscriptionPayment)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        typeorm_2.Repository,
        typeorm_2.Repository])
], StripeService);
//# sourceMappingURL=stripe.service.js.map