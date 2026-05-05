import { Link } from 'react-router-dom';
import { CheckCircle } from 'lucide-react';

export default function PaymentSuccess() {
    return (
        <div className="min-h-screen flex items-center justify-center px-4">
            <div className="text-center bg-card border border-white/10 rounded-2xl p-10 sm:p-12 max-w-md w-full shadow-2xl">
                <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-emerald-500/20 flex items-center justify-center">
                    <CheckCircle className="w-10 h-10 text-emerald-400" />
                </div>
                <h1 className="text-2xl font-bold text-white mb-2">Payment Successful!</h1>
                <p className="text-slate-400 leading-relaxed">
                    Your subscription is now active.
                </p>
                <p className="text-slate-400 mt-4 leading-relaxed">
                    You can close this window and return to the PayKey app.
                </p>
                <Link
                    to="/"
                    className="inline-block mt-8 px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-semibold rounded-lg transition-all shadow-lg shadow-emerald-500/20"
                >
                    Go to Home
                </Link>
            </div>
        </div>
    );
}
