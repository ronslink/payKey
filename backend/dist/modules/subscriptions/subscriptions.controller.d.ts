import { Repository } from 'typeorm';
import { Subscription, SubscriptionStatus } from './entities/subscription.entity';
export declare class SubscriptionsController {
    private subscriptionRepository;
    constructor(subscriptionRepository: Repository<Subscription>);
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
        tier: string;
        status: SubscriptionStatus;
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
    subscribe(req: any, body: {
        planId: string;
    }): Promise<Subscription>;
}
