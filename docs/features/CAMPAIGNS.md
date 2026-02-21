# Campaigns & Promotional Items

## Overview

The Campaigns system allows admins to create targeted marketing and engagement campaigns that are automatically delivered to employers through the PayDome mobile app and notification channels. Campaigns are tightly coupled to **Promotional Items** (the actual offers) and the **Notifications system** (the delivery mechanism).

---

## Concepts

### Promotional Item
A **Promotional Item** is the *offer* itself — a discount, free trial, feature unlock, or account credit. It defines the reward.

| Field | Description |
|---|---|
| `type` | DISCOUNT, FREE_TRIAL, FEATURE_UNLOCK, CREDIT |
| `discountPercentage` | e.g. `20` for 20% off |
| `discountAmount` | Fixed amount discount in USD |
| `freeTrialDays` | Days of free trial |
| `maxUses` / `currentUses` | Usage cap tracking |
| `validFrom` / `validUntil` | Offer validity window |
| `applicableTiers` | Which subscription tiers can redeem |

### Campaign
A **Campaign** is the *vehicle* that delivers a promotional item (or a standalone message) to users. It controls who sees it, when they see it, and how it is delivered.

| Field | Description |
|---|---|
| `type` | How it is delivered (see Campaign Types below) |
| `status` | Lifecycle state (see Campaign Lifecycle below) |
| `title` + `message` | The content shown to the user |
| `callToAction` + `callToActionUrl` | CTA button label and destination |
| `targetAudience.tiers` | Which subscription tiers receive this campaign |
| `scheduledFrom` / `scheduledUntil` | Active delivery window |
| `priority` | 1–100; higher = shown first when multiple campaigns are active |
| `promotionalItemId` | Optional link to the associated offer |
| `displaySettings` | Position, dismissibility, auto-hide, page restrictions |
| `lastDispatchedAt` | Timestamp of last dispatch run (NULL = never sent) |
| `lastDispatchCount` | Number of recipients reached on last dispatch |
| `impressions` / `clicks` / `conversions` | Analytics counters |

---

## Campaign Types

| Type | Delivery Mechanism | Who triggers it |
|---|---|---|
| `EMAIL` | SendGrid email to each matching employer | `CampaignScheduler` (server-side, automatic) |
| `IN_APP_NOTIFICATION` | Firebase FCM push to each device token | `CampaignScheduler` (server-side, automatic) |
| `BANNER` | In-app banner rendered by Flutter app | Mobile app polls `GET /subscriptions/campaigns/active` |
| `POPUP` | In-app modal rendered by Flutter app | Mobile app polls `GET /subscriptions/campaigns/active` |
| `SIDEBAR` | Sidebar widget rendered by Flutter app | Mobile app polls `GET /subscriptions/campaigns/active` |

**Key distinction:**
- `EMAIL` and `IN_APP_NOTIFICATION` are **push** — the server sends them once automatically.
- `BANNER`, `POPUP`, `SIDEBAR` are **pull** — the mobile app fetches them on demand and renders them.

---

## Campaign Lifecycle

```
DRAFT → SCHEDULED → ACTIVE → PAUSED → COMPLETED
                           ↘ CANCELLED
```

| Status | Meaning |
|---|---|
| `DRAFT` | Being composed, not visible anywhere |
| `SCHEDULED` | Ready, waiting for `scheduledFrom` date to arrive |
| `ACTIVE` | Live — scheduler will dispatch it; mobile app will serve it |
| `PAUSED` | Temporarily halted; will not dispatch or display |
| `COMPLETED` | Manually marked done |
| `CANCELLED` | Abandoned |

Status transitions available from the admin console:
- **DRAFT → ACTIVE** via "Activate" button
- **ACTIVE → PAUSED** via "Pause" button
- **PAUSED → ACTIVE** via "Resume" button

---

## Delivery Architecture — End to End

### Server-Dispatched Campaigns (EMAIL, IN_APP_NOTIFICATION)

```
Admin creates campaign in admin console
         ↓
Sets type = EMAIL, targetAudience.tiers = ["FREE", "BASIC"]
scheduledFrom = go-live date, status = ACTIVE
         ↓
CampaignScheduler fires every 15 minutes
         ↓
Finds campaigns WHERE:
  - status = ACTIVE
  - type IN (EMAIL, IN_APP_NOTIFICATION)
  - scheduledFrom <= NOW (or NULL)
  - scheduledUntil >= NOW (or NULL)
  - lastDispatchedAt IS NULL  ← "never sent" guard
         ↓
Resolves target users:
  - Queries users table WHERE role IN (EMPLOYER, USER)
    AND tier IN targetAudience.tiers
  - If no tiers set → sends to ALL employers
         ↓
EMAIL: sends via NotificationsService → SendGrid
PUSH:  looks up device_tokens table → sends via Firebase FCM
         ↓
Stamps lastDispatchedAt = NOW, lastDispatchCount = N
Increments campaign.impressions by N
         ↓
Next scheduler tick: lastDispatchedAt IS NOT NULL → skipped ✓
```

> **Important:** Each campaign is dispatched **exactly once**. `lastDispatchedAt` is the idempotency guard.
> If you need to re-send a campaign (e.g. after adding new users), reset `lastDispatchedAt` to `NULL` in the database.

### Mobile Pull Campaigns (BANNER, POPUP, SIDEBAR)

```
Employer opens Flutter app / navigates to dashboard
         ↓
App calls: GET /subscriptions/campaigns/active
         ↓
Backend filters campaigns:
  - status = ACTIVE
  - type IN (BANNER, POPUP, SIDEBAR)
  - scheduledFrom <= NOW (or NULL)
  - scheduledUntil >= NOW (or NULL)
  - Matched to calling user's subscription tier
  - Ordered by priority DESC
         ↓
App renders highest-priority campaign
Calls POST /subscriptions/campaigns/:id/impression
         ↓
Employer taps CTA → navigates to callToActionUrl
Calls POST /subscriptions/campaigns/:id/click
         ↓
Employer completes upgrade / redeems offer
Calls POST /subscriptions/campaigns/:id/conversion
```

---

## API Endpoints

### Admin Endpoints (require ADMIN or SUPER_ADMIN role)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/subscription-plans/campaigns` | List all campaigns |
| `GET` | `/api/admin/subscription-plans/campaigns/:id` | Get campaign details |
| `GET` | `/api/admin/subscription-plans/campaigns/active` | Get currently active campaigns (admin view) |
| `POST` | `/api/admin/subscription-plans/campaigns` | Create campaign |
| `PUT` | `/api/admin/subscription-plans/campaigns/:id` | Update campaign |
| `PUT` | `/api/admin/subscription-plans/campaigns/:id/status` | Update campaign status |
| `DELETE` | `/api/admin/subscription-plans/campaigns/:id` | Delete campaign |
| `POST` | `/api/admin/subscription-plans/campaigns/:id/impression` | Track impression |
| `POST` | `/api/admin/subscription-plans/campaigns/:id/click` | Track click |
| `POST` | `/api/admin/subscription-plans/campaigns/:id/conversion` | Track conversion |

### Promotional Items (require ADMIN or SUPER_ADMIN role)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/subscription-plans/promotional-items` | List all promotional items |
| `GET` | `/api/admin/subscription-plans/promotional-items/:id` | Get promotional item |
| `POST` | `/api/admin/subscription-plans/promotional-items` | Create promotional item |
| `PUT` | `/api/admin/subscription-plans/promotional-items/:id` | Update promotional item |
| `DELETE` | `/api/admin/subscription-plans/promotional-items/:id` | Delete promotional item |

### Mobile / User Endpoints (require valid JWT)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/subscriptions/campaigns/active` | Get active campaigns for calling user's tier |

---

## Campaign Scheduler

**File:** `backend/src/modules/subscriptions/campaign.scheduler.ts`

**Cron schedule:** Every 15 minutes — `0 */15 * * * *`

**Behaviour:**
- Only dispatches `EMAIL` and `IN_APP_NOTIFICATION` types
- Uses `lastDispatchedAt IS NULL` as the idempotency guard (one send per campaign)
- Handles stale FCM tokens: automatically marks tokens as `isActive = false` when Firebase returns `registration-token-not-registered` or `invalid-registration-token`
- Runs sends in parallel using `Promise.allSettled` — individual failures do not abort the batch

**Configuration:** No additional environment variables required beyond the existing notification provider config (see [NOTIFICATIONS.md](./NOTIFICATIONS.md)).

---

## Analytics

Each campaign tracks three counters:

| Counter | Incremented by |
|---|---|
| `impressions` | `CampaignScheduler` after dispatch (count = recipients reached); or `POST /campaigns/:id/impression` from mobile |
| `clicks` | Mobile app on CTA button tap via `POST /campaigns/:id/click` |
| `conversions` | Mobile app after successful upgrade/redemption via `POST /campaigns/:id/conversion` |

Derived metrics visible in the admin console:
- **CTR (Click-through rate)** = `clicks / impressions × 100`
- **CVR (Conversion rate)** = `conversions / clicks × 100`

---

## Database Schema

### `campaigns` table

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | varchar(255) | Internal identifier |
| `description` | text | Optional description |
| `type` | enum | BANNER, POPUP, EMAIL, IN_APP_NOTIFICATION, SIDEBAR |
| `status` | enum | DRAFT, SCHEDULED, ACTIVE, PAUSED, COMPLETED, CANCELLED |
| `title` | varchar(255) | Display title |
| `message` | text | Display body |
| `callToAction` | text | CTA button label |
| `callToActionUrl` | text | CTA destination URL |
| `imageUrl` | text | Optional image |
| `targetAudience` | JSON | `{ tiers?: string[], userSegments?: string[], countries?: string[] }` |
| `scheduledFrom` | timestamptz | Campaign start (null = immediate) |
| `scheduledUntil` | timestamptz | Campaign end (null = no end) |
| `priority` | int | 1–100, higher = more prominent |
| `impressions` | int | Total impressions tracked |
| `clicks` | int | Total clicks tracked |
| `conversions` | int | Total conversions tracked |
| `promotionalItemId` | UUID | FK → `promotional_items.id` (SET NULL on delete) |
| `displaySettings` | JSON | `{ position?, dismissible?, autoHideAfter?, showOnPages? }` |
| `lastDispatchedAt` | timestamptz | NULL = never dispatched; set by CampaignScheduler |
| `lastDispatchCount` | int | Recipients reached on last dispatch |
| `createdAt` | timestamptz | Auto-set |
| `updatedAt` | timestamptz | Auto-set |

**Indexes:**
- `IDX_CAMPAIGNS_STATUS` on `status`
- `IDX_CAMPAIGNS_SCHEDULE` on `(scheduledFrom, scheduledUntil)`
- `IDX_CAMPAIGNS_PRIORITY` on `priority`
- `IDX_CAMPAIGNS_LAST_DISPATCHED_AT` on `lastDispatchedAt`

### `promotional_items` table

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | varchar(255) | |
| `description` | text | |
| `type` | enum | DISCOUNT, FREE_TRIAL, FEATURE_UNLOCK, CREDIT |
| `status` | enum | DRAFT, ACTIVE, PAUSED, EXPIRED |
| `discountPercentage` | decimal(10,2) | |
| `discountAmount` | decimal(10,2) | |
| `freeTrialDays` | int | |
| `features` | JSON | Array of feature names for FEATURE_UNLOCK |
| `maxUses` | int | Null = unlimited |
| `currentUses` | int | Default 0 |
| `validFrom` | timestamptz | |
| `validUntil` | timestamptz | |
| `applicableTiers` | JSON | Array of tier strings |
| `promoCode` | varchar(50) | Unique human-readable code employers enter at checkout (e.g. `XMAS2025`). NULL = no redeemable code (banner-only promo). |
| `termsAndConditions` | text | |
| `createdAt` | timestamptz | |
| `updatedAt` | timestamptz | |

---

## Promo Code Redemption

Promotional items with a `promoCode` set can be redeemed directly at subscription checkout. This is the full-redemption flow (Option C) — the discount is applied to the payment amount before the employer is charged.

### How It Works

```
Employer sees campaign (EMAIL / BANNER / POPUP)
        ↓
Employer taps "Upgrade Now" → navigates to checkout in Flutter app
        ↓
Employer enters promo code (e.g. "XMAS2025")
        ↓
App calls POST /subscriptions/validate-promo
    { promoCode: "XMAS2025", planId: "GOLD", billingPeriod: "monthly" }
        ↓
Backend validates:
    ✓ Code exists + status = ACTIVE
    ✓ validFrom ≤ now ≤ validUntil
    ✓ currentUses < maxUses (if capped)
    ✓ plan tier is in applicableTiers (if set)
        ↓
Returns: { valid: true, discountType, discountValue, originalAmount, discountedAmount, savings }
        ↓
App shows discounted price preview to employer
        ↓
Employer confirms → calls POST /subscriptions/mpesa-subscribe (or /subscribe)
    { planId, phoneNumber, billingPeriod, promoCode: "XMAS2025" }
        ↓
Backend re-validates + applies discount to amountToCharge
Increments promotional_items.currentUses by 1
Saves appliedPromoId + promoDiscountAmount on Subscription
Saves promoCodeUsed + promoDiscountAmount on SubscriptionPayment (audit record)
        ↓
Payment proceeds at discounted price
```

### Validation Rules

| Rule | Behaviour on failure |
|---|---|
| Code not found | `{ valid: false, error: "Promo code not found" }` |
| Status ≠ ACTIVE | `{ valid: false, error: "Promo code is not active" }` |
| Before `validFrom` | `{ valid: false, error: "Promo code is not yet valid" }` |
| After `validUntil` | `{ valid: false, error: "Promo code has expired" }` |
| `currentUses >= maxUses` | `{ valid: false, error: "Promo code usage limit reached" }` |
| Tier not eligible | `{ valid: false, error: "Promo code is not applicable to your subscription tier" }` |

### Discount Calculation

- **Percentage**: `savings = round(originalAmount × discountPercentage / 100)`
- **Fixed**: `savings = min(discountAmount, originalAmount)` (never makes it negative)
- `discountedAmount = max(0, originalAmount − savings)`

### API Endpoints for Redemption

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/subscriptions/validate-promo` | Validate code + preview discount (no redemption yet) |
| `POST` | `/subscriptions/subscribe` | Stripe / Wallet / Bank checkout — accepts optional `promoCode` in body |
| `POST` | `/subscriptions/mpesa-subscribe` | M-Pesa STK push checkout — accepts optional `promoCode` in body |

### Audit Trail

Every payment with a promo code applied records:
- `subscription_payments.promoCodeUsed` — the code string (survives if promo is deleted)
- `subscription_payments.promoDiscountAmount` — KES saved
- `subscriptions.appliedPromoId` — FK to `promotional_items.id`
- `subscriptions.promoDiscountAmount` — KES saved on this subscription

---

## Annual Campaign Playbook

PayDome runs two recurring promotional campaigns each year:

### Christmas Campaign (December)

```
Promo Item:
  Name:              Christmas Upgrade Offer
  Type:              DISCOUNT
  Promo Code:        XMAS2025          ← update year each December
  Discount %:        20
  Status:            ACTIVE
  Valid From:        Dec 1
  Valid Until:       Dec 31
  Applicable Tiers:  FREE, BASIC
  Max Uses:          (leave null for unlimited)

Campaigns:
  1. Type: EMAIL   → CampaignScheduler auto-dispatches on Dec 1
  2. Type: BANNER  → Flutter app shows in-app banner all December
```

### Mid-Year Campaign (June)

```
Promo Item:
  Name:              Mid-Year Upgrade Offer
  Type:              DISCOUNT
  Promo Code:        MIDYEAR2025       ← update year each June
  Discount %:        15
  Status:            ACTIVE
  Valid From:        Jun 1
  Valid Until:       Jun 30
  Applicable Tiers:  FREE, BASIC
  Max Uses:          (leave null for unlimited)

Campaigns:
  1. Type: EMAIL   → CampaignScheduler auto-dispatches on Jun 1
  2. Type: BANNER  → Flutter app shows in-app banner all June
```

### Setup Checklist (run each campaign period)

1. **Create / update the Promo Item** with the new year's code (Admin → Promotions → Create Promo)
2. **Create the EMAIL Campaign** linked to the promo, set `scheduledFrom` = campaign start date, activate on the day
3. **Create the BANNER Campaign** (same content, different type) — activates automatically when date arrives
4. **Verify** `GET /subscriptions/campaigns/active` returns the banner for a test FREE account
5. **Monitor** `promotional_items.currentUses` via admin console to track redemptions

---

## Go-Live Campaign Playbook

### Step 1 — Create the Promotional Item

Go to: **Admin → Subscription Management → Promotions → Create Promo**

Example: Launch Month Upgrade Offer
```
Name:              Launch Month Upgrade Offer
Type:              DISCOUNT
Discount %:        20
Status:            ACTIVE
Valid From:        [go-live date]
Valid Until:       [go-live date + 30 days]
Applicable Tiers:  FREE, BASIC
Max Uses:          500
Terms:             Applies to first 3 months of Gold plan
```

### Step 2 — Create the Campaign

Go to: **Admin → Subscription Management → Campaigns → Create Campaign**

```
Name:              Go-Live — Upgrade to Gold
Type:              EMAIL          ← server will send automatically
Status:            SCHEDULED      ← change to ACTIVE on go-live day
Title:             🚀 We're live! Upgrade to Gold — 20% off
Message:           Unlock unlimited workers, payroll automation,
                   and full tax compliance tools. Offer valid for
                   the first month only.
Call to Action:    Upgrade Now
CTA URL:           /subscription/upgrade
Scheduled From:    [go-live date]
Scheduled Until:   [go-live date + 30 days]
Priority:          90
Target Tiers:      FREE, BASIC
Linked Promo:      Launch Month Upgrade Offer
```

### Step 3 — Activate on Go-Live Day

Change status to **ACTIVE**. Within 15 minutes the `CampaignScheduler` will dispatch emails to all FREE and BASIC employers.

### Step 4 — Create a BANNER version for the app

Duplicate the campaign with type **BANNER** — this one requires no scheduler and will appear automatically in the Flutter app for users on FREE or BASIC tiers.

---

## Supplementing with Manual Broadcasts

For immediate one-off sends (not automated), use:

**Admin → Notifications → Send Notification**

This sends directly via the existing notification pipeline (Email, SMS, or Push) to selected users or all employers. Useful for:
- Urgent announcements that can't wait for the scheduler tick
- SMS broadcasts (the campaign system does not support SMS type currently)
- Ad-hoc messages to specific users

---

## Related Files

| File | Purpose |
|---|---|
| `backend/src/modules/subscriptions/entities/campaign.entity.ts` | Campaign TypeORM entity |
| `backend/src/modules/subscriptions/entities/promotional-item.entity.ts` | PromotionalItem TypeORM entity (includes `promoCode`) |
| `backend/src/modules/subscriptions/entities/subscription.entity.ts` | Subscription entity (includes `appliedPromoId`, `promoDiscountAmount`) |
| `backend/src/modules/subscriptions/entities/subscription-payment.entity.ts` | SubscriptionPayment entity (includes `promoCodeUsed`, `promoDiscountAmount`) |
| `backend/src/modules/subscriptions/campaign.scheduler.ts` | CampaignScheduler cron service |
| `backend/src/modules/admin/admin-subscriptions.controller.ts` | Admin CRUD endpoints for campaigns and promos |
| `backend/src/modules/subscriptions/subscriptions.controller.ts` | User-facing endpoints: `GET /campaigns/active`, `POST /validate-promo`, `POST /subscribe`, `POST /mpesa-subscribe` |
| `backend/src/migrations/add-promotional-items-and-campaigns.ts` | Initial schema migration |
| `backend/src/migrations/1771700000000-AddCampaignDispatchFields.ts` | Dispatch tracking columns migration |
| `backend/src/migrations/1771800000000-AddPromoCodeRedemption.ts` | Promo code redemption fields migration |
| `admin/src/pages/SubscriptionPlansPage.tsx` | Admin UI — Campaigns and Promotions management |
| `mobile/lib/` | Flutter app — consumes `GET /subscriptions/campaigns/active` and promo validation |

## Related Documentation

- [NOTIFICATIONS.md](./NOTIFICATIONS.md) — notification channels (email, SMS, push) and configuration
- [SUBSCRIPTIONS.md](./SUBSCRIPTIONS.md) — subscription tiers, billing, and lifecycle
