import { useState } from 'react';
import { Link } from 'react-router-dom';
import { readSession } from '@/lib/billing-api';
import { requestAccountDeletion } from '@/lib/account-deletion-api';

export default function DeleteMe() {
    const [session, setSession] = useState(readSession);
    const [email, setEmail] = useState(() => readSession()?.email || '');
    const [password, setPassword] = useState('');
    const [reason, setReason] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [submitted, setSubmitted] = useState(false);
    const [error, setError] = useState('');
    const [requestId, setRequestId] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);
        setError('');

        try {
            const data = await requestAccountDeletion({ email, password, reason });
            setRequestId(data.requestId);
            setPassword('');
            setSubmitted(true);
        } catch (err) {
            setSession(readSession());
            setError(err instanceof Error ? err.message : 'An error occurred');
        } finally {
            setIsSubmitting(false);
        }
    };

    if (submitted) {
        return (
            <div className="min-h-screen flex items-center justify-center px-4">
                <div className="bg-card border border-white/10 rounded-2xl p-8 sm:p-10 max-w-lg w-full shadow-2xl">
                    <div className="w-16 h-16 rounded-full bg-emerald-500 text-white flex items-center justify-center text-3xl font-bold mx-auto mb-6">
                        ✓
                    </div>
                    <h1 className="text-2xl font-bold text-white text-center mb-4">Request Submitted</h1>
                    <p role="status" className="text-slate-400 text-center leading-relaxed mb-6">
                        Your account-deletion request for <strong className="text-white">{email}</strong> has been received.
                        This confirms receipt of the request, not completion of deletion.
                    </p>
                    <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4 mb-6">
                        <p className="text-sm text-emerald-400">
                            <strong>Request ID:</strong> {requestId}
                        </p>
                        <p className="text-sm text-emerald-400 mt-1">
                            Keep this reference. Contact support@paydome.co if you need help checking your request.
                        </p>
                    </div>
                    <Link
                        to="/"
                        className="block text-center text-sm text-emerald-400 hover:text-emerald-300 transition-colors"
                    >
                        ← Back to Home
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen flex items-center justify-center px-4 py-20">
            <div className="bg-card border border-white/10 rounded-2xl p-8 sm:p-10 max-w-lg w-full shadow-2xl">
                <h1 className="text-2xl font-bold text-white text-center mb-4">Delete My Paydome Account</h1>
                <p className="text-slate-400 text-center leading-relaxed mb-6">
                    Request deletion of your Paydome account and associated personal data.
                    This closes your account; it is not a request to remove selected data while keeping the account.
                </p>

                <div className="bg-amber-500/10 border border-amber-500/30 rounded-xl p-4 mb-6 text-sm text-amber-200">
                    <strong>Account deletion includes:</strong>
                    <ul className="list-disc pl-5 mt-2 space-y-1 text-amber-300/80">
                        <li>Your account and profile information</li>
                        <li>All worker records</li>
                        <li>Payroll history and payslips</li>
                        <li>Time tracking and leave records</li>
                        <li>Payment and transaction history</li>
                    </ul>
                    <p className="mt-3">Some records may need to be retained for legal, accounting or security requirements, as described in our <Link className="underline" to="/paydome/privacy_policy">privacy policy</Link>.</p>
                    <p className="mt-3">End any recurring subscription before requesting account deletion.</p>
                </div>

                <div className="mb-6 rounded-xl border border-white/10 bg-white/5 p-4 text-sm text-slate-300">
                    <p className="font-semibold text-white">Signed up with Google or Apple?</p>
                    <p className="mt-2">This website currently supports email and password sign-in. For help deleting an account created with Google or Apple, <a className="text-emerald-400 underline" href="mailto:support@paydome.co?subject=Paydome%20account%20deletion">email support@paydome.co</a> from the address linked to your account. We need to verify ownership before processing the request. Do not send your password.</p>
                </div>

                {session ? <p className="mb-4 text-sm text-slate-300">Requesting deletion of the signed-in account: <strong className="break-all">{session.email}</strong>.</p> : <p className="mb-4 text-sm text-slate-300">If your account has a password, use the form below to confirm ownership.</p>}

                <form onSubmit={handleSubmit} className="flex flex-col gap-5">
                    <div className="flex flex-col gap-2">
                        <label htmlFor="email" className="text-sm font-semibold text-slate-300">
                            Email Address *
                        </label>
                        <input
                            type="email"
                            id="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            readOnly={Boolean(session)}
                            autoComplete="email"
                            placeholder="Enter your account email"
                            required
                            className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-500 outline-none focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/25 transition-colors"
                        />
                    </div>

                    <div className="flex flex-col gap-2">
                        <label htmlFor="password" className="text-sm font-semibold text-slate-300">
                            {session ? 'Account Password (if set)' : 'Account Password *'}
                        </label>
                        <input
                            type="password"
                            id="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="Enter your account password"
                            required={!session}
                            autoComplete="current-password"
                            className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-500 outline-none focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/25 transition-colors"
                        />
                    </div>

                    <div className="flex flex-col gap-2">
                        <label htmlFor="reason" className="text-sm font-semibold text-slate-300">
                            Reason for Deletion (Optional)
                        </label>
                        <textarea
                            id="reason"
                            value={reason}
                            onChange={(e) => setReason(e.target.value)}
                            placeholder="Help us improve by sharing why you're leaving"
                            rows={3}
                            className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-500 outline-none focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/25 transition-colors resize-vertical font-[inherit]"
                        />
                    </div>

                    {error && <p role="alert" className="text-red-400 text-sm">{error}</p>}

                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className="w-full bg-red-600 hover:bg-red-700 text-white font-semibold py-3.5 rounded-lg transition-all disabled:opacity-60 cursor-pointer mt-2"
                    >
                        {isSubmitting ? 'Submitting...' : 'Request Account Deletion'}
                    </button>
                </form>

                <Link
                    to="/"
                    className="block text-center mt-6 text-sm text-emerald-400 hover:text-emerald-300 transition-colors"
                >
                    ← Cancel and go back
                </Link>
            </div>
        </div>
    );
}
