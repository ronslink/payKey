export interface SubscriptionPlan {
  tier: string;
  name: string;
  priceUSD: number;
  priceKES: number;
  workerLimit: number;
  features: string[];
  isPopular?: boolean;
}

export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
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

export const TRIAL_PERIOD_DAYS = 14;

export function getPlanByTier(tier: string): SubscriptionPlan | undefined {
  return SUBSCRIPTION_PLANS.find((plan) => plan.tier === tier);
}

export function canAddWorker(
  tier: string,
  currentWorkerCount: number,
): boolean {
  const plan = getPlanByTier(tier);
  if (!plan) return false;
  return currentWorkerCount < plan.workerLimit;
}
