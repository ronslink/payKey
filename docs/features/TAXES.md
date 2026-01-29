# Taxes Feature

## Overview
Kenya tax management including PAYE, SHIF, NSSF, Housing Levy calculation, filing, and government submissions.

## Tax Types

| Tax | Rate | Description |
|-----|------|-------------|
| PAYE | Progressive | Pay As You Earn (income tax) |
| SHIF | 2.75% of gross | Social Health Insurance Fund (replaced NHIF) |
| NSSF | Tiered | National Social Security Fund |
| Housing Levy | 1.5% employee + 1.5% employer | Affordable Housing Levy |

## PAYE Tax Brackets (Kenya 2024/2025)
| Monthly Income | Rate |
|---------------|------|
| 0 - 24,000 | 10% |
| 24,001 - 32,333 | 25% |
| 32,334 - 500,000 | 30% |
| 500,001 - 800,000 | 32.5% |
| Above 800,000 | 35% |

## API Endpoints

### Tax Configuration & Calculations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taxes/config` | Get tax configuration |
| GET | `/taxes/calculate` | Calculate taxes for a salary |
| POST | `/taxes/calculate-batch` | Calculate taxes for multiple workers |

### Tax Submissions & Filings
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taxes/submissions` | Get tax submissions |
| POST | `/taxes/submit` | Submit tax filing |
| GET | `/taxes/summary/:year` | Get annual summary |
| GET | `/taxes/p10/:year` | Generate P10 report |

### Tax Payments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tax-payments` | List tax payments |
| POST | `/tax-payments/pay` | Record tax payment |
| GET | `/tax-payments/:id` | Get payment details |

## Government Integrations

### KRA Integration
- iTax API for PAYE filings
- P10 report generation
- NSSF and SHIF returns verification

### NSSF Integration
- Employer portal submission
- Contribution tracking
- Returns filing

### SHIF Integration
- SHIF portal submission
- Contribution tracking
- Compliance reporting

## Mobile UI
- **Tax Dashboard**: `mobile/lib/features/taxes/presentation/pages/`
- **P10 Reports**: Download annual tax summary
- **Government Submissions**: `mobile/lib/features/gov_submissions/presentation/pages/`

## Database Entities
- `TaxConfig` - `backend/src/modules/tax-config/entities/`
- `TaxSubmission` - `backend/src/modules/taxes/entities/tax-submission.entity.ts`
- `TaxPayment` - `backend/src/modules/tax-payments/entities/tax-payment.entity.ts`
- `GovSubmission` - `backend/src/modules/gov-integrations/entities/gov-submission.entity.ts`

## Current Configuration Status
- ✅ Automatic tax calculation on payroll
- ✅ Tax submissions tracking
- ✅ P10 report generation
- ✅ Kenya 2024/2025 tax tables
- ✅ SHIF (new health fund) support
- ✅ Housing Levy calculation
- ✅ Government submission APIs

## Known Gaps
| Gap | Status |
|-----|--------|
| Aggregate from payroll transactions | ✅ Completed |
| Housing Levy config | ✅ Completed |
| Auto-submission to KRA | ⚠️ In development |
| NSSF portal integration | ⚠️ In development |
