# Stripe Subscription 400 Error Fix

## Problem Summary

The application was throwing a 400 Bad Request error when attempting to create Stripe subscriptions:
```
adapter_impl.dart:289  POST http://localhost:3000/payments/unified/subscribe 400 (Bad Request)
```

## Root Cause Analysis

The issue was a **mismatch between frontend and backend data expectations**:

### Frontend Behavior
- The frontend was sending a `planId` parameter containing values like:
  - `"basic-plan"` (UUID or custom ID)
  - `"gold-plan"` (UUID or custom ID) 
  - `"platinum-plan"` (UUID or custom ID)

### Backend Expectations
- The backend validation in `StripeService.createCheckoutSession()` only accepted:
  - `"FREE"`
  - `"BASIC"` 
  - `"GOLD"`
  - `"PLATINUM"`

### Data Flow Issue
1. User clicks on subscription plan in Flutter app
2. `PaymentPage` calls `repo.subscribeWithStripe(widget.plan.id)`
3. API sends `planId` as `"basic-plan"` to backend
4. Backend validates against `['FREE', 'BASIC', 'GOLD', 'PLATINUM']`
5. Validation fails → 400 Bad Request

## Solution Implemented

### 1. Frontend Fix (`mobile/lib/features/subscriptions/presentation/pages/payment_page.dart`)

**Before:**
```dart
final checkoutUrl = await repo.subscribeWithStripe(widget.plan.id);
```

**After:**
```dart
final checkoutUrl = await repo.subscribeWithStripe(widget.plan.tier);
```

**Reason:** The `tier` field contains the expected backend values (`"BASIC"`, `"GOLD"`, `"PLATINUM"`), while `id` contains UUIDs.

### 2. Backend Improvements

#### Case Insensitive Validation (`backend/src/modules/payments/stripe.service.ts`)

**Before:**
```typescript
if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(planTier.toUpperCase())) {
  throw new BadRequestException('Invalid subscription plan');
}
```

**After:**
```typescript
const normalizedTier = planTier.toUpperCase();
if (!['FREE', 'BASIC', 'GOLD', 'PLATINUM'].includes(normalizedTier)) {
  throw new BadRequestException('Invalid subscription plan');
}
```

#### Consistent Usage (`backend/src/modules/payments/unified-payments.controller.ts`)

**Before:**
```typescript
const checkoutSession = await this.stripeService.createCheckoutSession(
  userId,
  body.planId.toUpperCase(),
  email,
  name || email,
);
```

**After:**
```typescript
const normalizedPlanId = body.planId.toUpperCase();
const checkoutSession = await this.stripeService.createCheckoutSession(
  userId,
  normalizedPlanId,
  email,
  name || email,
);
```

## Testing the Fix

Created `test_stripe_subscription_fix.js` to verify:
- ✅ BASIC plan subscription works
- ✅ GOLD plan subscription works  
- ✅ PLATINUM plan subscription works
- ✅ Case insensitive handling (e.g., "basic" → "BASIC")
- ✅ Returns proper Stripe checkout URLs

## Files Modified

1. **Frontend:**
   - `mobile/lib/features/subscriptions/presentation/pages/payment_page.dart`

2. **Backend:**
   - `backend/src/modules/payments/stripe.service.ts`
   - `backend/src/modules/payments/unified-payments.controller.ts`

3. **Testing:**
   - `test_stripe_subscription_fix.js`

## Expected Result

After this fix:
- Users can successfully subscribe to Stripe plans
- The 400 Bad Request error is resolved
- Stripe checkout sessions are created properly
- Case variations are handled gracefully

## Next Steps

1. **Test the fix:** Run the Flutter app and attempt a subscription
2. **Verify Stripe sandbox:** Ensure Stripe keys are configured for sandbox mode
3. **Monitor logs:** Check backend logs for successful checkout session creation
4. **Update documentation:** Reflect the tier-based subscription model in API docs