# Time Tracking Feature

## Overview
Clock in/out time tracking for hourly workers with location support.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/time-tracking` | Get time entries |
| POST | `/time-tracking/clock-in` | Clock in worker |
| POST | `/time-tracking/clock-out` | Clock out worker |
| GET | `/time-tracking/summary` | Get hours summary |

## Time Entry Model
```json
{
  "workerId": "uuid",
  "clockIn": "2024-01-15T08:00:00Z",
  "clockOut": "2024-01-15T17:00:00Z",
  "clockInLatitude": -1.2921,
  "clockInLongitude": 36.8219,
  "totalHours": 9.0
}
```

## Mobile UI
- **Time Tracking**: `mobile/lib/features/time_tracking/presentation/pages/`
- **Attendance Dashboard**: View attendance records

## Database Entities
- `TimeEntry` - `backend/src/modules/time-tracking/entities/`

## Current Configuration Status
- ✅ Clock in/out
- ✅ Location capture
- ✅ Hours calculation
- ✅ Integration with payroll (hourly workers)

## Known Gaps
| Gap | Status |
|-----|--------|
| Upgrade screen navigation | ⚠️ TODO in time_tracking_page.dart |
