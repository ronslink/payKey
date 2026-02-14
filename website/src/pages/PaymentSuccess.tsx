import { Link } from 'react-router-dom';

export default function PaymentSuccess() {
  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      margin: 0,
      backgroundColor: '#f0fdf4',
      color: '#166534',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    }}>
      <div style={{
        textAlign: 'center',
        padding: '3rem',
        background: 'white',
        borderRadius: '1rem',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
        maxWidth: '90%',
      }}>
        <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>✅</div>
        <h1 style={{ margin: '0 0 0.5rem', fontSize: '2rem' }}>Payment Successful!</h1>
        <p style={{ margin: 0, color: '#4b5563', fontSize: '1.1rem' }}>
          Your subscription is now active.
        </p>
        <p style={{ marginTop: '1.5rem', color: '#4b5563' }}>
          You can close this window and return to the PayKey app.
        </p>
        <Link
          to="/"
          style={{
            display: 'inline-block',
            marginTop: '2rem',
            padding: '0.75rem 1.5rem',
            backgroundColor: '#166534',
            color: 'white',
            textDecoration: 'none',
            borderRadius: '0.5rem',
            fontWeight: '500',
          }}
        >
          Go to Home
        </Link>
      </div>
    </div>
  );
}
