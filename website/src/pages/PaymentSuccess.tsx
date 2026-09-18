import { useEffect, useState } from 'react';
import { Link, useLocation, useSearchParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { apiRequest, ApiError, CHECKOUT_KEY, readSession } from '@/lib/billing-api';
import type { CheckoutStatus } from '@/lib/billing-api';

export default function PaymentSuccess() {
  const [params] = useSearchParams();
  const location = useLocation();
  const cancelled = location.pathname.endsWith('/cancel');
  const sessionId = params.get('session_id') || sessionStorage.getItem(CHECKOUT_KEY) || '';
  const validSession = /^cs_[A-Za-z0-9_]+$/.test(sessionId);
  const [resultForSession, setResultForSession] = useState<{ sessionId: string; result: CheckoutStatus } | null>(null);
  const status = resultForSession?.sessionId === sessionId ? resultForSession.result : null;
  const [error, setError] = useState('');
  const [checking, setChecking] = useState(false);
  const [expired, setExpired] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const signedIn = Boolean(readSession()) && !expired;

  useEffect(() => {
    if (!validSession || !signedIn || cancelled) return;
    const controller = new AbortController();
    let timer: ReturnType<typeof setTimeout> | undefined;
    let polls = 0;
    async function check() {
      setChecking(true);
      try {
        const result = await apiRequest<CheckoutStatus>(`/payments/subscriptions/checkout-status/${encodeURIComponent(sessionId)}`, { signal: controller.signal });
        if (controller.signal.aborted) return;
        setResultForSession({ sessionId, result });
        if (!(result.paymentStatus === 'paid' && result.entitlementActive) && result.paymentStatus !== 'failed' && ++polls < 10) {
          timer = setTimeout(check, 3000);
        } else setChecking(false);
      } catch (err) {
        if (controller.signal.aborted) return;
        if (err instanceof ApiError && err.status === 401) setExpired(true);
        setError(err instanceof Error ? err.message : 'Could not check payment status.');
        setChecking(false);
      }
    }
    void check();
    return () => { controller.abort(); if (timer) clearTimeout(timer); };
  }, [validSession, signedIn, cancelled, sessionId, attempt]);

  const active = status?.paymentStatus === 'paid' && status.entitlementActive === true;
  const returnPath = `/payments/subscriptions/success?session_id=${encodeURIComponent(sessionId)}`;
  const heading = cancelled ? 'Checkout closed' : active ? 'Your subscription is active' : status?.paymentStatus === 'failed' ? 'Payment not completed' : 'Checking your payment';
  return <section className="max-w-xl mx-auto px-4 py-16 sm:py-24">
    <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 sm:p-10 text-center">
      <h1 className="text-3xl font-bold text-white mb-5">{heading}</h1>
      <div aria-live="polite" className="text-slate-400 space-y-4">
        {cancelled ? <p>You left checkout. Your subscription will change only after the payment provider confirms a successful payment.</p>
          : !validSession ? <p>No valid checkout reference was provided. View your account to check your subscription or contact support.</p>
          : !signedIn ? <p>Sign in to the account used for checkout to securely check your payment and subscription.</p>
          : active ? <p>Your {status?.tier || ''} plan has been confirmed by the server. Sign in to the app with the same account to use it.</p>
          : status?.paymentStatus === 'failed' ? <p>The payment was not completed. You can review your account before trying again.</p>
          : status?.paymentStatus === 'paid' ? <p>Your payment was received. We are waiting for your subscription activation to finish.</p>
          : <p>{checking ? 'Waiting for payment confirmation from the provider…' : 'Your payment has not yet been confirmed. Check again shortly or contact support before starting another payment.'}</p>}
        {error ? <p role="alert" className="text-rose-300">{error}</p> : null}
      </div>
      <div className="flex flex-col gap-3 mt-8">
        {!signedIn && validSession && !cancelled ? <Button asChild className="bg-emerald-500 text-white"><Link to={`/account?mode=login&next=${encodeURIComponent(returnPath)}`}>Sign in to check payment</Link></Button> : null}
        {signedIn && validSession && !cancelled && !active ? <Button disabled={checking} onClick={() => { setError(''); setAttempt(n => n + 1); }} className="bg-emerald-500 text-white">{checking ? 'Checking…' : 'Check again'}</Button> : null}
        <Button asChild variant="outline" className="bg-white/5 border-white/20 text-white"><Link to="/account">View account</Link></Button>
        <Link to="/contact" className="text-sm text-emerald-400 underline">Contact support</Link>
      </div>
    </div>
  </section>;
}
