# Payroll Process Flow

This document outlines the workflow for running payroll in PayKey, covering both Manual and Automated processes.

## 1. Manual Payroll Process
This is the standard flow where the user manually reviews and initiates payments.

```mermaid
sequenceDiagram
    participant User
    participant App as Mobile App
    participant Backend
    participant MPESA as M-Pesa

    User->>App: Select "Run Payroll"
    App->>App: Initialize Pay Period (if needed)
    User->>App: Select Pay Period (e.g., Jan 2026)
    
    rect rgb(240, 248, 255)
        note right of User: Step 1: Employee Inputs
        User->>App: Enter Hours / Overtime
        User->>App: Enter Bonuses / Deductions
        User->>App: Adjust Days Worked (if partial period)
        App->>Backend: Save Draft (Auto-save)
        User->>App: Click "Review Payroll"
    end

    rect rgb(255, 250, 240)
        note right of User: Step 2: Review
        App->>Backend: Calculate Payroll
        Backend-->>App: Return Calculations (Gross, Net, Tax)
        App->>User: Display Summary & Worker List
        User->>App: Click "Confirm & Pay"
    end

    rect rgb(240, 255, 240)
        note right of User: Step 3: Confirm & Payment
        App->>Backend: Verify Wallet Balance
        
        alt Insufficient Funds
            Backend-->>App: Show Shortfall
            App->>User: Show Top-Up Sheet (M-Pesa)
            User->>App: Complete Top-Up
        end
        
        User->>App: Confirm Payment
        Backend->>MPESA: Initiate B2C Payments
        MPESA-->>Backend: Payment Status
        Backend-->>App: PayrollProcessingResult
        App->>User: Show Payment Results Page (with worker details)
    end
```

### Manual Flow Pages
| Step | Page | Route | Description |
|------|------|-------|-------------|
| 1 | `RunPayrollPageNew` | `/payroll/run` | Hours, overtime, bonuses, deductions, days worked |
| 2 | `PayrollReviewPage` | `/payroll/review/:id` | Tax breakdown, net pay calculations |
| 3 | `PayrollConfirmPage` | `/payroll/confirm/:id` | Wallet verification, top-up, final payment |

---

## 2. Automated Payroll Process
This flow allows "One-Click" processing for salaried employees with no variations.

```mermaid
flowchart TD
    A[Start: Run Payroll Page] --> B{Automation Toggle ON?}
    B -- No --> C[Manual Flow - See Above]
    B -- Yes --> D[Enter Worker Inputs]
    
    D --> E[Click 'Run Payroll' Button]
    
    E --> F[Calculate Payroll]
    F --> G[Save Draft]
    G --> H[Process Payroll Immediately]
    
    H --> I[Show Payment Results Page]
    I --> J[Navigate to Home]
```

### Key Differences from Manual Flow

| Aspect | Manual Flow | Automated Flow |
|--------|-------------|----------------|
| **Review Step** | Shows `PayrollReviewPage` with full breakdown | ⚡ Skipped entirely |
| **Confirmation** | `PayrollConfirmPage` with wallet check & top-up | ⚡ Skipped entirely |
| **Result Display** | `PaymentResultsPage` with per-worker status | ✅ Same `PaymentResultsPage` |
| **Failure Handling** | Shows failed workers, allows retry | ✅ Same behavior |
| **Best For** | Complex payrolls, first-time runs | Fixed-salary, recurring runs |

> [!TIP]
> Both flows now use the same `PaymentResultsPage` to display per-worker success/failure details.
> Users can see exactly which payments failed and why.

---

## 3. Proration & Partial Periods

### When Proration Applies
The app automatically detects and handles partial pay periods:

| Scenario | Detection | Default Days |
|----------|-----------|--------------|
| **New Hire** | `worker.startDate` after period start | Days from start to period end |
| **Termination** | `worker.terminatedAt` before period end | Days from period start to termination |
| **Deceased** | Same as termination | May be 0 if not reported in time |
| **Leave of Absence** | Manual entry required | User enters actual days |

### UI Behavior

```
┌─ Normal Worker ────────────────────────────┐
│ [Hours] [Overtime] [Bonuses] [Deductions]  │  ← No days field shown
└────────────────────────────────────────────┘

┌─ Terminated Worker ──────────────⚠️ Orange ─┐
│ ⚠️ 15 / 31 days                             │  ← Badge visible
├─────────────────────────────────────────────┤
│ Days Worked:                                │
│ ● Full Period (31 days)                     │
│ ○ Partial: [15] / 31                        │  ← Editable input
│                                             │
│ Prorated: KES 50,000 × (15/31) = KES 24,193│
└─────────────────────────────────────────────┘
```

### Proration Formula
```
Prorated Salary = Monthly Salary × (Days Worked / Total Days in Period)
```

### Payload Sent to Backend
```json
{
  "workerId": "uuid",
  "grossSalary": 24193.55,
  "bonuses": 0,
  "otherDeductions": 0,
  "daysWorked": 15,
  "totalDaysInPeriod": 31
}
```

---

## 4. Post-Payroll Actions

Once payroll is **Finalized**:
1.  **Payslips**: Generated automatically and available for download.
2.  **Reports**: Tax returns (P10, SHIF excel) are generated.
3.  **History**: Records are locked and moved to "History" tab.

## 5. Status Usage

| Status | Display Name | Meaning |
| :--- | :--- | :--- |
| `DRAFT` | **Draft** | Inputs are being entered. Editable. |
| `PROCESSING` | **Processing** | Calculations/Allocations in progress. |
| `COMPLETED` | **Finalized** | Payroll calculated, paid (if applicable), and payslips generated. |
| `CLOSED` | **Archived** | Optional manual state. Permanently locked. |

## 6. Key Components

### Reusable Widgets (from refactored `payroll_confirm` module)
- `WalletBalanceCard` - Shows balance, shortfall, top-up button
- `MpesaTopupSheet` - M-Pesa top-up bottom sheet
- `PaymentResultsPage` - Per-worker payment results with success/failure
- `WorkerPayrollCard` - Worker input card with optional proration UI

### Controller Management
  - Hours, Overtime, Bonuses, Deductions
  - **Days Worked** - with smart defaults based on worker status

---

## 7. Tax Submission Workflow

The system handles the **calculation** and **tracking** of tax liabilities automatically, but the **filing** and **payment** to authorities is currently a manual process.

```mermaid
sequenceDiagram
    participant User
    participant App
    participant Backend
    participant External as KRA/NSSF/SHIF

    note over Backend: Payroll Finalized (Auto)
    Backend->>Backend: Aggregate Tax Liabilities
    Backend->>Backend: Create TaxSubmission (PENDING)
    
    User->>App: View Tax Obligations
    App-->>User: Show PAYE, NSSF, SHIF Totals
    
    rect rgb(255, 255, 240)
        note right of User: Manual Action
        User->>External: File Returns & Pay (iTax/Paybill)
    end
    
    User->>App: Click "Mark as Filed"
    App->>Backend: POST /taxes/:id/file
    Backend->>Backend: Update Status to FILED
    Backend-->>App: Confirmation
```

### Steps Description

1.  **Automatic Generation**:
    *   Immediately after payroll is finalized (`COMPLETED`), the backend aggregates all tax data (PAYE, NSSF, SHIF, Housing Levy) from the period's payroll records.
    *   A `TaxSubmission` record is created with a `PENDING` status.

2.  **User Review**:
    *   The user views the "Statutory Reports" or "Tax" section in the app to see exactly how much is owed for each category.

3.  **Manual Filing (Critical)**:
    *   The user must manually log in to the KRA iTax portal or NSSF/SHIF portals to file the returns.
    *   Payment is made via external channels (M-Pesa Paybill or Bank).

4.  **Completion**:
    *   Once paid, the user clicks "Mark as Filed" in the app.
    *   The system updates the record to `FILED` for compliance tracking.

