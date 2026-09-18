import { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { accountReturnPath, apiRequest, ApiError, authenticate, clearSession, readSession, selectedPlan } from '@/lib/billing-api';
import type { AccountSession, Subscription } from '@/lib/billing-api';

const inputClass = 'w-full rounded-lg border border-white/15 bg-white/5 px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500';

function AccountOverview({ session, onSignOut }: { session: AccountSession; onSignOut: () => void }) {
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [reload, setReload] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    apiRequest<Subscription>('/subscriptions/current', { signal: controller.signal })
      .then(setSubscription).catch((err) => {
        if (!controller.signal.aborted) setError(err instanceof Error ? err.message : 'Could not load your subscription.');
      });
    return () => controller.abort();
  }, [reload]);

  async function setRenewal(enable: boolean) {
    setBusy(true); setError('');
    try {
      const result = await apiRequest<{ subscription: Subscription }>('/subscriptions/auto-renew', {
        method: 'POST', body: { enable },
      });
      setSubscription(result.subscription);
    } catch (err) { setError(err instanceof Error ? err.message : 'Could not update renewal.'); }
    finally { setBusy(false); }
  }

  return <>
    <h1 className="text-3xl font-bold text-white mb-3">Your Paydome account</h1>
    <p className="text-slate-400 break-all mb-8">Signed in as {session.email}</p>
    {error ? <div role="alert" className="text-rose-300 mb-4">{error} {readSession()
      ? <button className="underline" onClick={() => { setError(''); setReload(n => n + 1); }}>Retry</button>
      : <button className="underline" onClick={onSignOut}>Sign in again</button>}</div> : null}
    {subscription ? <div className="rounded-xl bg-white/5 border border-white/10 p-6 mb-6">
      <h2 className="text-xl font-semibold text-white">{subscription.planName || subscription.tier}</h2>
      <p className="text-slate-400 mt-2">{subscription.id ? `Subscription status: ${subscription.status || 'Unavailable'}` : 'Free account — no paid subscription confirmed.'}</p>
      {subscription.endDate ? <p className="text-slate-400 mt-2">Current period ends {new Date(subscription.endDate).toLocaleDateString()}.</p> : null}
      {subscription.id ? <>
        <p className="text-slate-300 mt-3">Automatic renewal: {subscription.autoRenew ? 'On' : 'Off'}</p>
        <p className="text-sm text-slate-400 mt-2">{subscription.autoRenewalDescription}</p>
        <Button disabled={busy} onClick={() => setRenewal(!subscription.autoRenew)} variant="outline" className="mt-4 bg-white/5 border-white/20 text-white">
          {busy ? 'Updating…' : subscription.autoRenew ? 'Turn off automatic renewal' : 'Turn on automatic renewal'}
        </Button>
      </> : <Button asChild className="mt-4 bg-emerald-500 text-white"><Link to="/pricing">Choose a plan</Link></Button>}
    </div> : !error ? <p role="status" className="text-slate-400 mb-6">Loading your subscription…</p> : null}
    <p className="text-slate-400 mb-6">Use the same email and password in the Paydome app to manage workers and payroll.</p>
    <div className="flex flex-wrap gap-3">
      <Button asChild className="bg-emerald-500 hover:bg-emerald-600 text-white"><Link to="/get-started">App access</Link></Button>
      <Button onClick={onSignOut} variant="outline" className="bg-white/5 border-white/20 text-white">Sign out</Button>
    </div>
  </>;
}

export default function Account() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const plan = selectedPlan(params.get('plan'));
  const next = accountReturnPath(params.get('next')) || (plan !== 'free' ? `/checkout?plan=${plan}` : null);
  const [session, setSession] = useState(readSession);
  const [mode, setMode] = useState<'register' | 'login'>(params.get('mode') === 'login' ? 'login' : 'register');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => { if (session && next) navigate(next, { replace: true }); }, [session, next, navigate]);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setError('');
    const form = new FormData(event.currentTarget);
    try {
      const result = await authenticate(mode, {
        email: String(form.get('email')).trim(), password: String(form.get('password')),
        ...(mode === 'register' ? { firstName: String(form.get('firstName')).trim(), lastName: String(form.get('lastName')).trim() } : {}),
      });
      setSession(result);
    } catch (err) { setError(err instanceof ApiError ? err.message : 'Could not sign in. Check your connection and try again.'); }
    finally { setBusy(false); }
  }

  return <section className="max-w-xl mx-auto px-4 py-16 sm:py-24">
    <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 sm:p-10">
      {session ? <AccountOverview session={session} onSignOut={() => { clearSession(); setSession(null); setMode('login'); navigate('/account?mode=login', { replace: true }); }} /> : <>
        <h1 className="text-3xl font-bold text-white mb-3">{mode === 'register' ? 'Create your account' : 'Sign in to Paydome'}</h1>
        <p className="text-slate-400 mb-8">{plan !== 'free' ? `Continue to review the ${plan} plan before paying.` : 'Manage your subscription and use the same account in the app.'}</p>
        <form onSubmit={submit} className="space-y-5">
          {mode === 'register' ? <div className="grid sm:grid-cols-2 gap-4">
            <label className="block text-sm text-slate-300">First name<input name="firstName" required autoComplete="given-name" maxLength={100} className={`${inputClass} mt-2`} /></label>
            <label className="block text-sm text-slate-300">Last name<input name="lastName" required autoComplete="family-name" maxLength={100} className={`${inputClass} mt-2`} /></label>
          </div> : null}
          <label className="block text-sm text-slate-300">Email<input name="email" type="email" required autoComplete="email" maxLength={254} className={`${inputClass} mt-2`} /></label>
          <label className="block text-sm text-slate-300">Password<input name="password" type="password" required minLength={6} autoComplete={mode === 'register' ? 'new-password' : 'current-password'} className={`${inputClass} mt-2`} /></label>
          {mode === 'register' ? <p className="text-sm text-slate-400">Review our <Link className="text-emerald-400 underline" to="/paydome/privacy_policy">privacy policy</Link>. Creating an account does not charge you.</p> : null}
          {error ? <p role="alert" className="text-rose-300">{error}</p> : null}
          <Button disabled={busy} type="submit" className="w-full bg-emerald-500 hover:bg-emerald-600 text-white">{busy ? 'Please wait…' : mode === 'register' ? 'Create account' : 'Sign in'}</Button>
        </form>
        <button disabled={busy} className="text-emerald-400 underline text-sm mt-6" onClick={() => { setMode(mode === 'register' ? 'login' : 'register'); setError(''); }}>
          {mode === 'register' ? 'Already have an account? Sign in' : 'New to Paydome? Create an account'}
        </button>
        <p className="text-sm text-slate-500 mt-5">Need help accessing your account? <Link to="/contact" className="text-emerald-400 underline">Contact support</Link>.</p>
      </>}
    </div>
  </section>;
}
