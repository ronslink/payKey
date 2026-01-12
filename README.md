# PayKey - Domestic Worker Management Platform

## Overview

PayKey is a comprehensive mobile application designed for employers in Kenya to efficiently manage domestic workers. It streamlines payroll, tax compliance (PAYE, NSSF, SHIF), and payments via M-Pesa. The platform operates on a tiered subscription model, offering features from basic record-keeping to advanced automated payroll and leave management.

## Key Features

- **Worker Management**: Full employee lifecycle (onboarding to termination), document management, and property assignment.
- **Smart Payroll**: Automated calculation of gross pay, taxes (PAYE, Housing Levy), and statutory deductions (NSSF, SHIF) based on Kenya 2024 tax laws.
- **Payments**: 
  - **M-Pesa Integration**: Direct wallet top-ups and salary payouts via IntaSend.
  - **Stripe Integration**: Subscription billing for access to advanced features.
- **Compliance**: Automatic tax submission generation (P10 forms) and statutory reports.
- **Employee Portal**: Self-service mobile view for employees to access payslips and leave balances.
- **Reporting**: Exportable muster rolls, payroll summaries, and worker lists.
- **Role-Based Access**: Multi-tier subscription system (Free, Basic, Gold, Platinum) controlling feature access.

## Technology Stack

- **Mobile**: Flutter (Dart) - Cross-platform iOS & Android
- **Backend**: NestJS (TypeScript) - Modular microservices architecture
- **Database**: PostgreSQL (Primary) + Redis (Caching/Queue)
- **ORM**: TypeORM
- **Infrastructure**: DigitalOcean (Dockerized deployment)
- **Integrations**: 
  - IntaSend (M-Pesa)
  - Stripe (Subscriptions)
  - Firebase (Push Notifications)
  - SendGrid (Email)
  - Africa's Talking (SMS)

## Documentation Structure

The documentation is organized to help you find what you need quickly:

### 📂 Feature Documentation (`/docs/features/`)
Detailed guides for each major system component:
- **Core**: [Auth](docs/features/AUTH.md), [Workers](docs/features/WORKERS.md), [Properties](docs/features/PROPERTIES.md)
- **Financial**: [Payroll](docs/features/PAYROLL.md), [Taxes](docs/features/TAXES.md), [Payments (IntaSend)](docs/features/PAYMENTS_INTASEND.md)
- **Access Control**: [Subscriptions](docs/features/SUBSCRIPTIONS.md), [Feature Gating](docs/features/FEATURE_GATING.md)
- **User Experience**: [Onboarding](docs/features/ONBOARDING.md), [Employee Portal](docs/features/EMPLOYEE_PORTAL.md)
- **Roadmap**: [Future Features](docs/features/FUTURE_FEATURES.md)

### 📂 Guides (`/docs/guides/`)
Step-by-step instructions for developers:
- **Setup**: [Configuration](docs/guides/setup/CONFIGURATION.md), [Docker](docs/guides/setup/DOCKER_DEVELOPMENT_GUIDE.md)
- **Testing**: [E2E Setup](docs/guides/testing/E2E_TEST_SETUP.md), [Load Testing](docs/guides/testing/LOAD_TESTING_GUIDE.md)
- **Deployment**: [CI/CD](docs/guides/deployment/CI_CD_AND_UNIT_TESTS_SUMMARY.md), [DigitalOcean](docs/guides/deployment/DIGITALOCEAN_SETUP.md)

### 📂 Technical & Business (`/docs/`)
- [Implementation Summary](docs/PAYMENT_SYSTEM_IMPLEMENTATION_SUMMARY.md)
- [Payroll Process Flow](docs/payroll_process_flow.md)
- [Database Verification](docs/database_verification_report.md)

## Getting Started

1. **Prerequisites**: Ensure you have Flutter, Docker, and Node.js installed.
2. **Configuration**: Copy `.env.example` to `.env` in the backend directory and configure your keys.
   - See [Configuration Guide](docs/guides/setup/CONFIGURATION.md) for details.
3. **Run Services**: Use Docker Compose to start the backend and database.
   ```bash
   docker-compose up -d
   ```
4. **Run Mobile**:
   ```bash
   cd mobile
   flutter run
   ```

## License

Proprietary - PayKey Inc.
