# Reports Feature

## Overview
Business reports including payroll summaries, P10 tax reports, muster rolls, and worker exports.

## Available Reports

### Payroll Reports
| Report | Description | Format | Tier |
|--------|-------------|--------|------|
| Payroll Summary | Monthly/period payroll totals | Screen | BASIC+ |
| Payroll Details | Per-worker breakdown | Screen | BASIC+ |
| Payment History | All payments made | Screen | BASIC+ |

### Tax Reports
| Report | Description | Format | Tier |
|--------|-------------|--------|------|
| P10 Report | Annual employer tax return | CSV | GOLD+ |
| Tax Summary | Monthly tax deductions | Screen | BASIC+ |
| PAYE Breakdown | Per-worker PAYE details | Screen | GOLD+ |

### HR Reports
| Report | Description | Format | Tier |
|--------|-------------|--------|------|
| Muster Roll | Employee attendance/roster | CSV | GOLD+ |
| Worker List | All workers export | CSV | BASIC+ |
| Termination Report | Terminated workers | Screen | BASIC+ |
| Leave Report | Leave taken summary | Screen | PLATINUM |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/reports/payroll-summary` | Payroll summary |
| GET | `/reports/p10/:year` | P10 tax report |
| GET | `/reports/muster-roll` | Muster roll download |
| GET | `/export/workers` | Export workers |
| GET | `/reports/tax-summary/:period` | Tax summary |

## Mobile UI
- **Reports Hub**: `mobile/lib/features/reports/presentation/pages/reports_page.dart`
- Download buttons for exportable reports

## Export Formats
- **CSV** - Data exports (workers, muster roll)
- **PDF** - Formal reports (planned)
- **Excel** - Advanced exports (planned)

## Current Configuration Status
- ✅ Payroll summary generation
- ✅ P10 report download (CSV)
- ✅ Muster roll CSV
- ✅ Worker list export
- ✅ Tier-based access

## Known Gaps
| Gap | Status |
|-----|--------|
| Fetch from config | ⚠️ TODO in reports.service.ts |
| PDF generation | ❌ Not implemented |
| Scheduled reports | ❌ Not implemented |
| Email reports | ❌ Not implemented |
