# Feature Gating by Subscription Tier

## Overview
Features are gated by subscription tier. Guards enforce access control on both backend and mobile.

## Tier Feature Matrix

| Feature | FREE | BASIC | GOLD | PLATINUM |
|---------|------|-------|------|----------|
| **Workers** |
| Worker CRUD | 1 max | 5 max | 10 max | 20 max |
| Worker termination | ✅ | ✅ | ✅ | ✅ |
| **Payroll** |
| Basic payroll | ✅ | ✅ | ✅ | ✅ |
| Payslip viewing | ✅ | ✅ | ✅ | ✅ |
| **Payments** |
| M-Pesa payments | ❌ | ✅ | ✅ | ✅ |
| Bulk payments | ❌ | ❌ | ✅ | ✅ |
| **Imports/Exports** |
| Excel import | ❌ | ❌ | ✅ | ✅ |
| P10 report | ❌ | ❌ | ✅ | ✅ |
| Muster roll | ❌ | ❌ | ✅ | ✅ |
| **Leave Management** |
| Leave requests | ❌ | ❌ | ❌ | ✅ |
| Leave approvals | ❌ | ❌ | ❌ | ✅ |
| Leave balance | ❌ | ❌ | ❌ | ✅ |
| **Time Tracking** |
| Clock in/out | ❌ | ❌ | ❌ | ✅ |
| Attendance reports | ❌ | ❌ | ❌ | ✅ |

## Backend Guards

| Guard | Purpose | File |
|-------|---------|------|
| `SubscriptionGuard` | Refreshes user subscription data before guarded actions | `subscription.guard.ts` |
| `TierGuard` | Validates minimum tier for explicit tier routes | `common/guards/tier.guard.ts` |
| `ImportFeatureGuard` | GOLD+ for imports | `import-feature.guard.ts` |
| `PlatinumGuard` | PLATINUM-only features | `auth/platinum.guard.ts` |

## Usage in Controllers

```typescript
@Post()
@UseGuards(JwtAuthGuard, SubscriptionGuard)  // Any paid tier
createWorker() { ... }

@Get('leave-requests')
@UseGuards(JwtAuthGuard, SubscriptionGuard, PlatinumGuard)  // Platinum only
getLeaveRequests() { ... }

@Post('import')
@UseGuards(JwtAuthGuard, ImportFeatureGuard)  // Gold+
importWorkers() { ... }
```

## Mobile Implementation
Feature checks in `FeatureAccessService`:
- `canAccessFeature(userId, featureName)`
- Returns boolean based on user's current tier

## Configuration
Feature definitions in:
- `backend/src/modules/subscriptions/feature-access.config.ts`

## Current Enforcement Notes
The `/features` summary uses the active subscription tier, falls back to `users.tier`, and includes the live active worker count. The mobile app refreshes this summary after subscription payment or plan changes so gated screens and worker limits update with the new tier.
