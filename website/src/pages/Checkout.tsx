import { useEffect, useState } from 'react';
import { Link, Navigate, useSearchParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { apiRequest, ApiError, CHECKOUT_KEY, hostedCheckoutUrl, readSession, selectedPlan } from '@/lib/billing-api';
import type { Subscription, SubscriptionPlan } from '@/lib/billing-api';

export default function Checkout() {
  const [params] = useSearchParams();
  const planId = selectedPlan(params.get('plan'));
  const [plan, setPlan] = useState<SubscriptionPlan | null>(null);
  const [current, setCurrent] = useState<Subscription | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [expired, setExpired] = useState(false);
  const [reload, setReload] = useState(0);
  const signedIn = Boolean(readSession());
  const returnPath = `/checkout?plan=${planId}`;

  useEffect(() => {
    if (!signedIn || planId === 'free') return;
    const controller = new AbortController();
    Promise.all([
      apiRequest<SubscriptionPlan[]>('/subscriptions/plans', { signal: controller.signal }),
      apiRequest<Subscription>('/subscriptions/current', { signal: controller.signal }),
    ]).then(([plans, subscription]) => {
      const found = plans.find(p => p.id === planId && p.active && Number(p.price_usd) > 0);
      if (!found) throw new Error('This plan is not currently available. Please choose another plan.');
      setPlan(found); setCurrent(subscription);
    }).catch(err => {
      if (!controller.signal.aborted) {
        if (err instanceof ApiError && err.status === 401) setExpired(true);
        setError(err instanceof Error ? err.message : 'Could not load checkout.');
      }
    });
    return () => controller.abort();
  }, [planId, signedIn, reload]);

  if (!signedIn || expired) return <Navigate replace to={`/account?mode=login&plan=${planId}&next=${encodeURIComponent(returnPath)}`} />;
  if (planId === 'free') return <Navigate replace to="/account" />;

  async function checkout() {
    setBusy(true); setError('');
    try {
      const result = await apiRequest<{ checkoutUrl: string; sessionId: string }>('/subscriptions/subscribe', {
        method: 'POST', body: { planId, paymentMethod: 'STRIPE', billingPeriod: 'monthly' },
      });
      const url = hostedCheckoutUrl(result.checkoutUrl);
      if (!/^cs_[A-Za-z0-9_]+$/.test(result.sessionId)) throw new Error('The payment provider returned an invalid session. Please contact support.');
      sessionStorage.setItem(CHECKOUT_KEY, result.sessionId);
      window.location.assign(url);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) setExpired(true);
      setError(err instanceof Error ? err.message : 'Could not start checkout. Please try again.');
      setBusy(false);
    }
  }

  const hasPaidPlan = Boolean(current?.id && current.tier !== 'FREE');
  return <section className="max-w-xl mx-auto px-4 py-16 sm:py-24">
    <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-6 sm:p-10">
      <h1 className="text-3xl font-bold text-white mb-6">Review your subscription</h1>
      {error ? <p role="alert" className="text-rose-300 mb-4">{error} <button onClick={() => { setError(''); setReload(n => n + 1); }} className="underline">Retry</button></p> : null}
      {plan && current ? <>
        <h2 className="text-xl font-semibold text-white">{plan.name}</h2>
        <p className="text-3xl font-bold text-white my-4">{new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(plan.price_usd))}<span className="text-base font-normal text-slate-400"> USD / month</span></p>
        <p className="text-slate-300">Up to {plan.worker_limit} workers.</p>
        <p className="text-slate-400 mt-4">Card subscriptions are billed in US dollars each month and renew automatically. Review the final amount on Stripe before paying. You can turn off renewal in your Paydome account.</p>
        <p className="text-slate-400 mt-4">Payroll and worker management are in the mobile app. <Link to="/get-started" className="text-emerald-400 underline">Check app access</Link> before subscribing.</p>
        {hasPaidPlan ? <div className="mt-6 text-slate-300">You already have a paid subscription. <Link to="/account" className="text-emerald-400 underline">Manage your current plan</Link> or contact support to change plans.</div> : <Button disabled={busy} onClick={checkout} className="w-full mt-8 bg-emerald-500 hover:bg-emerald-600 text-white">{busy ? 'Opening secure checkout…' : 'Continue to Stripe checkout'}</Button>}
      </> : !error ? <p role="status" className="text-slate-400">Loading the current plan and price…</p> : null}
      <Link to="/pricing" className="block mt-6 text-sm text-emerald-400 underline">Back to plans</Link>
    </div>
  </section>;
}
