# Payroll Feature

## Overview
Complete payroll processing including pay periods, worker payments, and approval workflow with automatic tax calculations.

## Pay Period Statuses
`DRAFT` → `OPEN` → `PROCESSING` → `COMPLETED` → `CLOSED`

## Pay Period Frequencies
- `WEEKLY`, `BIWEEKLY`, `MONTHLY`, `QUARTERLY`, `YEARLY`

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
| GET | `/pay-periods/:id/workers` | Get unprocessed workers |

### Payroll Processing
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payroll/run` | Run payroll for pay period |
| GET | `/payroll/records` | Get payroll records |
| GET | `/payroll/records/:id` | Get specific record |
| PATCH | `/payroll/records/:id` | Update payroll record |
| POST | `/payroll/records/:id/finalize` | Finalize record |
| POST | `/payroll/records/:id/pay` | Mark as paid |

## Payroll Calculation
Automatically calculates:
- Gross salary (fixed or hourly × hours)
- Overtime pay (holiday, Sunday, regular overtime)
- Bonuses and other earnings
- PAYE (Kenya tax brackets)
- SHIF (2.75% of gross)
- NSSF (Tiered rates)
- Housing Levy (1.5% employee + 1.5% employer)
- Other deductions
- Net pay

## PAYE Tax Brackets (Kenya 2024/2025)
| Monthly Income | Rate |
|---------------|------|
| 0 - 24,000 | 10% |
| 24,001 - 32,333 | 25% |
| 32,334 - 500,000 | 30% |
| 500,001 - 800,000 | 32.5% |
| Above 800,000 | 35% |

## Payroll Record Entity Fields
| Field | Type | Description |
|-------|------|-------------|
| id | uuid | Primary key |
| userId | uuid | Employer ID |
| workerId | uuid | Worker ID |
| payPeriodId | uuid | Pay period ID |
| grossSalary | decimal | Base salary |
| bonuses | decimal | Bonus amounts |
| otherEarnings | decimal | Other earnings |
| otherDeductions | decimal | Other deductions |
| holidayHours | decimal | Holiday hours worked |
| sundayHours | decimal | Sunday hours worked |
| overtimePay | decimal | Overtime pay |
| netSalary | decimal | Net pay after deductions |
| taxAmount | decimal | Total tax amount |
| status | enum | draft, finalized, paid |
| paymentStatus | string | pending, paid, failed, processing |
| paymentMethod | string | mpesa, bank, cash |
| paymentDate | timestamp | When payment was made |
| finalizedAt | timestamp | When finalized |
| taxBreakdown | json | Breakdown of taxes |
| deductions | json | Detailed deductions |

## Mobile UI
- **Pay Periods**: `mobile/lib/features/pay_periods/presentation/pages/`
- **Payroll**: `mobile/lib/features/payroll/presentation/pages/`
- **Payslips**: `mobile/lib/features/payroll/presentation/pages/payslip_page.dart`

## Database Entities
- `PayPeriod` - `backend/src/modules/payroll/entities/pay-period.entity.ts`
- `PayrollRecord` - `backend/src/modules/payroll/entities/payroll-record.entity.ts`

## Current Configuration Status
- ✅ Pay period CRUD with full workflow
- ✅ Payroll calculation with Kenya taxes 2024/2025
- ✅ Status workflow (DRAFT → OPEN → PROCESSING → COMPLETED → CLOSED)
- ✅ Payslip viewing
- ✅ Bulk payroll processing
- ✅ Overtime calculations
- ✅ Payment tracking

## Known Gaps
| Gap | Status |
|-----|--------|
| Payslip Download/PDF | ⚠️ Basic implementation |
| Bulk run for all workers | ✅ Completed |
| Bank transfer payments | ⚠️ In development |
