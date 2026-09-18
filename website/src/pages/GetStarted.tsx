import { ArrowRight, Mail, Smartphone } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { appLinks } from '@/lib/app-links';

export default function GetStarted() {
  const hasDownload = Boolean(appLinks.android || appLinks.ios);

  return (
    <section className="relative max-w-3xl mx-auto px-4 sm:px-6 py-16 sm:py-24">
      <div className="text-center mb-10">
        <Smartphone className="w-12 h-12 text-emerald-400 mx-auto mb-6" aria-hidden="true" />
        <h1 className="text-4xl sm:text-5xl font-bold text-white mb-5">Get started with Paydome</h1>
        <p className="text-lg text-slate-400 leading-relaxed">
          {hasDownload
            ? 'Choose your device to view the available app or beta access. Create your account in the app when access is available.'
            : 'Contact our team for current app availability and help getting started with your household payroll.'}
        </p>
      </div>
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 sm:p-8 mb-6 text-center">
        <h2 className="text-xl font-semibold text-white mb-3">Create your Paydome account</h2>
        <p className="text-slate-400 mb-5">Create an account or sign in to review plans and manage your subscription. Use that same account in the mobile app.</p>
        <div className="flex flex-col sm:flex-row justify-center gap-3">
          <Button asChild className="bg-emerald-500 hover:bg-emerald-600 text-white"><Link to="/account">Create account</Link></Button>
          <Button asChild variant="outline" className="bg-white/5 border-white/20 text-white"><Link to="/account?mode=login">Sign in</Link></Button>
        </div>
      </div>
      <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-6 sm:p-10 space-y-6">
        {hasDownload ? (
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            {appLinks.android ? (
              <Button asChild size="lg" className="bg-emerald-500 hover:bg-emerald-600 text-white">
                <a href={appLinks.android} rel="noopener noreferrer">View Android access <ArrowRight aria-hidden="true" /></a>
              </Button>
            ) : null}
            {appLinks.ios ? (
              <Button asChild size="lg" className="bg-emerald-500 hover:bg-emerald-600 text-white">
                <a href={appLinks.ios} rel="noopener noreferrer">View iPhone access <ArrowRight aria-hidden="true" /></a>
              </Button>
            ) : null}
          </div>
        ) : null}
        <div className="text-center">
          <h2 className="text-xl font-semibold text-white mb-3">Need access or a hand setting up?</h2>
          <p className="text-slate-400 mb-6">Tell us whether you use Android or iPhone. Our team can confirm availability and the next steps for your device.</p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <Button asChild size="lg" className="bg-white hover:bg-slate-100 text-emerald-900">
              <a href="mailto:support@paydome.co?subject=Paydome%20app%20access"><Mail aria-hidden="true" /> Email for app access</a>
            </Button>
            <Button asChild size="lg" variant="outline" className="border-white/20 bg-white/5 text-white hover:bg-white/10">
              <Link to="/contact">Contact our team</Link>
            </Button>
          </div>
        </div>
      </div>
      <p className="text-sm text-slate-500 text-center mt-8">Review <Link to="/pricing" className="text-emerald-400 underline">plans and features</Link> or read our <Link to="/paydome/privacy_policy" className="text-emerald-400 underline">privacy policy</Link> before getting started.</p>
    </section>
  );
}
