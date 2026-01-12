# Payroll Feature

## Overview
Complete payroll processing including pay periods, worker payments, and approval workflow.

## API Endpoints

### Pay Periods
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/pay-periods` | List all pay periods |
| POST | `/pay-periods` | Create pay period |
| GET | `/pay-periods/:id` | Get pay period details |
| PATCH | `/pay-periods/:id` | Update pay period |
| DELETE | `/pay-periods/:id` | Delete pay period |
| POST | `/pay-periods/:id/activate` | Activate pay period |
| POST | `/pay-periods/:id/process` | Process pay period |
| POST | `/pay-periods/:id/complete` | Complete pay period |
| POST | `/pay-periods/:id/close` | Close pay period |
| GET | `/pay-periods/:id/statistics` | Get statistics |

### Payroll Processing
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payroll/run` | Run payroll for pay period |
| GET | `/payroll/records` | Get payroll records |
| GET | `/payroll/records/:id` | Get specific record |

## Pay Period Statuses
`DRAFT` → `OPEN` → `PROCESSING` → `COMPLETED` → `CLOSED`

## Pay Period Frequencies
- `WEEKLY`, `BIWEEKLY`, `MONTHLY`, `QUARTERLY`, `YEARLY`

## Payroll Calculation
Automatically calculates:
- Gross salary (fixed or hourly × hours)
- PAYE (Kenya tax brackets)
- SHIF (Social Health Insurance Fund)
- NSSF (National Social Security Fund)
- Housing Levy
- Net pay

## Mobile UI
- **Pay Periods**: `mobile/lib/features/pay_periods/presentation/pages/`
- **Payroll**: `mobile/lib/features/payroll/presentation/pages/`
- **Payslips**: `mobile/lib/features/payroll/presentation/pages/payslip_page.dart`

## Database Entities
- `PayPeriod` - `backend/src/modules/payroll/entities/pay-period.entity.ts`
- `PayrollRecord` - `backend/src/modules/payroll/entities/payroll-record.entity.ts`

## Current Configuration Status
- ✅ Pay period CRUD
- ✅ Payroll calculation with Kenya taxes
- ✅ Status workflow
- ✅ Payslip viewing

## Known Gaps
| Gap | Status |
|-----|--------|
| Payslip Download/PDF | ❌ Coming soon message |
| Bulk run for all workers | ⚠️ Needs testing |
