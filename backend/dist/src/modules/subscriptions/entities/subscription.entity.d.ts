import { User } from '../../users/entities/user.entity';
export declare enum SubscriptionStatus {
    ACTIVE = "ACTIVE",
    CANCELLED = "CANCELLED",
    EXPIRED = "EXPIRED",
    PAST_DUE = "PAST_DUE",
    TRIAL = "TRIAL"
}
export declare class Subscription {
    id: string;
    user: User;
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
}
