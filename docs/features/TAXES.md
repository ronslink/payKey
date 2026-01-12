# Taxes Feature

## Overview
Kenya tax management including PAYE, SHIF, NSSF, Housing Levy calculation, filing and submissions.

## Tax Types

| Tax | Rate | Description |
|-----|------|-------------|
| PAYE | Progressive | Pay As You Earn (income tax) |
| SHIF | 2.75% of gross | Social Health Insurance Fund |
| NSSF | Tiered | National Social Security Fund |
| Housing Levy | 1.5% | Affordable Housing Levy |

## PAYE Tax Brackets (Kenya 2024)
| Monthly Income | Rate |
|---------------|------|
| 0 - 24,000 | 10% |
| 24,001 - 32,333 | 25% |
| 32,334 - 500,000 | 30% |
| 500,001 - 800,000 | 32.5% |
| Above 800,000 | 35% |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taxes/config` | Get tax configuration |
| GET | `/taxes/submissions` | Get tax submissions |
| POST | `/taxes/submit` | Submit tax filing |
| GET | `/taxes/summary/:year` | Get annual summary |

## Mobile UI
- **Tax Dashboard**: `mobile/lib/features/taxes/presentation/pages/`
- **P10 Reports**: Download annual tax summary

## Database Entities
- `TaxConfig` - `backend/src/modules/tax-config/entities/`
- `TaxSubmission` - `backend/src/modules/taxes/entities/`
- `TaxPayment` - `backend/src/modules/tax-payments/entities/`

## Current Configuration Status
- ✅ Automatic tax calculation on payroll
- ✅ Tax submissions tracking
- ✅ P10 report generation
- ✅ Kenya 2024 tax tables

## Known Gaps
| Gap | Status |
|-----|--------|
| Aggregate from payroll transactions | ⚠️ TODO in taxes.service.ts |
| Housing Levy config | ⚠️ Hardcoded in some places |
