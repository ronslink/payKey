import { useState } from 'react';

const API_URL = import.meta.env.VITE_API_URL || 'https://api.paydome.co';

export default function DeleteMe() {
    const [email, setEmail] = useState('');
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
                body: JSON.stringify({ email, reason }),
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
            <div style={styles.container}>
                <div style={styles.card}>
                    <div style={styles.successIcon}>✓</div>
                    <h1 style={styles.title}>Request Submitted</h1>
                    <p style={styles.description}>
                        Your data deletion request has been received and will be processed automatically.
                        All data associated with <strong>{email}</strong> will be permanently deleted.
                    </p>
                    <div style={styles.infoBox}>
                        <p style={styles.infoText}>
                            <strong>Request ID:</strong> {requestId}
                        </p>
                        <p style={styles.infoText}>
                            This process is fully automated and typically completes within 24 hours.
                        </p>
                    </div>
                    <a href="/" style={styles.backLink}>← Back to Home</a>
                </div>
            </div>
        );
    }

    return (
        <div style={styles.container}>
            <div style={styles.card}>
                <h1 style={styles.title}>Delete My Data</h1>
                <p style={styles.description}>
                    Request the deletion of all your personal data from payDome.
                    This action is irreversible and will permanently remove your account and all associated data.
                </p>

                <div style={styles.warningBox}>
                    <strong>⚠️ Warning:</strong> This will delete:
                    <ul style={styles.list}>
                        <li>Your account and profile information</li>
                        <li>All worker records</li>
                        <li>Payroll history and payslips</li>
                        <li>Time tracking and leave records</li>
                        <li>Payment and transaction history</li>
                        <li>All other associated data</li>
                    </ul>
                </div>

                <form onSubmit={handleSubmit} style={styles.form}>
                    <div style={styles.formGroup}>
                        <label htmlFor="email" style={styles.label}>
                            Email Address *
                        </label>
                        <input
                            type="email"
                            id="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="Enter your account email"
                            required
                            style={styles.input}
                        />
                    </div>

                    <div style={styles.formGroup}>
                        <label htmlFor="reason" style={styles.label}>
                            Reason for Deletion (Optional)
                        </label>
                        <textarea
                            id="reason"
                            value={reason}
                            onChange={(e) => setReason(e.target.value)}
                            placeholder="Help us improve by sharing why you're leaving"
                            rows={3}
                            style={styles.textarea}
                        />
                    </div>

                    {error && <p style={styles.error}>{error}</p>}

                    <button
                        type="submit"
                        disabled={isSubmitting}
                        style={{
                            ...styles.button,
                            opacity: isSubmitting ? 0.7 : 1,
                        }}
                    >
                        {isSubmitting ? 'Submitting...' : 'Delete My Data'}
                    </button>
                </form>

                <a href="/" style={styles.backLink}>← Cancel and go back</a>
            </div>
        </div>
    );
}

const styles: { [key: string]: React.CSSProperties } = {
    container: {
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #1E40AF 0%, #6366F1 100%)',
        padding: '20px',
    },
    card: {
        background: 'white',
        borderRadius: '16px',
        padding: '40px',
        maxWidth: '500px',
        width: '100%',
        boxShadow: '0 20px 60px rgba(0, 0, 0, 0.2)',
    },
    title: {
        fontSize: '28px',
        fontWeight: 'bold',
        color: '#1E293B',
        marginBottom: '16px',
        textAlign: 'center',
    },
    description: {
        fontSize: '16px',
        color: '#64748B',
        marginBottom: '24px',
        textAlign: 'center',
        lineHeight: '1.6',
    },
    warningBox: {
        background: '#FEF3C7',
        border: '1px solid #F59E0B',
        borderRadius: '8px',
        padding: '16px',
        marginBottom: '24px',
        fontSize: '14px',
        color: '#92400E',
    },
    list: {
        marginTop: '8px',
        marginBottom: '0',
        paddingLeft: '20px',
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
    },
    formGroup: {
        display: 'flex',
        flexDirection: 'column',
        gap: '8px',
    },
    label: {
        fontSize: '14px',
        fontWeight: '600',
        color: '#374151',
    },
    input: {
        padding: '12px 16px',
        borderRadius: '8px',
        border: '1px solid #D1D5DB',
        fontSize: '16px',
        outline: 'none',
    },
    textarea: {
        padding: '12px 16px',
        borderRadius: '8px',
        border: '1px solid #D1D5DB',
        fontSize: '16px',
        outline: 'none',
        resize: 'vertical',
        fontFamily: 'inherit',
    },
    button: {
        background: '#DC2626',
        color: 'white',
        padding: '14px 24px',
        borderRadius: '8px',
        border: 'none',
        fontSize: '16px',
        fontWeight: '600',
        cursor: 'pointer',
        marginTop: '8px',
    },
    error: {
        color: '#DC2626',
        fontSize: '14px',
        margin: '0',
    },
    backLink: {
        display: 'block',
        textAlign: 'center',
        marginTop: '24px',
        color: '#6366F1',
        textDecoration: 'none',
        fontSize: '14px',
    },
    successIcon: {
        width: '64px',
        height: '64px',
        borderRadius: '50%',
        background: '#10B981',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '32px',
        margin: '0 auto 24px',
    },
    infoBox: {
        background: '#F0FDF4',
        border: '1px solid #10B981',
        borderRadius: '8px',
        padding: '16px',
        marginBottom: '24px',
    },
    infoText: {
        fontSize: '14px',
        color: '#166534',
        margin: '4px 0',
    },
};
