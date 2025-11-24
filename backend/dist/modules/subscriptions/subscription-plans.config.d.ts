export interface SubscriptionPlan {
    tier: string;
    name: string;
    priceUSD: number;
    priceKES: number;
    workerLimit: number;
    features: string[];
    isPopular?: boolean;
}
export declare const SUBSCRIPTION_PLANS: SubscriptionPlan[];
export declare const TRIAL_PERIOD_DAYS = 14;
export declare function getPlanByTier(tier: string): SubscriptionPlan | undefined;
export declare function canAddWorker(tier: string, currentWorkerCount: number): boolean;
