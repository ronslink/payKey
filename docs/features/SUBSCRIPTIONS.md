                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          # Subscriptions Feature

## Overview
Tiered subscription system controlling feature access with Stripe and M-Pesa (via IntaSend) payment integration.

## Subscription Tiers

| Tier | Price | Workers | Features |
|------|-------|---------|----------|
| FREE | $0 | 1 | Basic worker management |
| BASIC | $9.99/mo | 5 | + M-Pesa payments |
| GOLD | $29.99/mo | 10 | + Excel import, reports |
| PLATINUM | $49.99/mo | 20 | + Leave management, full features |

## Environment Variables
```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
INTASEND_PUBLISHABLE_KEY=ISPubKey_...
INTASEND_SECRET_KEY=ISSecretKey_...
FRONTEND_URL=http://localhost:3000
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/payments/subscriptions/plans` | Get available plans |
| GET | `/payments/subscriptions/current` | Get current subscription |
| POST | `/payments/subscriptions/checkout` | Create Stripe checkout |
| POST | `/payments/subscriptions/mpesa` | Create M-Pesa checkout |
| GET | `/payments/subscriptions/payment-history` | Payment history |
| POST | `/payments/subscriptions/webhook` | Stripe webhook |
| GET | `/subscriptions/features` | Get feature access |
| GET | `/subscriptions/usage` | Get usage statistics |
| PUT | `/subscriptions` | Update subscription settings |

## Subscription Statuses
- `ACTIVE` - Subscription is active and valid
- `PENDING` - Payment processing
- `CANCELLED` - Subscription cancelled
- `EXPIRED` - Subscription expired
- `PAST_DUE` - Payment failed, retrying
- `TRIAL` - Trial period

## Feature Gating
Guards control access per tier:
- `SubscriptionGuard` - Validates active subscription
- `TierGuard` - Validates specific tier requirement
- `ImportFeatureGuard` - Gold+ for Excel import
- `PlatinumGuard` - Platinum for leave management

## Renewal Methods
- `NOTIFICATION` - User notified to make manual payment
- `STK_PUSH` - Automatic M-Pesa STK push on renewal

## Mobile UI
- **Pricing Page**: `mobile/lib/features/subscriptions/presentation/pages/pricing_page.dart`
- **Subscription Details**: `mobile/lib/features/subscriptions/presentation/pages/subscription_details_page.dart`
- **Subscription Management**: `mobile/lib/features/subscriptions/presentation/pages/subscription_management_page.dart`
- **Payment Page**: `mobile/lib/features/subscriptions/presentation/pages/payment_page.dart`
- **Settings**: Shows current tier in profile

## Database Entities
- `Subscription` - `backend/src/modules/subscriptions/entities/subscription.entity.ts`
- `SubscriptionPayment` - `backend/src/modules/subscriptions/entities/subscription-payment.entity.ts`

## Subscription Entity Fields
| Field | Type | Description |
|-------|------|-------------|
| id | uuid | Primary key |
| userId | uuid | Foreign key to users |
| tier | enum | FREE, BASIC, GOLD, PLATINUM |
| status | enum | ACTIVE, PENDING, CANCELLED, etc. |
| billingPeriod | string | monthly, yearly |
| amount | decimal | Subscription amount |
| currency | string | USD, KES |
| startDate | timestamp | Subscription start |
| endDate | timestamp | Subscription end |
| nextBillingDate | timestamp | Next billing date |
| stripeSubscriptionId | string | Stripe subscription ID |
| stripePriceId | string | Stripe price ID |
| autoRenewal | boolean | Auto-renewal enabled |
| renewalMethod | enum | NOTIFICATION, STK_PUSH |
| lockedPrice | decimal | Price locked at signup |
| gracePeriodEndDate | timestamp | Grace period end |

## Current Configuration Status
- ✅ Stripe checkout integration
- ✅ M-Pesa (IntaSend) payment support
- ✅ Webhook handling for subscription events
- ✅ Feature gating by tier
- ✅ Worker limit enforcement
- ✅ Auto-renewal with STK push
- ✅ Subscription payment history
- ✅ Usage statistics tracking
- ✅ Grace period management

## Known Gaps
| Gap | Status |
|-----|--------|
| Cancel Subscription UI | ✅ Completed |
| Proration handling | ⚠️ Partial |
| Multi-currency support | ⚠️ USD/KES only |
