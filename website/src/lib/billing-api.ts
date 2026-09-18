const API_URL = (import.meta.env.VITE_API_URL || 'https://api.paydome.co').replace(/\/$/, '');
const SESSION_KEY = 'paydome.account.v1';
export const CHECKOUT_KEY = 'paydome.checkout.v1';

export interface AccountSession { token: string; email: string }
export interface SubscriptionPlan { id: string; tier: string; name: string; price_usd: number; worker_limit: number; active: boolean }
export interface Subscription {
  id: string | null; tier: string; planName: string; status?: string;
  endDate?: string | null; autoRenew?: boolean; autoRenewalDescription?: string;
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
