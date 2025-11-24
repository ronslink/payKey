# Database Schema Design

## 1. ER Diagram

```mermaid
erDiagram
    USERS ||--o{ WORKERS : employs
    USERS ||--o{ SUBSCRIPTIONS : has
    USERS ||--o{ TRANSACTIONS : initiates
    WORKERS ||--o{ TRANSACTIONS : receives
    WORKERS ||--o{ LEAVE_REQUESTS : requests
    WORKERS ||--o{ TAX_REPORTS : has

    USERS {
        uuid id PK
        string email UK
        string password_hash
        string first_name
        string last_name
        enum tier "FREE, BASIC, PRO, ENTERPRISE"
        string stripe_customer_id
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
    }

    SUBSCRIPTIONS {
        uuid id PK
        uuid user_id FK
        string provider_sub_id
        enum status "ACTIVE, PAST_DUE, CANCELED"
        timestamp current_period_end
        boolean cancel_at_period_end
    }

    TRANSACTIONS {
        uuid id PK
        uuid user_id FK
        uuid worker_id FK "Nullable"
        decimal amount
        string currency
        enum type "SUBSCRIPTION, SALARY_PAYOUT"
        enum status "PENDING, SUCCESS, FAILED"
        string provider_ref
        jsonb metadata
        timestamp created_at
    }

    LEAVE_REQUESTS {
        uuid id PK
        uuid worker_id FK
        date start_date
        date end_date
        enum type "ANNUAL, SICK, MATERNITY"
        enum status "PENDING, APPROVED, REJECTED"
        string reason
    }

    TAX_REPORTS {
        uuid id PK
        uuid worker_id FK
        integer month
        integer year
        decimal paye_amount
        decimal nssf_amount
        decimal nhif_amount
        decimal housing_levy
        timestamp generated_at
    }
```

## 2. Table Definitions (SQL/PostgreSQL)

### Users Table
```sql
CREATE TYPE user_tier AS ENUM ('FREE', 'BASIC', 'PRO', 'ENTERPRISE');

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
CREATE TYPE transaction_type AS ENUM ('SUBSCRIPTION', 'SALARY_PAYOUT');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED');

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
