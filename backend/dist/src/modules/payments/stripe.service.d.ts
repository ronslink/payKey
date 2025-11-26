import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { Repository } from 'typeorm';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
export declare class StripeService {
    private configService;
    private subscriptionRepository;
    private paymentRepository;
    private readonly logger;
    private stripe;
    constructor(configService: ConfigService, subscriptionRepository: Repository<Subscription>, paymentRepository: Repository<SubscriptionPayment>);
    private ensureStripeConfigured;
    createCustomer(email: string, name?: string): Promise<Stripe.Customer>;
    createCheckoutSession(userId: string, planTier: string, customerEmail: string, customerName?: string, successUrl?: string, cancelUrl?: string): Promise<{
        sessionId: string;
        url: string;
    }>;
    private getPlanPrice;
    handleWebhook(event: Stripe.Event): Promise<void>;
    private handleCheckoutCompleted;
    private handlePaymentSucceeded;
    private handlePaymentFailed;
    private handleSubscriptionCancelled;
    private handleSubscriptionUpdated;
    cancelSubscription(userId: string): Promise<void>;
    updateSubscription(userId: string, newPlanTier: string): Promise<void>;
    getAccountInfo(): Promise<any>;
}
