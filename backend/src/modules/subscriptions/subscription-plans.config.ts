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
    workerLimit: 3,
    features: ['Up to 3 workers', 'Automatic tax calculations'],
  },
  {
    tier: 'BASIC',
    name: 'Basic',
    priceUSD: 9.99,
    priceKES: 1300,
    workerLimit: 5,
    features: [
      'Up to 5 workers',
      'Automatic tax calculations',
      'M-Pesa payments',
      'P9 Tax Cards',
    ],
    isPopular: true,
  },
  {
    tier: 'GOLD',
    name: 'Gold',
    priceUSD: 29.99,
    priceKES: 3900,
    workerLimit: 10,
    features: [
      'Up to 10 workers',
      'Automatic tax calculations',
      'M-Pesa payments',
      'P9 Tax Cards',
      'Advanced reporting',
      'Accounting exports',
      'Priority support',
    ],
  },
  {
    tier: 'PLATINUM',
    name: 'Platinum',
    priceUSD: 49.99,
    priceKES: 6500,
    workerLimit: 20,
    features: [
      'Up to 20 workers',
      'Automatic tax calculations',
      'M-Pesa payments',
      'Leave tracking',
      'Time tracking (clock in/out)',
      'Geofencing',
      'Advanced reporting',
      'Accounting exports',
      'Priority support',
      'Automatic tax payments to KRA',
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
