import { Repository } from 'typeorm';
import { StripeService } from './stripe.service';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../subscriptions/entities/subscription-payment.entity';
export declare class SubscriptionPaymentsController {
    private stripeService;
    private subscriptionRepository;
    private paymentRepository;
    constructor(stripeService: StripeService, subscriptionRepository: Repository<Subscription>, paymentRepository: Repository<SubscriptionPayment>);
    getPlans(): {
        id: string;
        tier: string;
        name: string;
        description: string;
        price_usd: number;
        price_kes: number;
        currency: string;
        active: boolean;
        features: Record<string, boolean>;
        sort_order: number;
        worker_limit: number;
        billing_period: string;
        created_at: string;
        updated_at: string;
    }[];
    private convertFeaturesToMap;
    getCurrentSubscription(req: any): Promise<{
        id: null;
        tier: string;
        planName: string;
        price: number;
        currency: string;
        features: string[];
        isActive: boolean;
        startDate: null;
        endDate: null;
        user: {
            id: any;
        } | null;
    } | {
        planName: string;
        id: string;
        user: import("../users/entities/user.entity").User;
        userId: string;
        tier: import("../subscriptions/entities/subscription.entity").SubscriptionTier;
        status: import("../subscriptions/entities/subscription.entity").SubscriptionStatus;
        amount: number;
        currency: string;
        startDate: Date;
        endDate: Date;
        nextBillingDate: Date;
        stripeSubscriptionId: string;
        stripePriceId: string;
        notes: string;
        createdAt: Date;
        updatedAt: Date;
        price?: undefined;
        features?: undefined;
        isActive?: undefined;
    }>;
    createCheckoutSession(req: any, body: {
        planId: string;
    }): Promise<{
        sessionId: string;
        checkoutUrl: string;
    }>;
    cancelSubscription(req: any, subscriptionId: string): Promise<{
        message: string;
    }>;
    getPaymentHistory(req: any): Promise<SubscriptionPayment[]>;
    getUsage(req: any): Promise<{
        currentPlan: string;
        workerUsage: number;
        workerLimit: number;
        usagePercentage: number;
    }>;
    getStripeStatus(): Promise<any>;
    handleWebhook(body: any): Promise<{
        received: boolean;
        error?: undefined;
    } | {
        error: any;
        received?: undefined;
    }>;
}
