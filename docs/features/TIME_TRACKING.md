# Time Tracking Feature

## Overview

Geofenced attendance plus employer-recorded hours for hourly workers.

The employee is the only one who can start or stop a clock. Attendance is
evidence of where somebody was, so it has to come from the device that is
actually on site; an employer records hours they know about as a time entry
instead. Nothing typed in by hand (or guessed when a shift was auto-closed)
reaches payroll until the employer decides to include it.

## API Endpoints

| Method | Endpoint | Who | Description |
|--------|----------|-----|-------------|
| POST | `/time-tracking/clock-in/:workerId` | Employee only | Start the employee's own clock (geofenced) |
| POST | `/time-tracking/clock-out/:workerId` | Employee only | Stop the employee's own clock |
| POST | `/time-tracking/auto-clock-out/:workerId` | Employee's device | Auto clock-out after leaving the geofence |
| GET | `/time-tracking/status/:workerId` | Both | Whether the worker is on the clock |
| GET | `/time-tracking/live-status` | Employer | Who is on the clock right now |
| GET | `/time-tracking/entries` | Employer | All entries in a range |
| GET | `/time-tracking/entries/:workerId` | Both | One worker's entries in a range |
| GET | `/time-tracking/summary` | Employer | Hours grouped by worker |
| POST | `/time-tracking/entries` | Employer only | Record hours (`clockIn` and `clockOut` required) |
| PATCH | `/time-tracking/adjust/:entryId` | Employer only | Correct an entry (needs a reason) |
| GET | `/time-tracking/payroll-review` | Employer only | Hours by source plus what awaits a decision |
| POST | `/time-tracking/payroll-review/decision` | Employer only | Include or exclude entries from payroll |

## Time Entry Model

```json
{
  "workerId": "uuid",
  "clockIn": "2024-01-15T08:00:00Z",
  "clockOut": "2024-01-15T17:00:00Z",
  "clockInLat": -1.2921,
  "clockInLng": 36.8219,
  "totalHours": 9.0,
  "source": "CLOCK",
  "payrollDecision": "INCLUDED"
}
```

- `source`: `CLOCK` for the employee's own clock-in, `ENTERED` for hours typed in
  by the employer.
- `payrollDecision`: `INCLUDED` (paid), `PENDING` (not paid yet) or `EXCLUDED`.
  Clocked entries are included on creation; employer-entered entries start
  `PENDING`, and any correction returns an entry to `PENDING`.

## Geofencing

A property's geofence measures from its pin (`latitude`/`longitude`) with a
radius in metres (10–5000). Without a pin the property cannot be geofenced and
every clock-in is accepted regardless of location.

Employers set the pin from the mobile property form by capturing their current
location at the site, resolving a what3words address (needs `W3W_API_KEY`
server-side), or typing the coordinates. `GET /property-location/what3words`
and `GET /property-location/words` perform the what3words lookups; without a key
they answer 503 so the app falls back to GPS or manual coordinates.

## Payroll

`payroll.service.ts` sums only entries whose `payrollDecision` is `INCLUDED`
(and whose status is `COMPLETED` or `ADJUSTED`). The run-payroll screen shows
what is payable and warns about hours awaiting a decision, and the worker
timesheet shows each entry's state and lets the employer change it.

## Stale shifts

Shifts left open longer than `TIME_TRACKING_MAX_SHIFT_HOURS` (default 12) are
capped at that length by an hourly job, marked `COMPLETED`, flagged with an
`adjustmentReason` and returned to `PENDING` for review. They are not cancelled:
the employee did start work, so payroll sees capped hours rather than nothing.

## Mobile UI

- **Time Tracking** (employer): overview plus the Enter Time tab —
  `mobile/lib/features/time_tracking/presentation/pages/`
- **Attendance Dashboard** (employer): live status with a Record Time action
- **Employee portal**: self clock-in/out and a read-only timesheet
- Shared sheets for recording, correcting and deciding hours:
  `mobile/lib/features/time_tracking/presentation/widgets/time_entry_sheets.dart`

## Database Entities

- `TimeEntry` — `backend/src/modules/time-tracking/entities/`
- `Property` (geofence pin) — `backend/src/modules/properties/entities/`

## Current Configuration Status

- ✅ Employee-only clock in/out, geofenced against the property pin
- ✅ Employer time entry and corrections, both audited
- ✅ Payroll include/exclude decision per entry, decided by whom and when
- ✅ Auto-close for forgotten clock-outs
- ✅ what3words and GPS pin capture for property setup
