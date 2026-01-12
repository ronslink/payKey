# Feature Gating by Subscription Tier

## Overview
Features are gated by subscription tier. Guards enforce access control on both backend and mobile.

## Tier Feature Matrix

| Feature | FREE | BASIC | GOLD | PLATINUM |
|---------|------|-------|------|----------|
| **Workers** |
| Worker CRUD | 1 max | 5 max | 10 max | 15 max |
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
| Clock in/out | ❌ | ✅ | ✅ | ✅ |
| Attendance reports | ❌ | ❌ | ✅ | ✅ |

## Backend Guards

| Guard | Purpose | File |
|-------|---------|------|
| `SubscriptionGuard` | Validates active subscription | `subscription.guard.ts` |
| `TierGuard` | Validates minimum tier | `tier.guard.ts` |
| `ImportFeatureGuard` | Gold+ for imports | `import-feature.guard.ts` |
| `PlatinumGuard` | Platinum-only features | `platinum.guard.ts` |

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

## Known Gaps
| Gap | Status |
|-----|--------|
| Worker count injection | ⚠️ TODO: Inject WorkersService for validation |
| Get actual worker count | ⚠️ TODO in feature-access.controller.ts |
