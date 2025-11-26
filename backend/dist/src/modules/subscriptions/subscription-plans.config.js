"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TRIAL_PERIOD_DAYS = exports.SUBSCRIPTION_PLANS = void 0;
exports.getPlanByTier = getPlanByTier;
exports.canAddWorker = canAddWorker;
exports.SUBSCRIPTION_PLANS = [
    {
        tier: 'FREE',
        name: 'Free',
        priceUSD: 0,
        priceKES: 0,
        workerLimit: 1,
        features: ['Up to 1 worker', 'Automatic tax calculations'],
    },
    {
        tier: 'BASIC',
        name: 'Basic',
        priceUSD: 9.99,
        priceKES: 1200,
        workerLimit: 5,
        features: [
            'Up to 5 workers',
            'Automatic tax calculations',
            'M-Pesa payments',
            'Leave tracking',
        ],
        isPopular: true,
    },
    {
        tier: 'GOLD',
        name: 'Gold',
        priceUSD: 29.99,
        priceKES: 3600,
        workerLimit: 10,
        features: [
            'Up to 10 workers',
            'Automatic tax calculations',
            'M-Pesa payments',
            'Leave tracking',
            'Advanced reporting',
            'Priority support',
        ],
    },
    {
        tier: 'PLATINUM',
        name: 'Platinum',
        priceUSD: 49.99,
        priceKES: 6000,
        workerLimit: 15,
        features: [
            'Up to 15 workers',
            'Automatic tax calculations',
            'M-Pesa payments',
            'Leave tracking',
            'Time tracking (clock in/out)',
            'Geofencing',
            'Automatic tax payments to KRA',
            'Finance software integration',
            'Multi-property management',
        ],
    },
];
exports.TRIAL_PERIOD_DAYS = 14;
function getPlanByTier(tier) {
    return exports.SUBSCRIPTION_PLANS.find((plan) => plan.tier === tier);
}
function canAddWorker(tier, currentWorkerCount) {
    const plan = getPlanByTier(tier);
    if (!plan)
        return false;
    return currentWorkerCount < plan.workerLimit;
}
//# sourceMappingURL=subscription-plans.config.js.map