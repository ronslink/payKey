const API_URL = (import.meta.env.VITE_API_URL || 'https://api.paydome.co').replace(/\/$/, '');
const SESSION_KEY = 'paydome.account.v1';
export const CHECKOUT_KEY = 'paydome.checkout.v1';

export interface AccountSession { token: string; email: string }
export interface SubscriptionPlan { id: string; tier: string; name: string; price_usd: number; worker_limit: number; active: boolean }
export interface Subscription {
  id: string | null; tier: string; planName: string; status?: string;
  endDate?: string | null; autoRenew?: boolean; autoRenewalDescription?: string;
  provider?: 'STRIPE' | 'INTASEND' | null;
  renewalMode?: 'automatic' | 'manual' | null;
  billingPeriod?: BillingPeriod;
  pendingPayment?: PendingSubscriptionPayment | null;
}
export type BillingPeriod = 'monthly' | 'yearly';
export interface PendingSubscriptionPayment {
  id: string; status: string; amount: number; currency: string;
  planId?: string; billingPeriod: BillingPeriod; paymentMethod: string;
}
export interface MpesaQuote {
  planId: string; billingPeriod: BillingPeriod; amount: number; currency: 'KES';
  periodStart: string; periodEnd: string; renewalMode: 'manual';
}
export interface MpesaSubscriptionStatus {
  paymentId: string; status: 'PENDING' | 'COMPLETED' | 'FAILED';
  entitlementActive: boolean; amount: number; currency: string; paidDate?: string;
}
export interface CheckoutStatus {
  paymentStatus: 'pending' | 'paid' | 'failed'; entitlementActive: boolean;
  tier?: string; billingPeriod?: string;
}
export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) { super(message); this.status = status; }
}

export function readSession(): AccountSession | null {
  try {
    const value = JSON.parse(sessionStorage.getItem(SESSION_KEY) || 'null');
    return value && typeof value.token === 'string' && typeof value.email === 'string' ? value : null;
  } catch { return null; }
}

export function clearSession() {
  sessionStorage.removeItem(SESSION_KEY);
  sessionStorage.removeItem(CHECKOUT_KEY);
}

export function selectedPlan(value: string | null): string {
  return ['free', 'basic', 'gold', 'platinum'].includes(value || '') ? value! : 'free';
}

export function accountReturnPath(value: string | null): string | null {
  if (!value || !value.startsWith('/') || value.startsWith('//')) return null;
  const url = new URL(value, window.location.origin);
  return url.origin === window.location.origin &&
    ['/checkout', '/subscription/success', '/payments/subscriptions/success'].includes(url.pathname)
    ? `${url.pathname}${url.search}` : null;
}

export function hostedCheckoutUrl(value: string): string {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.hostname !== 'checkout.stripe.com' || url.username || url.password || url.port) {
    throw new Error('The payment provider returned an unexpected checkout address. Please contact support.');
  }
  return url.href;
}

export function validPaymentId(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

export function isMpesaPaymentMethod(value: string | undefined): boolean {
  return value?.toLowerCase() === 'mpesa';
}

export function mpesaPaymentPath(paymentId: string): string {
  if (!validPaymentId(paymentId)) throw new Error('The server returned an invalid payment reference. Please check your account.');
  return `/subscription/success?payment_id=${encodeURIComponent(paymentId)}`;
}

export function normalizeMpesaPhone(value: string): string {
  const phone = value.replace(/[\s()-]/g, '').replace(/^\+/, '').replace(/^0/, '254');
  if (!/^254[17]\d{8}$/.test(phone)) throw new Error('Enter a Kenyan M-Pesa number, such as 0712 345 678.');
  return phone;
}

export async function quoteMpesaSubscription(planId: string, billingPeriod: BillingPeriod, signal?: AbortSignal): Promise<MpesaQuote> {
  const quote = await apiRequest<MpesaQuote>('/subscriptions/mpesa-quote', {
    method: 'POST', body: { planId, billingPeriod }, signal,
  });
  if (quote.planId?.toLowerCase() !== planId.toLowerCase() || quote.billingPeriod !== billingPeriod ||
    quote.currency !== 'KES' || quote.renewalMode !== 'manual' || !Number.isFinite(quote.amount) || quote.amount <= 0 ||
    Math.abs(quote.amount * 100 - Math.round(quote.amount * 100)) > 0.000001 ||
    !Number.isFinite(Date.parse(quote.periodStart)) || !Number.isFinite(Date.parse(quote.periodEnd)) ||
    Date.parse(quote.periodEnd) <= Date.parse(quote.periodStart)) {
    throw new Error('The server did not return a valid M-Pesa price. Please try again.');
  }
  return quote;
}

export async function startMpesaSubscription(quote: MpesaQuote, phoneNumber: string): Promise<{ paymentId: string }> {
  const result = await apiRequest<{ paymentId: string }>('/subscriptions/mpesa-subscribe', {
    method: 'POST', body: {
      planId: quote.planId, billingPeriod: quote.billingPeriod,
      phoneNumber: normalizeMpesaPhone(phoneNumber), expectedAmount: quote.amount,
    },
  });
  if (!validPaymentId(result.paymentId)) throw new Error('Check your account before retrying: the payment request returned no valid reference.');
  return result;
}

export async function readMpesaSubscriptionPayment(paymentId: string, signal?: AbortSignal): Promise<CheckoutStatus> {
  if (!validPaymentId(paymentId)) throw new Error('Invalid payment reference.');
  const result = await apiRequest<MpesaSubscriptionStatus>(`/subscriptions/mpesa-payment-status/${encodeURIComponent(paymentId)}`, { signal });
  if (result.paymentId !== paymentId || !['PENDING', 'COMPLETED', 'FAILED'].includes(result.status)) {
    throw new Error('The server returned an unexpected payment status. Please check your account.');
  }
  return {
    paymentStatus: result.status === 'COMPLETED' ? 'paid' : result.status === 'FAILED' ? 'failed' : 'pending',
    entitlementActive: result.status === 'COMPLETED' && result.entitlementActive === true,
  };
}

export async function apiRequest<T>(path: string, options: {
  method?: 'GET' | 'POST'; body?: unknown; authenticated?: boolean; signal?: AbortSignal;
} = {}): Promise<T> {
  const session = readSession();
  if (options.authenticated !== false && !session) throw new ApiError('Please sign in to continue.', 401);
  const response = await fetch(`${API_URL}${path}`, {
    method: options.method || 'GET',
    headers: {
      Accept: 'application/json',
      ...(options.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(options.authenticated !== false && session ? { Authorization: `Bearer ${session.token}` } : {}),
    },
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    signal: options.signal
      ? AbortSignal.any([options.signal, AbortSignal.timeout(30000)])
      : AbortSignal.timeout(30000),
    cache: 'no-store', credentials: 'omit',
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 401 && options.authenticated !== false) clearSession();
    const message = typeof data?.message === 'string' ? data.message :
      Array.isArray(data?.message) ? data.message.join('. ') : 'The request could not be completed. Please try again.';
    throw new ApiError(message, response.status);
  }
  if (data === null) throw new Error('The server returned an unexpected response. Please try again.');
  return data as T;
}

export async function authenticate(mode: 'login' | 'register', details: {
  email: string; password: string; firstName?: string; lastName?: string;
}): Promise<AccountSession> {
  const data = await apiRequest<{ access_token: string }>(`/auth/${mode}`, {
    method: 'POST', authenticated: false, body: details,
  });
  if (!data.access_token) throw new Error('Sign-in did not return a session. Please try again.');
  const session = { token: data.access_token, email: details.email };
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}
