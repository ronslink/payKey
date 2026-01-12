# Stripe Payments

## Overview
Stripe integration for subscription billing and international card payments.

## Environment Variables
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
FRONTEND_URL=https://paydome.co
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payments/subscriptions/plans` | Get subscription plans |
| POST | `/payments/subscriptions/checkout` | Create checkout session |
| POST | `/payments/subscriptions/webhook` | Handle Stripe webhooks |
| GET | `/payments/subscriptions/payment-history` | Get payment history |

## Checkout Flow
1. User selects plan
2. Backend creates Stripe Checkout session
3. User redirected to Stripe hosted page
4. User enters card details
5. Stripe processes payment
6. Webhook confirms subscription
7. User tier updated

## Webhook Events Handled
- `checkout.session.completed` - New subscription
- `invoice.payment_succeeded` - Renewal success
- `invoice.payment_failed` - Payment failed
- `customer.subscription.deleted` - Subscription cancelled

## Mobile UI
- **Subscription Management**: `mobile/lib/features/subscriptions/presentation/pages/`

## Database Entities
- `Subscription` - Stores subscription status
- `SubscriptionPayment` - Payment records

## Current Configuration Status
- ✅ Stripe Checkout working
- ✅ Webhook verification
- ✅ Subscription lifecycle management
- ✅ Production keys configured

## Webhook Setup
1. Create webhook endpoint in Stripe Dashboard
2. Point to: `https://api.paydome.co/payments/subscriptions/webhook`
3. Select events: `checkout.session.completed`, `invoice.*`
4. Copy signing secret to `STRIPE_WEBHOOK_SECRET`
