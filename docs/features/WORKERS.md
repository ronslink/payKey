# Workers Feature

## Overview
Complete worker (employee) management including CRUD operations, termination workflow, and leave management.

## API Endpoints

### Worker CRUD
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workers` | List all workers |
| POST | `/workers` | Create worker |
| GET | `/workers/:id` | Get worker details |
| PATCH | `/workers/:id` | Update worker |
| DELETE | `/workers/:id` | Delete worker |
| GET | `/workers/stats` | Get worker statistics |

### Termination
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/workers/:id/calculate-final-payment` | Calculate final payment |
| POST | `/workers/:id/terminate` | Terminate worker |
| GET | `/workers/terminated/history` | Get termination history |

### Leave Management (Platinum tier)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/workers/leave-requests` | Get all leave requests |
| POST | `/workers/:id/leave-requests` | Create leave request |
| GET | `/workers/:id/leave-requests` | Get worker's leave requests |
| GET | `/workers/:id/leave-balance` | Get leave balance |
| PATCH | `/workers/leave-requests/:id/approve` | Approve leave request |
| DELETE | `/workers/leave-requests/:id` | Cancel leave request |

## Worker Model Fields
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+254700000000",
  "idNumber": "12345678",
  "employeeType": "FULL_TIME",
  "salaryType": "MONTHLY",
  "salaryGross": 50000,
  "hourlyRate": null,
  "hoursingAllowance": 5000,
  "transportAllowance": 3000,
  "propertyId": "uuid",
  "startDate": "2024-01-01",
  "status": "ACTIVE"
}
```

## Employment Types
- `FULL_TIME`, `PART_TIME`, `CONTRACT`, `CASUAL`

## Worker Statuses
- `ACTIVE`, `INACTIVE`, `TERMINATED`, `ON_LEAVE`

## Mobile UI
- **Worker List**: `mobile/lib/features/workers/presentation/pages/workers_page.dart`
- **Worker Form**: `mobile/lib/features/workers/presentation/pages/worker_form_page.dart`
- **Worker Detail**: `mobile/lib/features/workers/presentation/pages/worker_detail_page.dart`

## Database Entities
- `Worker` - `backend/src/modules/workers/entities/worker.entity.ts`
- `Termination` - `backend/src/modules/workers/entities/termination.entity.ts`
- `LeaveRequest` - `backend/src/modules/workers/entities/leave-request.entity.ts`

## Current Configuration Status
- ✅ Full CRUD operations
- ✅ Termination workflow with final payment calculation
- ✅ Leave management (Platinum tier)
- ✅ Property assignment
- ✅ Excel import (Gold tier)

## Known Gaps
| Gap | Status |
|-----|--------|
| Avatar/Photo Upload | ❌ Display works (initials), no upload |
| Document Attachments | ❌ Not implemented |
