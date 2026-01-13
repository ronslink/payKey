/**
 * Type definitions for E2E test API responses
 *
 * These interfaces provide type safety for API responses in tests,
 * eliminating the need for `any` types and eslint-disable comments.
 */

// =============================================================================
// Auth Types
// =============================================================================

export interface UserResponse {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  businessName?: string;
  phone?: string;
  tier?: 'FREE' | 'SILVER' | 'GOLD' | 'PLATINUM';
  createdAt?: string;
  updatedAt?: string;
}

export interface LoginResponse {
  access_token: string;
  user: UserResponse;
}

export interface RegisterResponse extends LoginResponse {}

// =============================================================================
// Worker Types
// =============================================================================

export interface WorkerResponse {
  id: string;
  name: string;
  phoneNumber: string;
  email?: string;
  salaryGross: number;
  startDate: string;
  jobTitle?: string;
  isActive: boolean;
  terminationId?: string;
  paymentMethod?: 'MPESA' | 'BANK' | 'CASH';
  mpesaNumber?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface WorkerStatsResponse {
  totalWorkers: number;
  activeWorkers?: number;
  terminatedWorkers?: number;
}

// =============================================================================
// Worker Termination Types
// =============================================================================

export type TerminationReason =
  | 'RESIGNATION'
  | 'LAYOFF'
  | 'DISMISSAL'
  | 'CONTRACT_END'
  | 'RETIREMENT'
  | 'OTHER';

export interface TerminationHistoryResponse {
  id: string;
  workerId: string;
  reason: TerminationReason;
  terminationDate: string;
  noticePeriodDays?: number;
  notes?: string;
  createdAt?: string;
}

export interface FinalPaymentCalculation {
  proratedSalary: number;
  taxDeductions: {
    paye: number;
    shif: number;
    nssf: number;
    housingLevy: number;
  };
  netPay: number;
}

// =============================================================================
// Payroll Types
// =============================================================================

export type PayrollStatus = 'draft' | 'pending' | 'finalized' | 'paid';

export interface PayrollRecordResponse {
  id: string;
  workerId: string;
  payPeriodId: string;
  grossSalary: string | number;
  netSalary: string | number;
  status: PayrollStatus;
  createdAt?: string;
}

export interface PayPeriodResponse {
  id: string;
  startDate: string;
  endDate: string;
  frequency: 'WEEKLY' | 'BIWEEKLY' | 'MONTHLY';
  status?: string;
}

// =============================================================================
// Tax Types
// =============================================================================

export interface TaxSubmissionResponse {
  id: string;
  payPeriodId: string;
  payPeriod: PayPeriodResponse;
  totalPaye: string | number;
  totalShif: string | number;
  totalNssf: string | number;
  totalHousingLevy: string | number;
  status?: string;
  createdAt?: string;
}

// =============================================================================
// Generic API Response Types
// =============================================================================

export interface ApiErrorResponse {
  statusCode: number;
  message: string | string[];
  error?: string;
}

/**
 * Type guard to check if response body is an API error
 */
export function isApiError(body: unknown): body is ApiErrorResponse {
  return (
    typeof body === 'object' &&
    body !== null &&
    'statusCode' in body &&
    'message' in body
  );
}

/**
 * Type assertion helper for array responses
 */
export function asArray<T>(body: unknown): T[] {
  if (!Array.isArray(body)) {
    throw new Error(`Expected array response, got ${typeof body}`);
  }
  return body as T[];
}

// =============================================================================
// Accounting Types
// =============================================================================

export interface AccountMapping {
  category: string;
  accountCode: string;
  accountName: string;
}

export interface AccountMappingsResponse {
  mappings: AccountMapping[];
}

export interface AccountMappingDefaultsResponse {
  defaults: AccountMapping[];
}

export interface ExportFormat {
  id: string;
  name: string;
}

export interface FormatsResponse {
  formats: ExportFormat[];
}

export interface ExportHistoryResponse {
  history: Array<{
    id: string;
    format: string;
    createdAt: string;
  }>;
}

// =============================================================================
// Subscription Types
// =============================================================================

export type SubscriptionTier = 'FREE' | 'SILVER' | 'GOLD' | 'PLATINUM';

export interface SubscriptionPlan {
  tier: SubscriptionTier;
  name: string;
  price_usd: number;
  price_kes: number;
  workerLimit: number;
  features: string[];
}

export interface CurrentSubscriptionResponse {
  tier: SubscriptionTier;
  startDate?: string;
  endDate?: string;
  status?: string;
}

export interface UsageResponse {
  currentPlan: SubscriptionTier;
  workerUsage: number;
  workerLimit: number;
  usagePercentage: number;
}

// =============================================================================
// Payroll Calculation Types
// =============================================================================

export interface TaxBreakdown {
  nssf: number;
  nhif: number;
  shif?: number;
  housingLevy: number;
  paye: number;
  totalDeductions: number;
}

export interface PayrollItem {
  workerId: string;
  grossSalary: number;
  netPay: number;
  taxBreakdown: TaxBreakdown;
  daysWorked?: number;
  totalDaysInPeriod?: number;
}

export interface PayrollCalculationResponse {
  payrollItems: PayrollItem[];
}

export interface DraftPayrollItem {
  workerId: string;
  grossSalary: number;
  daysWorked?: number;
  totalDaysInPeriod?: number;
}

export interface SavedPayrollRecord {
  id: string;
  workerId: string;
  grossSalary: number | string;
  netSalary: number | string;
  status: 'draft' | 'pending' | 'finalized' | 'paid';
}

export interface FinalizeResponse {
  status: 'PROCESSING' | 'COMPLETED' | 'FAILED';
  jobId?: string;
  payPeriodId: string;
  message?: string;
}
