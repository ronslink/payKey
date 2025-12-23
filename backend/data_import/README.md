# Data Import Documentation

This folder contains scripts for importing historical payroll data from PDF payslips into PayKey.

## Overview

The migration process extracts worker information and payroll history from PDF payslips and imports them directly into the PayKey database, bypassing the application's business logic to preserve exact historical values.

## Data Flow

```
PDF Payslips → extract_workers.py → extracted_data.json → import-sam-olago.ts → Database
```

## Scripts

### 1. extract_workers.py
**Purpose:** Extracts worker and payroll data from PDF payslips.

**Prerequisites:**
- Python 3.x
- `pdftotext` command-line tool (from Poppler)

**Usage:**
```bash
cd backend/data_import
python extract_workers.py
```

**Input:** PDF files in `SAMUEL OLAGO NSSF NHIF and PAYSLIPS/Payslips and Muster file - 2024 - 2025/`

**Output:** `extracted_data.json` containing:
- `workers[]` - Array of worker objects with name, PIN, NSSF, NHIF, salary
- `payroll_history[]` - Array of monthly payroll records

---

### 2. import-sam-olago.ts
**Purpose:** Imports extracted data into PayKey database.

**Prerequisites:**
- Local PostgreSQL database running
- Backend dependencies installed (`npm install`)

**Usage:**
```powershell
cd D:\payKey
$env:DB_HOST='localhost'; npx ts-node backend/data_import/import-sam-olago.ts
```

**What it creates:**
| Entity | Details |
|--------|---------|
| User | Sam Olago (kingpublish@gmail.com) with complete profile |
| Subscription | PLATINUM tier, active |
| Property | "Samuel Olago - UNON" with coordinates and what3words |
| Workers | 2 workers with DOB, leave balance (21 days), and all tax details |
| Pay Periods | 18 months (Jan 2024 - June 2025), status: CLOSED, with totals |
| Payroll Records | 36 records (2 workers × 18 months), status: FINALIZED |

**Key Features:**
- **Idempotent** - Safe to run multiple times
- **Direct Repository Access** - Bypasses service validation for historical data
- **Data Enrichment** - Generates placeholder phone numbers if missing
- **Onboarding Completion** - Sets all profile fields and marks onboarding complete
- **Pay Period Totals** - Calculates and stores totalGrossAmount, totalNetAmount, totalTaxAmount

---

### 3. verify-import.ts
**Purpose:** Verifies imported data is correct.

**Usage:**
```powershell
cd D:\payKey
$env:DB_HOST='localhost'; npx ts-node backend/data_import/verify-import.ts
```

**Expected Output:**
```
👤 User: kingpublish@gmail.com
💎 Sam Subscription: { tier: 'PLATINUM', status: 'ACTIVE' }
🏢 Sam Property: { name: 'Samuel Olago - UNON', what3words: '///rise.condition.hype' }
👷 Sam Workers (2):
   - KEFA, Nicholas Luvaga: KES 16700.00
   - MUSULWA, Janet Ngoyisi: KES 17800.00
📅 Sam Pay Periods: 18
📄 Sam Payroll Records: 36
```

---

### 4. fix-subscription.ts
**Purpose:** Utility to update subscription tier to PLATINUM if needed.

**Usage:**
```powershell
cd D:\payKey
$env:DB_HOST='localhost'; npx ts-node backend/data_import/fix-subscription.ts
```

---

## Source Data Location

```
D:\payKey\backend\data_import\SAMUEL OLAGO NSSF NHIF and PAYSLIPS\
├── Payslips and Muster file - 2024 - 2025\
│   ├── Payslips - January 2024.pdf
│   ├── Payslips - February 2024.pdf
│   └── ... (19 files total)
├── NSSF 2024 - 2025\
│   └── NSSF receipts (18 files)
└── NHIF 2024\
    └── NHIF receipts
```

## Workers Imported

| Name | Emp No | KRA PIN | NSSF | NHIF | Job Title | Salary |
|------|--------|---------|------|------|-----------|--------|
| KEFA, Nicholas Luvaga | 001 | A008064326K | 246694939 | 7573188 | Driver | 16,700 |
| MUSULWA, Janet Ngoyisi | 002 | A011473719L | 573605823 | 7493843 | House Help | 17,800 |

## After Import

Sam Olago can now:
1. Log into PayKey with `kingpublish@gmail.com`
2. View complete payroll history for 2024-2025
3. Update worker phone numbers for M-Pesa payments
4. Run new payroll for upcoming months
