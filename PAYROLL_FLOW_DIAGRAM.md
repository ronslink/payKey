# Payroll Processing Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PAYROLL PROCESSING FLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│  1. CREATE       │
│  Pay Period      │  Status: DRAFT
│  (Name, Dates)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  2. SELECT       │
│  Workers         │  Frontend: run_payroll_page.dart
│  (Checkboxes)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  3. CALCULATE    │  ⚠️ FIXED: Now actually saves data!
│  Payroll         │  
│                  │  Actions:
│  ┌────────────┐  │  1. POST /payroll/calculate (get calculations)
│  │ Calculate  │  │  2. POST /payroll/draft (save draft records)
│  │ Taxes      │  │  3. Navigate to review page
│  │ (PAYE,     │  │
│  │  NSSF,     │  │  Data saved:
│  │  NHIF,     │  │  - workerId
│  │  Housing)  │  │  - grossSalary
│  └────────────┘  │  - bonuses, otherEarnings, otherDeductions
│                  │  - taxBreakdown (calculated)
│  - netSalary (calculated)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  4. REVIEW       │  Frontend: payroll_review_page.dart
│  Payroll         │  (Manual Flow)
│                  │  Displays:
│  ┌────────────┐  │  - List of workers with amounts
│  │ Worker 1   │  │  - Summary statistics
│  │ Gross: 100K│  │  - Pay period details
│  │ Net: 75K   │  │
│  └────────────┘  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  5. CONFIRM      │  Frontend: payroll_confirm_page.dart  ⭐ NEW GATEKEEPER
│  & PAY           │  
│                  │  Converge Point:
│  [Confirm & Pay] │  - Manual Flow navigates here from Review
│                  │  - Automated Flow navigates here directly (Skipping Review)
│                  │
│  IntaSend Logic: │
│  1. Check Wallet │
│  2. Top Up (Opt) │
│  3. Disburse (Batch) <- Supports multiple!│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  6. PROCESS      │  Status: ACTIVE → PROCESSING
│  Payroll         │  
│                  │  POST /pay-periods/:id/process
│  [Process]       │  (Triggered by Confirm Page success)
│                  │  
│                  │  Backend calculates totals:
│  ┌────────────┐  │  - totalGrossAmount = Σ grossSalary
│  │ Calculate  │  │  - totalNetAmount = Σ netSalary
│  │ Totals     │  │  - totalTaxAmount = Σ taxAmount
│  └────────────┘  │  - processedWorkers = count
│                  │
│  Statistics:     │  ⚠️ FIXED: Frontend now refreshes!
│  ✓ Total Gross   │  - Calls _loadStatistics() after action
│  ✓ Total Net     │  - Displays updated totals (not zeros)
│  ✓ Total Tax     │
│  ✓ Worker Count  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  7. COMPLETE     │  Status: PROCESSING → COMPLETED
│  Pay Period      │  
│                  │  POST /pay-periods/:id/complete
│  [Complete]      │  
│                  │  Backend actions:
│  ┌────────────┐  │  1. Generate tax submission data
│  │ Generate   │  │  2. Create TaxPayment entries
│  │ Tax Data   │  │  3. Update pay period status
│  └────────────┘  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  8. GENERATE     │  (Optional, when COMPLETED)
│  Payslips        │  
│                  │  POST /payroll/payslips/generate/:payPeriodId
│  [Generate]      │  ⚠️ NEW ENDPOINT ADDED!
│                  │
│  ┌────────────┐  │  Backend actions:
│  │ Create PDF │  │  1. Fetch finalized payroll records
│  │ Payslips   │  │  2. Generate PDF for each worker
│  └────────────┘  │  3. Cache PDFs (5 min TTL)
│  4. Return success + count
│  Result:         │
│  ✓ Payslip 1.pdf │
│  ✓ Payslip 2.pdf │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  9. CLOSE        │  Status: COMPLETED → CLOSED
│  Pay Period      │  
│                  │  POST /pay-periods/:id/close
│  [Close]         │  
│                  │  Period is now locked
│  ✓ Finalized     │  No further modifications allowed
│  ✓ Locked        │
└──────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                       INTASEND PAYMENT INTEGRATION                       │
└─────────────────────────────────────────────────────────────────────────┘

PREREQUISITE: Wallet Funding
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Mobile App      │──────▶│   IntaSend API   │──────▶│   User Phone     │
│  [Top Up Wallet] │       │   (STK Push)     │       │   (M-Pesa PIN)   │
└──────────────────┘       └──────────────────┘       └────────┬─────────┘
                                                               │
                                                               ▼
                           ┌──────────────────┐       ┌──────────────────┐
                           │   Wallet Bal     │◀──────│  M-Pesa System   │
                           │   Updated        │       │  (Process Payment│
                           └──────────────────┘       └──────────────────┘

PAYROLL DISBURSEMENT FLOW (Step 6 Detail)

┌──────────────────┐
│  A. CONFIRM      │
│  Verification    │
│                  │
│  1. Check Wallet │ ────▶ GET /wallets (IntaSend)
│  2. Calc Total   │
│  3. Show Balance │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  B. DISBURSE     │  Triggered by "Confirm & Pay"
│  (IntaSend)      │
│                  │
│  1. Batch Payout │ ────▶ POST /send-money/initiate (IntaSend)
│  2. M-Pesa B2C   │       (Sends to all workers)
│  3. Get Tracking │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐       ┌──────────────────┐
│  C. SYNC         │       │  IntaSend API    │
│  (Backend)       │       │  (Webhooks)      │
│                  │       └────────┬─────────┘
│  1. Status Sync  │◀───────────────┘
│  2. Record Txns  │
│  3. Mark Paid    │
└──────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                            KEY COMPONENTS                                │
└─────────────────────────────────────────────────────────────────────────┘

Frontend Pages:
├── run_payroll_page.dart          → Worker selection & calculation
├── payroll_review_page.dart       → Review & actions
├── payroll_workflow_page.dart     → Status tracking & statistics
└── payroll_confirm_page.dart      → IntaSend disbursement logic ⭐

Backend Services:
├── PayPeriodsService              → Pay period lifecycle
├── PayrollService                 → Payroll calculations & draft management
├── PayslipService                 → PDF generation with caching
├── TaxPaymentsService             → Tax submission generation
├── SubscriptionsController        → Handles M-Pesa STK Push for subs
└── IntaSendWebhookHandler         → Processes payment callbacks

API Endpoints:
├── POST   /pay-periods                          → Create pay period
├── POST   /pay-periods/:id/activate             → Activate period
├── POST   /pay-periods/:id/process              → Process payroll
├── POST   /pay-periods/:id/complete             → Complete period
├── POST   /pay-periods/:id/close                → Close period
├── GET    /pay-periods/:id/statistics           → Get statistics
├── POST   /payroll/calculate                    → Calculate payroll
├── POST   /payroll/draft                        → Save draft
├── GET    /payroll/draft/:payPeriodId           → Get draft
├── POST   /payroll/finalize/:payPeriodId        → Finalize payroll
├── POST   /payroll/payslips/generate/:id        → Generate payslips
└── POST   /subscriptions/mpesa-subscribe        → Subscribe via M-Pesa ⭐


┌─────────────────────────────────────────────────────────────────────────┐
│                          CRITICAL FIXES                                  │
└─────────────────────────────────────────────────────────────────────────┘

1. ⚠️ CALCULATE PAYROLL NOT SAVING DATA
   Before: Just navigated to review page (no data saved)
   After:  Calculates → Saves draft → Then navigates
   
2. ⚠️ STATISTICS SHOWING ZEROS
   Before: Frontend didn't refresh after status changes
   After:  Calls _loadStatistics() after each action
   
3. ⚠️ PAYSLIP GENERATION 404 ERROR
   Before: Endpoint didn't exist
   After:  Added POST /payroll/payslips/generate/:id

4. ⚠️ NUMERIC VALUE ERRORS
   Before: Crashed when backend returned strings
   After:  Safe conversion with _getNumValue() helper

5. ⚠️ PAYMENT SYNCHRONIZATION
   Before: Mobile directly called IntaSend (Ghost payments possible)
   After:  Backend orchestrates Subscription payments; Payroll syncs post-disbursement
```
