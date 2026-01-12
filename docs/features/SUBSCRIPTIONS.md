# Subscriptions Feature

## Overview
Tiered subscription system controlling feature access with Stripe payment integration.

## Subscription Tiers

| Tier | Price | Workers | Features |
|------|-------|---------|----------|
| FREE | $0 | 1 | Basic worker management |
| BASIC | $9.99/mo | 5 | + M-Pesa payments |
| GOLD | $29.99/mo | 10 | + Excel import, reports |
| PLATINUM | $49.99/mo | 15 | + Leave management, full features |

## Environment Variables
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
FRONTEND_URL=http://localhost:3000
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payments/subscriptions/plans` | Get available plans |
| GET | `/payments/subscriptions/current` | Get current subscription |
| POST | `/payments/subscriptions/checkout` | Create Stripe checkout |
| GET | `/payments/subscriptions/payment-history` | Payment history |
| POST | `/payments/subscriptions/webhook` | Stripe webhook |
| GET | `/subscriptions/features` | Get feature access |

## Feature Gating
Guards control access per tier:
- `SubscriptionGuard` - Validates active subscription
- `TierGuard` - Validates specific tier requirement
- `ImportFeatureGuard` - Gold+ for Excel import
- `PlatinumGuard` - Platinum for leave management

## Mobile UI
- **Subscription Page**: `mobile/lib/features/subscriptions/presentation/pages/`
- **Settings**: Shows current tier in profile

## Database Entities
- `Subscription` - `backend/src/modules/subscriptions/entities/subscription.entity.ts`
- `SubscriptionPayment` - `backend/src/modules/subscriptions/entities/subscription-payment.entity.ts`

## Current Configuration Status
- ✅ Stripe checkout integration
- ✅ Webhook handling for subscription events
- ✅ Feature gating by tier
- ✅ Worker limit enforcement

## Known Gaps
| Gap | Status |
|-----|--------|
| Worker Count Validation | ⚠️ TODO in feature-access.service.ts |
| Cancel Subscription UI | ⚠️ Backend ready, UI incomplete |
