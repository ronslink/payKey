# Excel Import Feature

## Overview
Bulk worker import via Excel template (Gold tier and above).

## Template Format
Download template with columns:
| Column | Required | Description |
|--------|----------|-------------|
| Name | Yes | Worker full name |
| Email | No | Email address |
| Phone | Yes | Phone number |
| ID Number | Yes | National ID |
| Employee Type | Yes | FULL_TIME/PART_TIME/etc |
| Salary | Yes | Monthly salary |
| Start Date | Yes | Employment start |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/excel-import/template` | Download template |
| POST | `/excel-import/upload` | Upload and import |
| GET | `/workers/import/template` | Alternative endpoint |
| POST | `/workers/import` | Alternative upload |

## Import Flow
1. Download Excel template
2. Fill in worker data
3. Upload file
4. Backend validates data
5. Workers created in batch
6. Errors returned for invalid rows

## Tier Restriction
- Requires GOLD tier or higher
- Enforced by `ImportFeatureGuard`

## Mobile UI
- **Import Page**: `mobile/lib/features/workers/presentation/pages/`
- Download template button
- Upload file picker

## Current Configuration Status
- ✅ Template download working
- ✅ Excel parsing (xlsx)
- ✅ Batch worker creation
- ✅ Tier gating enforced

## Known Gaps
| Gap | Status |
|-----|--------|
| Progress indicator for large files | ⚠️ Basic implementation |
| Duplicate detection | ⚠️ By ID number only |
