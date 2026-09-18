import { useEffect, useRef, useState } from 'react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { apiRequest, ApiError, CHECKOUT_KEY, hostedCheckoutUrl, isMpesaPaymentMethod, mpesaPaymentPath, normalizeMpesaPhone, quoteMpesaSubscription, readSession, selectedPlan, startMpesaSubscription, validPaymentId } from '@/lib/billing-api';
import type { BillingPeriod, MpesaQuote, Subscription, SubscriptionPlan } from '@/lib/billing-api';

const money = (amount: number, currency: string) => new Intl.NumberFormat('en-KE', { style: 'currency', currency }).format(amount);
const inputClass = 'w-full rounded-lg border border-white/15 bg-slate-900 px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500';

export default function Checkout() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const planId = selectedPlan(params.get('plan'));
  const [loaded, setLoaded] = useState<{ planId: string; plan: SubscriptionPlan; current: Subscription } | null>(null);
  const [method, setMethod] = useState<'STRIPE' | 'MPESA'>(params.get('method') === 'stripe' ? 'STRIPE' : 'MPESA');
  const [period, setPeriod] = useState<BillingPeriod>(params.get('period') === 'yearly' ? 'yearly' : 'monthly');
  const [quoteResult, setQuoteResult] = useState<{ key: string; quote: MpesaQuote } | null>(null);
  const [phone, setPhone] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [unknownRequest, setUnknownRequest] = useState(false);
  const [expired, setExpired] = useState(false);
  const [reload, setReload] = useState(0);
  const [quoteAttempt, setQuoteAttempt] = useState(0);
  const submitting = useRef(false);
  const signedIn = Boolean(readSession());
  const data = loaded?.planId === planId ? loaded : null;
  const current = data?.current;
  const pending = current?.pendingPayment;
  const hasPaidPlan = Boolean(current?.id && current.tier !== 'FREE');
  const manualRenewal = Boolean(hasPaidPlan && current?.provider === 'INTASEND' && current.renewalMode === 'manual' && current.tier.toLowerCase() === planId && method === 'MPESA');
  const canPurchase = Boolean(data && !pending && (!hasPaidPlan || manualRenewal));
  const quoteKey = `${planId}:${period}:${current?.endDate || ''}:${quoteAttempt}`;
  const quote = quoteResult?.key === quoteKey ? quoteResult.quote : null;
  const returnPath = `/checkout?plan=${planId}&method=${method.toLowerCase()}&period=${period}`;

  useEffect(() => {
    if (!signedIn || planId === 'free') return;
    const controller = new AbortController();
    Promise.all([
      apiRequest<SubscriptionPlan[]>('/subscriptions/plans', { signal: controller.signal }),
      apiRequest<Subscription>('/subscriptions/current', { signal: controller.signal }),
    ]).then(([plans, subscription]) => {
      if (controller.signal.aborted) return;
      const found = plans.find(p => p.id === planId && p.active && Number(p.price_usd) > 0);
      if (!found) throw new Error('This plan is not currently available. Please choose another plan.');
      setLoaded({ planId, plan: found, current: subscription });
    }).catch(err => {
      if (!controller.signal.aborted) {
        if (err instanceof ApiError && err.status === 401) setExpired(true);
        setError(err instanceof Error ? err.message : 'Could not load checkout.');
      }
    });
    return () => controller.abort();
  }, [planId, signedIn, reload]);

  useEffect(() => {
    if (!signedIn || method !== 'MPESA' || !canPurchase) return;
    const controller = new AbortController();
    quoteMpesaSubscription(planId, period, controller.signal).then(result => {
      if (!controller.signal.aborted) setQuoteResult({ key: quoteKey, quote: result });
    }).catch(err => {
      if (!controller.signal.aborted) {
        if (err instanceof ApiError && err.status === 401) setExpired(true);
        setError(err instanceof Error ? err.message : 'Could not quote this payment.');
      }
    });
    return () => controller.abort();
  }, [signedIn, method, canPurchase, planId, period, quoteKey]);

  if (!signedIn || expired) return <Navigate replace to={`/account?mode=login&plan=${planId}&next=${encodeURIComponent(returnPath)}`} />;
  if (planId === 'free') return <Navigate replace to="/account" />;

  async function checkExistingPayment() {
    if (submitting.current) return;
    submitting.current = true; setBusy(true); setError('');
    try {
      const subscription = await apiRequest<Subscription>('/subscriptions/current');
      if (data) setLoaded({ ...data, current: subscription });
      if (subscription.pendingPayment && isMpesaPaymentMethod(subscription.pendingPayment.paymentMethod)) navigate(mpesaPaymentPath(subscription.pendingPayment.id));
      else setError('No pending M-Pesa request is visible yet. Check again shortly or contact support before sending another payment.');
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) setExpired(true);
      setError(err instanceof Error ? err.message : 'Could not check your payment.');
    } finally { submitting.current = false; setBusy(false); }
  }

  async function checkout(event?: React.FormEvent<HTMLFormElement>) {
    event?.preventDefault();
    if (submitting.current || !canPurchase || unknownRequest || (method === 'MPESA' && !quote)) return;
    if (method === 'MPESA') {
      try { normalizeMpesaPhone(phone); } catch (err) { setError((err as Error).message); return; }
    }
    submitting.current = true; setBusy(true); setError('');
    try {
      if (method === 'MPESA' && quote) {
        const result = await startMpesaSubscription(quote, phone);
        navigate(mpesaPaymentPath(result.paymentId));
      } else {
        const result = await apiRequest<{ checkoutUrl: string; sessionId: string }>('/subscriptions/subscribe', {
          method: 'POST', body: { planId, paymentMethod: 'STRIPE', billingPeriod: 'monthly' },
        });
        const url = hostedCheckoutUrl(result.checkoutUrl);
        if (!/^cs_[A-Za-z0-9_]+$/.test(result.sessionId)) throw new Error('The payment provider returned an invalid session. Please contact support.');
        sessionStorage.setItem(CHECKOUT_KEY, result.sessionId);
        window.location.assign(url);
      }
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) setExpired(true);
      if (method === 'MPESA') {
        // A transport failure can happen after the provider accepted the request.
        if (!(err instanceof ApiError) || err.status >= 500) setUnknownRequest(true);
        setQuoteAttempt(n => n + 1);
        try {
          const subscription = await apiRequest<Subscription>('/subscriptions/current');
          if (data) setLoaded({ ...data, current: subscription });
          if (subscription.pendingPayment && isMpesaPaymentMethod(subscription.pendingPayment.paymentMethod)) {
            navigate(mpesaPaymentPath(subscription.pendingPayment.id));
            return;
          }
        } catch { /* Keep the original error; never send a second payment here. */ }
      }
      setError(err instanceof Error ? err.message : 'Could not start checkout. Please try again.');
    } finally { submitting.current = false; setBusy(false); }
  }

  return <section className="max-w-xl mx-auto px-4 py-16 sm:py-24">
    <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-6 sm:p-10">
      <h1 className="text-3xl font-bold text-white mb-6">{manualRenewal ? 'Renew your subscription' : 'Review your subscription'}</h1>
      {error ? <p role="alert" className="text-rose-300 mb-4">{error} {!busy && !unknownRequest ? <button onClick={() => { setError(''); setReload(n => n + 1); setQuoteAttempt(n => n + 1); }} className="underline">Refresh details</button> : null}</p> : null}
      {data ? <>
        <h2 className="text-xl font-semibold text-white">{data.plan.name}</h2>
        <p className="text-slate-300 mt-2">Up to {data.plan.worker_limit} workers.</p>
        {pending ? <div role="status" className="mt-6 text-slate-300">
          <p>A subscription payment is already pending. Check it before starting another payment.</p>
          {isMpesaPaymentMethod(pending.paymentMethod) && validPaymentId(pending.id) ? <Button asChild className="mt-4 bg-emerald-500 text-white"><Link to={mpesaPaymentPath(pending.id)}>Check M-Pesa payment</Link></Button> : <Link to="/account" className="text-emerald-400 underline">View account</Link>}
        </div> : <>
          <fieldset disabled={busy || unknownRequest} className="mt-6 flex flex-wrap gap-4 text-white">
            <legend className="text-sm text-slate-300 mb-2">Payment method</legend>
            <label className="flex items-center gap-2"><input type="radio" name="method" checked={method === 'MPESA'} onChange={() => { setMethod('MPESA'); setError(''); }} />M-Pesa · KES</label>
            <label className="flex items-center gap-2"><input type="radio" name="method" checked={method === 'STRIPE'} onChange={() => { setMethod('STRIPE'); setError(''); }} />Card · USD</label>
          </fieldset>
          {!canPurchase ? <p className="mt-6 text-slate-300">You already have a paid subscription. {current?.renewalMode === 'manual' && current.tier.toLowerCase() === planId ? 'Choose M-Pesa to approve its next renewal.' : <> <Link to="/account" className="text-emerald-400 underline">Manage your current plan</Link> or contact support to change plans.</>}</p> : method === 'STRIPE' ? <>
            <p className="text-3xl font-bold text-white my-4">{money(Number(data.plan.price_usd), 'USD')}<span className="text-base font-normal text-slate-400"> USD / month</span></p>
            <p className="text-slate-400">Card subscriptions renew automatically each month. Review the final amount on Stripe before paying. You can turn off renewal in your account.</p>
            <Button disabled={busy || unknownRequest} onClick={() => void checkout()} className="w-full mt-6 bg-emerald-500 hover:bg-emerald-600 text-white">{busy ? 'Opening secure checkout…' : 'Continue to Stripe checkout'}</Button>
          </> : <form onSubmit={checkout} className="mt-5 space-y-4">
            <label className="block text-sm text-slate-300">Billing period<select value={period} disabled={busy || unknownRequest} onChange={event => { setPeriod(event.target.value as BillingPeriod); setError(''); }} className={`${inputClass} mt-2`}><option value="monthly">Monthly</option><option value="yearly">Yearly</option></select></label>
            {quote ? <div aria-live="polite" className="rounded-lg bg-white/5 p-4 text-slate-300">
              <p className="text-2xl font-bold text-white">Pay {money(quote.amount, 'KES')}</p>
              <p className="mt-2">{period === 'yearly' ? 'One year' : 'One month'} of access, through {new Date(quote.periodEnd).toLocaleDateString()}.</p>
              <p className="mt-2 text-sm">You approve this payment on your phone. Each renewal requires another approval; M-Pesa is never debited automatically.</p>
            </div> : !error ? <p role="status" className="text-slate-400">Loading the exact KES price…</p> : null}
            <label className="block text-sm text-slate-300">M-Pesa phone number<input name="phone" type="tel" inputMode="tel" autoComplete="tel" required value={phone} disabled={busy || unknownRequest} onChange={event => setPhone(event.target.value)} placeholder="0712 345 678" className={`${inputClass} mt-2`} /></label>
            <Button type="submit" disabled={busy || unknownRequest || !quote || !phone.trim()} className="w-full bg-emerald-500 hover:bg-emerald-600 text-white">{busy ? 'Sending payment request…' : quote ? `Send M-Pesa request for ${money(quote.amount, 'KES')}` : 'Waiting for price'}</Button>
            <p className="text-xs text-slate-400">Enter your PIN only in the M-Pesa prompt on your phone. Access changes only after payment confirmation.</p>
          </form>}
        </>}
        {unknownRequest ? <div className="mt-4 text-slate-300"><p>The request outcome is not confirmed. Check its status before paying again.</p><Button disabled={busy} onClick={() => void checkExistingPayment()} className="mt-3 bg-emerald-500 text-white">Check existing payment</Button></div> : null}
        <p className="text-slate-400 mt-6">Payroll and worker management are in the mobile app. <Link to="/get-started" className="text-emerald-400 underline">Check app access</Link> before subscribing.</p>
      </> : !error ? <p role="status" className="text-slate-400">Loading the current plan and price…</p> : null}
      <Link to="/pricing" className="block mt-6 text-sm text-emerald-400 underline">Back to plans</Link>
    </div>
  </section>;
}
