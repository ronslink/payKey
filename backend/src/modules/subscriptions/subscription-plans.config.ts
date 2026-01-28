export interface SubscriptionPlan {
  tier: string;
  name: string;
  priceUSD: number;
  priceKES: number;
  priceUSDYearly: number;
  priceKESYearly: number;
  workerLimit: number;
  features: string[];
  importAccess: boolean;
  isPopular?: boolean;
}

export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
  {
    tier: 'FREE',
    name: 'Free',
    priceUSD: 0,
    priceKES: 0,
    priceUSDYearly: 0,
    priceKESYearly: 0,
    workerLimit: 3,
    features: ['Up to 3 workers', 'Automatic tax calculations'],
    importAccess: false,
  },
  {
    tier: 'BASIC',
    name: 'Basic',
    priceUSD: 9.99,
    priceKES: 1300,
    priceUSDYearly: 99.99,
    priceKESYearly: 13000,
    workerLimit: 5,
    features: [
      'Up to 5 workers',
      'Automatic tax calculations',
      'M-Pesa payments',
      'P9 Tax Cards',
    ],
    importAccess: false,
    isPopular: true,
  },
  {
    tier: 'GOLD',
    name: 'Gold',
    priceUSD: 29.99,
    priceKES: 3900,
    priceUSDYearly: 299.99,
    priceKESYearly: 39000,
    workerLimit: 10,
    features: [
      'Up to 10 workers',
      'Automatic tax calculations',
      'M-Pesa payments',
      'P9 Tax Cards',
      'Advanced reporting',
      'Accounting exports',
      'Priority support',
      'Excel worker import',
    ],
    importAccess: true,
  },
  {
    tier: 'PLATINUM',
    name: 'Platinum',
    priceUSD: 49.99,
    priceKES: 6500,
    priceUSDYearly: 499.99,
    priceKESYearly: 65000,
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
      'Excel worker import',
    ],
    importAccess: true,
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

export function canImport(tier: string): boolean {
  const plan = getPlanByTier(tier);
  if (!plan) return false;
  return plan.importAccess;
}
