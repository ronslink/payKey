# Leave Management Feature

## Overview
Employee leave requests, approvals, and balance tracking (Platinum tier).

## Leave Types
- `ANNUAL` - Annual leave
- `SICK` - Sick leave
- `MATERNITY` - Maternity leave
- `PATERNITY` - Paternity leave
- `COMPASSIONATE` - Compassionate leave
- `UNPAID` - Unpaid leave
- `EMERGENCY` - Emergency leave

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workers/leave-requests` | Get all leave requests |
| POST | `/workers/:id/leave-requests` | Create leave request |
| GET | `/workers/:id/leave-balance` | Get leave balance |
| PATCH | `/workers/leave-requests/:id/approve` | Approve request |
| DELETE | `/workers/leave-requests/:id` | Cancel request |

## Leave Request Statuses
`PENDING` → `APPROVED` / `REJECTED` → `COMPLETED` / `CANCELLED`

## Mobile UI
- **Leave Management**: `mobile/lib/features/leave_management/presentation/pages/`
- **Balance View**: Per-worker leave balances
- **Request Form**: Submit new requests

## Tier Restriction
- Requires PLATINUM tier
- Enforced by `PlatinumGuard`

## Database Entities
- `LeaveRequest` - `backend/src/modules/workers/entities/leave-request.entity.ts`

## Current Configuration Status
- ✅ Leave request workflow
- ✅ Approval/rejection flow
- ✅ Balance tracking
- ✅ Tier gating
