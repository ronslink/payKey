# Database Schema Design

## 1. ER Diagram

```mermaid
erDiagram
    USERS ||--o{ SUBSCRIPTIONS : has
    USERS ||--o{ WORKERS : employs
    USERS ||--o{ TRANSACTIONS : initiates
    USERS ||--o{ PAYROLL_RECORDS : processes
    USERS ||--o{ TAX_SUBMISSIONS : files
    USERS ||--o{ GOV_SUBMISSIONS : submits
    WORKERS ||--o{ TRANSACTIONS : receives
    WORKERS ||--o{ PAYROLL_RECORDS : receives
    WORKERS ||--o{ TAX_SUBMISSIONS : generates
    PAY_PERIODS ||--o{ PAYROLL_RECORDS : contains
    PAY_PERIODS ||--o{ TRANSACTIONS : includes
    SUBSCRIPTIONS ||--o{ SUBSCRIPTION_PAYMENTS : has

    USERS {
        uuid id PK
        string email UK
        string password_hash
        string first_name
        string last_name
        enum tier "FREE, BASIC, GOLD, PLATINUM"
        string stripe_customer_id
        string intasend_wallet_id
        timestamp created_at
    }

    WORKERS {
        uuid id PK
        uuid user_id FK
        string name
        string phone_number
        string id_number
        string kra_pin
        decimal salary_gross
        date start_date
        boolean is_active
        enum payment_method "mpesa, bank, cash"
        string bank_account
        string bank_name
    }

    PAY_PERIODS {
        uuid id PK
        uuid user_id FK
        string name
        date period_start
        date period_end
        enum frequency "WEEKLY, BIWEEKLY, MONTHLY, QUARTERLY, YEARLY"
        enum status "DRAFT, OPEN, PROCESSING, COMPLETED, CLOSED"
        boolean is_locked
    }

    PAYROLL_RECORDS {
        uuid id PK
        uuid user_id FK
        uuid worker_id FK
        uuid pay_period_id FK
        decimal gross_salary
        decimal bonuses
        decimal other_earnings
        decimal other_deductions
        decimal overtime_pay
        decimal net_salary
        decimal tax_amount
        json tax_breakdown
        json deductions
        enum status "draft, finalized, paid"
        string payment_status
        timestamp payment_date
    }

    SUBSCRIPTIONS {
        uuid id PK
        uuid user_id FK
        enum tier "FREE, BASIC, GOLD, PLATINUM"
        enum status "ACTIVE, PENDING, CANCELLED, EXPIRED, PAST_DUE, TRIAL"
        decimal amount
        string currency
        timestamp start_date
        timestamp end_date
        timestamp next_billing_date
        string stripe_subscription_id
        string stripe_price_id
        boolean auto_renewal
        enum renewal_method "NOTIFICATION, STK_PUSH"
    }

    SUBSCRIPTION_PAYMENTS {
        uuid id PK
        uuid subscription_id FK
        decimal amount
        string currency
        string stripe_payment_intent_id
        enum status "PENDING, SUCCEEDED, FAILED"
        timestamp paid_at
    }

    TRANSACTIONS {
        uuid id PK
        uuid user_id FK
        uuid worker_id FK
        uuid pay_period_id FK
        decimal amount
        string currency
        enum type "SUBSCRIPTION, SALARY_PAYOUT, TOPUP, DEPOSIT"
        enum status "PENDING, SUCCESS, FAILED, CLEARING, MANUAL_INTERVENTION"
        string provider_ref
        string provider
        enum payment_method "MPESA_STK, PESALINK, CARD, WALLET, STRIPE"
        jsonb metadata
        timestamp created_at
    }

    TAX_SUBMISSIONS {
        uuid id PK
        uuid user_id FK
        uuid worker_id FK
        integer month
        integer year
        decimal paye_amount
        decimal nssf_amount
        decimal shif_amount
        decimal housing_levy
        enum status "DRAFT, PENDING, SUBMITTED, ACCEPTED, REJECTED"
        string submission_reference
        timestamp submitted_at
    }

    GOV_SUBMISSIONS {
        uuid id PK
        uuid user_id FK
        enum type "KRA, NSSF, SHIF"
        string period
        decimal amount
        string reference_number
        enum status "PENDING, SUBMITTED, ACCEPTED, REJECTED"
        json response
        timestamp submitted_at
    }
```

## 2. Table Definitions (SQL/PostgreSQL)

### Users Table
```sql
CREATE TYPE user_tier AS ENUM ('FREE', 'BASIC', 'GOLD', 'PLATINUM');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    tier user_tier DEFAULT 'FREE',
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Workers Table
```sql
CREATE TABLE workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL, -- Encrypt in app layer if needed
    id_number VARCHAR(50), -- Encrypt in app layer
    kra_pin VARCHAR(50),
    salary_gross DECIMAL(12, 2) NOT NULL,
    start_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TYPE transaction_type AS ENUM ('SUBSCRIPTION', 'SALARY_PAYOUT', 'TOPUP', 'DEPOSIT');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CLEARING', 'MANUAL_INTERVENTION');

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    worker_id UUID REFERENCES workers(id), -- Null for subscription payments
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KES',
    type transaction_type NOT NULL,
    status transaction_status DEFAULT 'PENDING',
    provider_ref VARCHAR(255), -- M-Pesa Receipt Number or Stripe Charge ID
    metadata JSONB, -- Store extra details like failure reason
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 3. Indexes & Performance
*   `CREATE INDEX idx_workers_user_id ON workers(user_id);`
*   `CREATE INDEX idx_transactions_user_id ON transactions(user_id);`
*   `CREATE INDEX idx_transactions_created_at ON transactions(created_at);`
