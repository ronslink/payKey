# Technical Architecture Deep Dive

## 1. System Overview

The PayKey platform consists of a mobile application (Flutter), a backend API (NestJS), and a relational database (PostgreSQL). The system integrates with external payment gateways (M-Pesa, Stripe) and notification services.

## 2. Tech Stack & Infrastructure

*   **Mobile App**: Flutter (Dart)
    *   *State Management*: BLoC (Business Logic Component)
    *   *Architecture*: Clean Architecture (Presentation, Domain, Data layers)
*   **Backend**: Node.js with NestJS framework
    *   *Language*: TypeScript
    *   *ORM*: TypeORM or Prisma
*   **Database**: PostgreSQL 15+
*   **Caching**: Redis (for session management and queue processing)
*   **Infrastructure**: AWS
    *   *Compute*: EC2 or ECS (Fargate)
    *   *Database*: RDS for PostgreSQL
    *   *Storage*: S3 (Document storage)
    *   *CI/CD*: GitHub Actions

## 3. Backend Architecture (NestJS)

### Folder Structure
```
src/
├── app.module.ts
├── main.ts
├── common/                 # Shared utilities, decorators, guards
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   └── interceptors/
├── config/                 # Configuration (Env variables)
├── modules/
│   ├── auth/               # Authentication & Authorization
│   ├── users/              # User management
│   ├── workers/            # Worker profiles & management
│   ├── subscriptions/      # Subscription logic & Stripe integration
│   ├── payments/           # Payment processing (M-Pesa, Wallet)
│   ├── taxes/              # Tax calculations & Reporting
│   └── notifications/      # SMS/Email services
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
│   ├── dashboard/
│   ├── workers/
│   ├── payments/
│   └── taxes/
└── shared/                 # Common widgets (Buttons, Inputs)
```

## 5. API Design (RESTful)

### Authentication
*   `POST /auth/register`: Create new account
*   `POST /auth/login`: Get JWT access token
*   `POST /auth/refresh-token`: Refresh access token

### Subscriptions
*   `GET /subscriptions/plans`: List available tiers
*   `POST /subscriptions/subscribe`: Initiate subscription (Stripe/M-Pesa)
*   `POST /subscriptions/webhook`: Handle provider updates

### Workers
*   `GET /workers`: List all workers for current user
*   `POST /workers`: Add new worker
*   `GET /workers/:id`: Get worker details
*   `PATCH /workers/:id`: Update worker
*   `DELETE /workers/:id`: Archive worker (Soft delete)

### Payments
*   `POST /payments/mpesa/c2b`: Trigger STK Push (User -> App)
*   `POST /payments/mpesa/b2c`: Trigger Payout (App -> Worker)
*   `GET /payments/transactions`: List transaction history

### Taxes
*   `POST /taxes/calculate`: Preview tax for a given salary
*   `GET /taxes/reports`: Get list of generated reports
*   `GET /taxes/reports/:id/download`: Download PDF/CSV

## 6. Security Considerations

*   **API Security**: Rate limiting (ThrottlerModule), Helmet (Headers), CORS configuration.
*   **Data Protection**:
    *   Worker IDs and Phone numbers encrypted in DB.
    *   Signed URLs for accessing documents in S3.
*   **Payment Security**:
    *   Webhooks verified using signatures (Stripe & M-Pesa).
    *   Idempotency keys for payment requests to prevent double-charging.
