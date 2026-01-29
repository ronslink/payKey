# Government Integrations Feature

## Overview
Integration with Kenya government APIs for tax and statutory compliance filings including KRA (Kenya Revenue Authority), NSSF (National Social Security Fund), and SHIF (Social Health Insurance Fund).

## Supported Integrations

### KRA Integration
- **Service**: `KraService` - `backend/src/modules/gov-integrations/services/kra.service.ts`
- **Features**:
  - iTax API authentication
  - PAYE filing submissions
  - P10 report generation
  - NSSF and SHIF returns verification
  - Tax compliance status checks

### NSSF Integration
- **Service**: `NssfService` - `backend/src/modules/gov-integrations/services/nssf.service.ts`
- **Features**:
  - Employer portal authentication
  - Monthly contribution submissions
  - Member registration
  - Returns filing
  - Contribution history retrieval

### SHIF Integration
- **Service**: `ShifService` - `backend/src/modules/gov-integrations/services/shif.service.ts`
- **Features**:
  - SHIF portal authentication
  - Employee registration
  - Monthly contribution submissions
  - Compliance reporting
  - Eligibility verification

## Environment Variables
```env
# KRA iTax
KRA_API_URL=https://itax.kra.go.ke
KRA_USERNAME=your-username
KRA_PASSWORD=your-password
KRA_PIN=your-kra-pin

# NSSF
NSSF_API_URL=https://employers.nssf.go.ke
NSSF_USERNAME=your-username
NSSF_PASSWORD=your-password

# SHIF
SHIF_API_URL=https://www.shif.go.ke
SHIF_API_KEY=your-api-key
```

## API Endpoints

### Government Submissions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/gov/submissions` | List all government submissions |
| GET | `/gov/submissions/:id` | Get submission details |
| POST | `/gov/submit/kra` | Submit KRA filing |
| POST | `/gov/submit/nssf` | Submit NSSF contribution |
| POST | `/gov/submit/shif` | Submit SHIF contribution |
| GET | `/gov/status/:id` | Check submission status |
| POST | `/gov/retry/:id` | Retry failed submission |

### Compliance Reports
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/gov/compliance/summary` | Get compliance summary |
| GET | `/gov/compliance/:type` | Get specific compliance status |
| GET | `/gov/reports/:type/:year` | Generate compliance report |

## Submission Statuses
- `PENDING` - Submission created, awaiting processing
- `SUBMITTED` - Submitted to government API
- `ACCEPTED` - Government accepted the submission
- `REJECTED` - Government rejected the submission
- `ERROR` - Error during submission

## Mobile UI
- **Submissions List**: `mobile/lib/features/gov_submissions/presentation/pages/`
- **Submission Details**: View individual submission status
- **Create Submission**: Form to submit new filings

## Database Entities
- `GovSubmission` - `backend/src/modules/gov-integrations/entities/gov-submission.entity.ts`

## Gov Submission Entity Fields
| Field | Type | Description |
|-------|------|-------------|
| id | uuid | Primary key |
| userId | uuid | Employer ID |
| type | enum | KRA, NSSF, SHIF |
| period | string | Submission period (e.g., "2024-01") |
| amount | decimal | Amount submitted |
| referenceNumber | string | Government reference |
| status | enum | PENDING, SUBMITTED, ACCEPTED, REJECTED |
| response | json | API response data |
| submittedAt | timestamp | When submitted |

## Current Configuration Status
- ✅ KRA service structure
- ✅ NSSF service structure
- ✅ SHIF service structure
- ✅ Gov submission entity
- ✅ Mobile gov_submissions feature
- ⚠️ API authentication tokens
- ⚠️ Full portal integration

## Workflow

### Submitting a KRA Filing
1. Collect payroll data for the period
2. Calculate total PAYE, NSSF, SHIF, Housing Levy
3. Authenticate with iTax API
4. Submit filing via `POST /gov/submit/kra`
5. Store submission reference
6. Poll for status updates

### Submitting NSSF Contributions
1. Gather employee contribution data
2. Authenticate with NSSF employer portal
3. Submit contributions via `POST /gov/submit/nssf`
4. Get confirmation receipt
5. Store for compliance records

### Submitting SHIF Contributions
1. Register/verify employees in SHIF
2. Calculate contributions (2.75% of gross)
3. Submit via `POST /gov/submit/shif`
4. Track payment status

## Known Gaps
| Gap | Status |
|-----|--------|
| KRA iTax API full integration | ⚠️ In development |
| NSSF portal API access | ⚠️ Awaiting credentials |
| SHIF API documentation | ⚠️ Review needed |
| Auto-submission scheduling | ❌ Not implemented |
| Compliance notifications | ❌ Not implemented |
