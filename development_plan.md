# Development Plan: Kenya Expats Domestic Worker Management App

## 1. Subscription Model Design

### Subscription Tiers & Pricing Strategy
To cater to different user needs, we propose a three-tier subscription model.

| Feature | **Rafiki (Basic)** | **Familia (Standard)** | **Shujaa (Premium)** |
| :--- | :--- | :--- | :--- |
| **Target Audience** | Single expat, 1 part-time worker | Family, 1-3 workers | Large household, agencies |
| **Price (Est.)** | Free / $2.99/mo | $9.99/mo | $24.99/mo |
| **Worker Limit** | 1 Worker | Up to 3 Workers | Unlimited |
| **Payment Features** | Manual recording, M-Pesa Receipts | Auto-payments, Bulk Pay | Multi-currency, Auto-receipts |
| **HR Features** | Basic Profile | Leave Tracking, Contracts | Doc Storage, Adv. HR |
| **Tax Compliance** | Calculator only | Auto-generated Forms | Tax Filing Assistance |
| **Support** | Email | Chat | Priority 24/7 |

### Subscription Lifecycle
*   **Free Trial**: 14-day full access to "Familia" tier.
*   **Billing Cycle**: Monthly and Annual (2 months free).
*   **Grace Period**: 3 days for failed payments before feature locking.
*   **Downgrades**: Effective at end of billing cycle. Data for extra workers becomes read-only.

### Revenue Recognition
*   Use a "Merchant of Record" (MoR) like **Paddle** or **RevenueCat** to simplify international tax handling for digital subscriptions, or standard **Stripe** + **M-Pesa** handling.

## 2. Technical Architecture

### Tech Stack
*   **Mobile App (Cross-Platform)**: **Flutter** (Dart). Best for high-fidelity UI and consistent behavior on iOS/Android.
*   **Backend**: **Node.js** with **NestJS** (TypeScript). Strong typing, modular, great for financial logic.
*   **Database**: **PostgreSQL**. Essential for relational data (Users <-> Workers <-> Payments) and ACID compliance.
*   **Infrastructure**: **AWS** (EC2, RDS, S3) or **Google Cloud** (Cloud Run, Cloud SQL).
*   **Payment Processing**:
    *   *Subscriptions*: **Stripe** (Int'l cards), **M-Pesa** (via Daraja API for local subs).
    *   *Worker Payouts*: **Flutterwave** or **IntaSend** (Aggregators that allow Card/Wallet -> M-Pesa payouts).

### M-Pesa Integration Approach
*   **Direct Daraja API**: For collecting subscription payments from users via M-Pesa (C2B/STK Push).
*   **Payouts (Worker Salaries)**:
    *   *Option A (Direct)*: M-Pesa B2C API. Requires a Paybill number and pre-funding the B2C account.
    *   *Option B (Aggregator - Recommended)*: Use **IntaSend** or **Flutterwave**. They handle the "Pay to Mobile Money" complexity and allow users to fund the transaction via Card or Bank.

### Security
*   **Data Encryption**: AES-256 for sensitive data (contracts, IDs) at rest. TLS 1.3 in transit.
*   **Auth**: Auth0 or Firebase Auth (MFA enabled).
*   **Compliance**: GDPR (for EU expats) and Kenya Data Protection Act (ODPC).

## 3. Development Phases

### Phase 1: MVP (Months 1-3)
*   **Goal**: Core value proposition - Pay a worker and calculate tax.
*   **Features**:
    *   User Auth & Worker Profiles (Basic).
    *   Tax Calculator (PAYE, NSSF, NHIF, Housing Levy).
    *   Manual Payment Recording (User pays outside app, records it).
    *   Basic Subscription (Stripe integration).
    *   Document generation (Payslips).

### Phase 2: Automation & Payments (Months 4-6)
*   **Goal**: Seamless transactions.
*   **Features**:
    *   In-app Payments (Card -> M-Pesa Payouts).
    *   Leave Management System.
    *   M-Pesa Receipt Parsing (Android only) or Upload.
    *   Notifications (SMS/Email to workers).

### Phase 3: Compliance & Scale (Months 7-9)
*   **Goal**: Full HR suite.
*   **Features**:
    *   Tax Filing Integration (iTax guides/exports).
    *   Multi-user access (Spouse login).
    *   Expense tracking (Groceries/Household money).

## 4. Database Schema (Core Entities)

*   **Users**: `id, email, tier, payment_methods, preferences`
*   **Workers**: `id, employer_id, name, phone (mpesa), id_number, salary_gross, start_date`
*   **Subscriptions**: `id, user_id, status, start_date, next_billing, provider_id`
*   **Transactions**: `id, sender_id, recipient_id, amount, currency, type (SALARY, SUBSCRIPTION), status, external_ref`
*   **LeaveRecords**: `id, worker_id, type, start_date, end_date, status`
*   **TaxReports**: `id, worker_id, month, year, paye_amount, nssf_amount, nhif_amount, housing_levy`

## 5. Payment Integration Strategy

### Dual Payment System
1.  **Subscription Payments (Incoming)**:
    *   Recurring billing.
    *   Logic: Cron job checks due dates -> Triggers Stripe charge or M-Pesa prompt.
2.  **Worker Payments (Outgoing)**:
    *   One-off or Scheduled.
    *   **Flow**: User Selects Workers -> Calculates Total (Salary + Fees) -> User Charges Card/Wallet -> System holds funds -> System triggers Payout to Worker M-Pesa.
    *   *Critical*: Requires "Wallet" architecture or atomic transactions to ensure user isn't charged if payout fails.

### Error Handling
*   **M-Pesa Timeouts**: Common. Implement exponential backoff for status checks.
*   **Insufficient Funds**: Notify user immediately.
*   **Reconciliation**: Daily jobs matching Bank/M-Pesa statements with DB records.

## 6. Tax Module Design

### Calculations (Kenya FY 2024/2025)
*   **NSSF**: Tier I & Tier II calculations (Pension).
*   **NHIF/SHIF**: Social Health Insurance Fund (2.75% of gross).
*   **Housing Levy**: 1.5% of gross (Employer & Employee).
*   **PAYE**: Graduated scale bands.

### Reporting
*   Generate **P9 Forms** (End of year).
*   Generate monthly **Excel/CSV** compatible with KRA iTax returns.

## 7. User Interface Flow

### Critical Journeys
1.  **Onboarding**: Splash -> Value Prop -> Sign Up -> **Select Tier** -> Add First Worker.
2.  **Pay Day**: Dashboard -> "Run Payroll" -> Review Amounts -> Confirm & Pay -> Success -> Auto-send SMS to Worker.
3.  **Leave Request**: Worker (or Employer on behalf) logs dates -> System checks balance -> Approval.

### Key Screens
*   **Dashboard**: Quick actions, Upcoming payments, Active subscriptions.
*   **Worker Profile**: Bio, Salary config, Leave balance, Payment history.
*   **Payroll Center**: Bulk payment selection, Tax breakdown.
*   **Subscription Manager**: Upgrade/Downgrade, Billing history.

## 8. Analytics & Metrics

*   **Business Metrics**: MRR (Monthly Recurring Revenue), Churn Rate, CAC (Customer Acquisition Cost).
*   **Product Metrics**: % of users running payroll monthly, Avg workers per user.
*   **Tech Metrics**: API Latency, Payment Success Rate (Critical for M-Pesa).

## 9. Compliance & Legal

*   **Labor Law**: Contracts must meet Employment Act 2007 standards. App should generate compliant contract templates.
*   **Data Privacy**: Explicit consent for storing worker ID/Phone data.
*   **Financial**: If holding funds, need CBK license. **Recommendation**: Use a licensed PSP (Payment Service Provider) to avoid holding funds directly.

## 10. Testing Strategy

*   **Unit Tests**: Tax calculations (Must be 100% accurate).
*   **Integration Tests**: Payment flows (Mock M-Pesa APIs).
*   **UAT**: Beta group of 10 expats.
*   **Security**: Penetration testing on payment endpoints.

## 11. Deployment & Maintenance

*   **Stores**: Apple App Store & Google Play.
*   **CI/CD**: GitHub Actions -> Codemagic/Bitrise -> Stores.
*   **Support**: Intercom integration for in-app chat (Tier based).

## 12. Monetization Strategy

*   **Freemium**: Free tier is very limited (manual tracking) to drive upgrades.
*   **Upsell**: "Unlock Auto-Pay" is the main hook.
*   **B2B**: "Enterprise" tier for Property Management companies managing staff for multiple units.

## 13. Potential Challenges & Solutions

*   **Challenge**: M-Pesa API downtime.
    *   *Solution*: Queue payments and retry; notify users of delays.
*   **Challenge**: Trust (Expats connecting bank accounts).
    *   *Solution*: Use trusted brands (Stripe/Flutterwave) logos prominent. Don't store card details (Tokenization).
*   **Challenge**: Complex Tax Laws.
    *   *Solution*: Partner with a local accounting firm to audit formulas quarterly.
