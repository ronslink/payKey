# Technical Architecture Deep Dive

## 1. System Overview

The PayKey platform consists of a mobile application (Flutter), a backend API (NestJS), and a relational database (PostgreSQL). The system integrates with external payment gateways (M-Pesa via IntaSend, Stripe) and government APIs (KRA, NSSF, SHIF) for tax compliance.

## 2. Tech Stack & Infrastructure

*   **Mobile App**: Flutter (Dart)
    *   *State Management*: BLoC (Business Logic Component)
    *   *Architecture*: Clean Architecture (Presentation, Domain, Data layers)
*   **Backend**: Node.js with NestJS framework
    *   *Language*: TypeScript
    *   *ORM*: TypeORM
*   **Database**: PostgreSQL 15+
*   **Caching**: Redis (for session management and queue processing)
*   **Infrastructure**: DigitalOcean/AWS
    *   *Compute*: Docker containers on ECS/Fargate or Droplets
    *   *Database*: Managed PostgreSQL (RDS or DO Managed)
    *   *Storage*: S3-compatible object storage
    *   *CI/CD*: GitHub Actions

## 3. Backend Architecture (NestJS)

### Folder Structure
```
src/
├── app.module.ts
├── main.ts
├── common/                 # Shared utilities, decorators, guards, transformers
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── transformers/
├── config/                 # Configuration (Env variables)
├── modules/
│   ├── auth/               # Authentication & Authorization
│   ├── users/              # User management
│   ├── workers/            # Worker profiles & management
│   ├── subscriptions/      # Subscription logic & Stripe integration
│   │   ├── entities/
│   │   ├── dto/
│   │   └── subscription.processor.ts
│   ├── payments/           # Payment processing (M-Pesa via IntaSend, Stripe)
│   │   ├── entities/
│   │   ├── intasend.service.ts
│   │   ├── stripe.service.ts
│   │   ├── unified-payments.controller.ts
│   │   └── subscription-payments.controller.ts
│   ├── payroll/            # Payroll processing & pay periods
│   │   ├── entities/
│   │   └── payroll.service.ts
│   ├── taxes/              # Tax calculations & Reporting
│   ├── tax-config/         # Tax configuration management
│   ├── tax-payments/       # Tax payment tracking
│   ├── gov-integrations/   # KRA, NSSF, SHIF API integrations
│   │   ├── entities/
│   │   ├── services/
│   │   │   ├── kra.service.ts
│   │   │   ├── nssf.service.ts
│   │   │   └── shif.service.ts
│   │   └── gov-submissions.controller.ts
│   ├── notifications/      # SMS/Email services
│   ├── data-deletion/      # GDPR data deletion compliance
│   ├── export/             # Data export functionality
│   ├── activities/         # Activity feed & audit logging
│   ├── properties/         # Property/branch management
│   ├── reports/            # Reports generation
│   ├── excel-import/       # Excel import functionality
│   ├── time-tracking/      # Time tracking features
│   ├── holidays/           # Holiday management
│   ├── countries/          # Country data
│   ├── cache/              # Caching layer
│   ├── throttler/          # Rate limiting
│   ├── uploads/            # File uploads
│   └── testing/            # Testing utilities
└── shared/                 # Shared services (e.g., S3, Redis)
```

### Key Modules & Responsibilities

#### Auth Module
*   **Controller**: `AuthController` (`/auth/login`, `/auth/register`, `/auth/refresh`)
*   **Service**: `AuthService` (JWT generation, Hashing)
*   **Guards**: `JwtAuthGuard`, `RolesGuard` (Admin vs User)

#### Payments Module
*   **Controller**: `PaymentsController` (`/payments/initiate`, `/payments/callback`, `/payments/history`)
*   **Service**: `MpesaService` (Daraja API interaction), `StripeService`
*   **Queue**: `PaymentQueue` (BullMQ) for processing async payment callbacks.

#### Taxes Module
*   **Service**: `TaxCalculatorService` (Core logic for PAYE, NSSF, NHIF)
*   **Service**: `ReportGeneratorService` (PDF/Excel generation)

## 4. Mobile App Architecture (Flutter)

### Folder Structure
```
lib/
├── main.dart
├── core/                   # Core functionality (DI, Network, Errors)
│   ├── error/
│   ├── network/
│   └── utils/
├── config/                 # Routes, Themes
├── features/               # Feature-based organization
│   ├── auth/
│   │   ├── data/           # Repositories, Data Sources
│   │   ├── domain/         # Entities, UseCases
│   │   └── presentation/   # BLoCs, Pages, Widgets
│   ├── home/
│   ├── workers/
│   ├── payroll/
│   │   ├── pay_periods/
│   │   └── presentation/
│   ├── payments/
│   ├── subscriptions/
│   ├── taxes/
│   ├── gov_submissions/
│   ├── time_tracking/
│   ├── holidays/
│   ├── leave_management/
│   ├── reports/
│   ├── properties/
│   ├── employee_portal/
│   ├── settings/
│   ├── profile/
│   ├── onboarding/
│   ├── accounting/
│   └── finance/
└── shared/                 # Common widgets (Buttons, Inputs)
```

## 5. API Design (RESTful)

### Authentication
*   `POST /auth/register`: Create new account
*   `POST /auth/login`: Get JWT access token
*   `POST /auth/refresh-token`: Refresh access token

### Subscriptions
*   `GET /payments/subscriptions/plans`: List available tiers
*   `GET /payments/subscriptions/current`: Get current subscription
*   `POST /payments/subscriptions/checkout`: Create Stripe checkout
*   `GET /payments/subscriptions/payment-history`: Payment history
*   `POST /payments/subscriptions/webhook`: Stripe webhook
*   `GET /subscriptions/features`: Get feature access
*   `GET /subscriptions/usage`: Get usage statistics

### Payroll
*   `GET /pay-periods`: List all pay periods
*   `POST /pay-periods`: Create pay period
*   `POST /pay-periods/:id/activate`: Activate pay period
*   `POST /pay-periods/:id/process`: Process pay period
*   `POST /payroll/run`: Run payroll for pay period
*   `GET /payroll/records`: Get payroll records

### Payments
*   `POST /payments/initiate-stk`: STK Push for wallet top-up
*   `POST /payments/send-b2c`: Development-only direct B2C payout helper
*   `GET /payments/intasend/status/:trackingId`: Check payout status
*   `POST /payments/intasend/webhook`: IntaSend webhook handler
*   `GET /payments/unified/wallet`: Get wallet balance
*   `GET /payments/transactions`: List transaction history

### Workers
*   `GET /workers`: List all workers for current user
*   `POST /workers`: Add new worker
*   `GET /workers/:id`: Get worker details
*   `PATCH /workers/:id`: Update worker
*   `DELETE /workers/:id`: Archive worker (Soft delete)

### Taxes
*   `GET /taxes/config`: Get tax configuration
*   `GET /taxes/submissions`: Get tax submissions
*   `POST /taxes/submit`: Submit tax filing
*   `GET /taxes/summary/:year`: Get annual summary
*   `POST /tax-payments/pay`: Record tax payment

### Government Integrations
*   `GET /gov/submissions`: List government submissions
*   `POST /gov/submit/kra`: Submit KRA filing
*   `POST /gov/submit/nssf`: Submit NSSF contribution
*   `POST /gov/submit/shif`: Submit SHIF contribution
*   `GET /gov/status/:id`: Check submission status

## 6. Security Considerations

*   **API Security**: Rate limiting (ThrottlerModule), Helmet (Headers), CORS configuration.
*   **Data Protection**:
    *   Worker IDs and Phone numbers encrypted in DB.
    *   Signed URLs for accessing documents in S3.
*   **Payment Security**:
    *   Webhooks verified using signatures (Stripe & M-Pesa).
    *   Idempotency keys for payment requests to prevent double-charging.
