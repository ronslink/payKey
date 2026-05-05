import { useState } from 'react';
import { Link } from 'react-router-dom';

const API_URL = import.meta.env.VITE_API_URL || 'https://api.paydome.co';

export default function DeleteMe() {
    const [email, setEmail] = useState('');
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
            const response = await fetch(`${API_URL}/data-deletion/request`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password, reason }),
            });

            if (!response.ok) {
                throw new Error('Failed to submit request. Please try again.');
            }

            const data = await response.json();
            setRequestId(data.requestId);
            setSubmitted(true);
        } catch (err) {
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
                    <p className="text-slate-400 text-center leading-relaxed mb-6">
                        Your data deletion request has been received and will be processed automatically.
                        All data associated with <strong className="text-white">{email}</strong> will be permanently deleted.
                    </p>
                    <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4 mb-6">
                        <p className="text-sm text-emerald-400">
                            <strong>Request ID:</strong> {requestId}
                        </p>
                        <p className="text-sm text-emerald-400 mt-1">
                            This process is fully automated and typically completes within 24 hours.
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
                <h1 className="text-2xl font-bold text-white text-center mb-4">Delete My Data</h1>
                <p className="text-slate-400 text-center leading-relaxed mb-6">
                    Request the deletion of all your personal data from payDome.
                    This action is irreversible and will permanently remove your account and all associated data.
                </p>

                <div className="bg-amber-500/10 border border-amber-500/30 rounded-xl p-4 mb-6 text-sm text-amber-200">
                    <strong>⚠️ Warning:</strong> This will delete:
                    <ul className="list-disc pl-5 mt-2 space-y-1 text-amber-300/80">
                        <li>Your account and profile information</li>
                        <li>All worker records</li>
                        <li>Payroll history and payslips</li>
                        <li>Time tracking and leave records</li>
                        <li>Payment and transaction history</li>
                        <li>All other associated data</li>
                    </ul>
                </div>

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
                            placeholder="Enter your account email"
                            required
                            className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-500 outline-none focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/25 transition-colors"
                        />
                    </div>

                    <div className="flex flex-col gap-2">
                        <label htmlFor="password" className="text-sm font-semibold text-slate-300">
                            Password
                        </label>
                        <input
                            type="password"
                            id="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="Enter your account password (if not Google/Apple)"
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

                    {error && <p className="text-red-400 text-sm">{error}</p>}

                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className="w-full bg-red-600 hover:bg-red-700 text-white font-semibold py-3.5 rounded-lg transition-all disabled:opacity-60 cursor-pointer mt-2"
                    >
                        {isSubmitting ? 'Submitting...' : 'Delete My Data'}
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
