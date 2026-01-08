/**
 * Feature Access Configuration
 *
 * This file defines what features are available at each subscription tier
 * and whether mock data is available during the trial period.
 */

export type SubscriptionTier = 'FREE' | 'BASIC' | 'GOLD' | 'PLATINUM';

export interface FeatureDefinition {
  key: string;
  name: string;
  description: string;
  /** Tiers that have full access to this feature */
  tiers: SubscriptionTier[];
  /** If true, trial users can see mock data for this feature */
  mockDataAvailable: boolean;
  /** Parent feature key if this is a sub-feature */
  parentFeature?: string;
  /** Sort order for display */
  displayOrder: number;
}

/**
 * Complete feature access matrix for PayKey
 */
export const FEATURE_ACCESS_MATRIX: FeatureDefinition[] = [
  // ============== CORE FEATURES (All Tiers) ==============
  {
    key: 'workers',
    name: 'Worker Management',
    description: 'Add and manage domestic workers',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 1,
  },
  {
    key: 'basic_payroll',
    name: 'Basic Payroll',
    description: 'Run payroll with automatic tax calculations',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 2,
  },
  {
    key: 'tax_calculations',
    name: 'Automatic Tax Calculations',
    description: 'PAYE, NSSF, SHIF calculated automatically',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 3,
  },
  {
    key: 'payslips',
    name: 'Payslips',
    description: 'View and download payslips',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 4,
  },
  {
    key: 'statutory_reports',
    name: 'Statutory Reports (P9, P10)',
    description: 'KRA statutory tax reports and filings (required by law)',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false, // Statutory reports need real data
    displayOrder: 4.5,
  },

  // ============== BASIC TIER FEATURES ==============
  {
    key: 'payroll_processing',
    name: 'Payroll Processing',
    description:
      'Process payroll and M-Pesa disbursements (FREE tier can preview only)',
    tiers: ['BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 5,
  },
  {
    key: 'mpesa_payments',
    name: 'M-Pesa Payments',
    description: 'Pay workers directly via M-Pesa',
    tiers: ['BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false, // Payment can't be mocked
    displayOrder: 10,
  },
  {
    key: 'p9_tax_cards',
    name: 'P9 Tax Cards',
    description: 'Generate P9 tax cards for workers',
    tiers: ['BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 11,
  },
  {
    key: 'basic_reports',
    name: 'Basic Reports',
    description: 'Payroll summaries and basic analytics',
    tiers: ['BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 12,
  },

  // ============== GOLD TIER FEATURES ==============
  {
    key: 'excel_import',
    name: 'Excel Import',
    description: 'Bulk import workers from Excel spreadsheets',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 15,
  },
  {
    key: 'advanced_reports',
    name: 'Advanced Reports',
    description: 'Detailed analytics, trends, and PDF exports',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 22,
  },
  {
    key: 'accounting_integration',
    name: 'Accounting & Export',
    description: 'Export payroll data and configure account mappings',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 23,
  },
  {
    key: 'priority_support',
    name: 'Priority Support',
    description: 'Faster response times from support team',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 24,
  },

  // ============== PLATINUM TIER FEATURES ==============
  {
    key: 'time_tracking',
    name: 'Time Tracking',
    description: 'Clock in/out and attendance tracking',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 20,
  },
  {
    key: 'geofencing',
    name: 'Geofencing',
    description: 'Location-based attendance verification',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
    parentFeature: 'time_tracking',
    displayOrder: 21,
  },
  {
    key: 'property_management',
    name: 'Property Management',
    description: 'Multi-property geofencing and worker assignment',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 25,
  },
  {
    key: 'leave_management',
    name: 'Leave Management',
    description:
      'Track vacation, sick days, and time off with approval workflow',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 30,
  },
  {
    key: 'auto_tax_filing',
    name: 'Automatic Tax Filing',
    description: 'Automatically file taxes with KRA (Coming Soon)',
    tiers: ['PLATINUM'],
    mockDataAvailable: false, // Not implemented yet
    displayOrder: 31,
  },
  {
    key: 'employee_portal',
    name: 'Employee Self-Service Portal',
    description: 'Workers can view payslips, request leave, and clock in/out',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
    displayOrder: 32,
  },
  {
    key: 'dedicated_support',
    name: 'Dedicated Support',
    description: 'Personal account manager and phone support',
    tiers: ['PLATINUM'],
    mockDataAvailable: false,
    displayOrder: 33,
  },
];

/**
 * Tier limits configuration
 */
export const TIER_LIMITS: Record<SubscriptionTier, { workerLimit: number }> = {
  FREE: { workerLimit: 3 },
  BASIC: { workerLimit: 5 },
  GOLD: { workerLimit: 10 },
  PLATINUM: { workerLimit: 20 },
};

/**
 * Get a feature definition by key
 */
export function getFeatureByKey(key: string): FeatureDefinition | undefined {
  return FEATURE_ACCESS_MATRIX.find((f) => f.key === key);
}

/**
 * Check if a tier has access to a feature
 */
export function tierHasFeature(
  tier: SubscriptionTier,
  featureKey: string,
): boolean {
  const feature = getFeatureByKey(featureKey);
  if (!feature) return true; // Unknown features are allowed by default
  return feature.tiers.includes(tier);
}

/**
 * Get all features available for a tier
 */
export function getFeaturesForTier(
  tier: SubscriptionTier,
): FeatureDefinition[] {
  return FEATURE_ACCESS_MATRIX.filter((f) => f.tiers.includes(tier)).sort(
    (a, b) => a.displayOrder - b.displayOrder,
  );
}

/**
 * Get the lowest tier that has access to a feature
 */
export function getLowestTierForFeature(
  featureKey: string,
): SubscriptionTier | null {
  const feature = getFeatureByKey(featureKey);
  if (!feature) return null;

  const tierOrder: SubscriptionTier[] = ['FREE', 'BASIC', 'GOLD', 'PLATINUM'];
  for (const tier of tierOrder) {
    if (feature.tiers.includes(tier)) {
      return tier;
    }
  }
  return null;
}

/**
 * Get features that can show mock data during trial
 */
export function getMockableFeatures(): FeatureDefinition[] {
  return FEATURE_ACCESS_MATRIX.filter((f) => f.mockDataAvailable);
}

/**
 * Get features a user is missing compared to a target tier
 */
export function getUpgradeFeatures(
  currentTier: SubscriptionTier,
  targetTier: SubscriptionTier,
): FeatureDefinition[] {
  const currentFeatures = new Set(
    getFeaturesForTier(currentTier).map((f) => f.key),
  );
  return getFeaturesForTier(targetTier).filter(
    (f) => !currentFeatures.has(f.key),
  );
}
