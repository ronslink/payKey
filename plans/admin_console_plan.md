# Admin Console Architecture Plan

## Executive Summary

This document outlines architectural options and recommendations for implementing a dedicated admin console for the PayKey platform. The admin console will enable administrators to manage subscription pricing, update tax configurations, and view analytics—separate from the main mobile application used by end users.

---

## 1. Current System Analysis

### Existing Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PAYKEY PLATFORM                          │
├─────────────────────────────────────────────────────────────────┤
│  Mobile App (Flutter)          │  Backend API (NestJS)          │
│  • BLoC state management       │  • TypeORM + PostgreSQL        │
│  • Clean Architecture          │  • Redis caching               │
│  • 25+ feature modules         │  • Stripe + M-Pesa integration │
│                                 │                               │
│  Current Modules:              │  Key Modules:                  │
│  • Auth                        │  • Auth (JWT)                  │
│  • Workers                     │  • Users                       │
│  • Payroll                     │  • Subscriptions               │
│  • Taxes                       │  • Tax-Config                  │
│  • Subscriptions               │  • Payments                    │
│  • Gov Integrations            │  • Reports                     │
│  • Reports                     │  • System-Config               │
└─────────────────────────────────────────────────────────────────┘
```

### Key Observations

1. **Subscription Pricing**: Currently hardcoded in [`subscription-plans.config.ts`](backend/src/modules/subscriptions/subscription-plans.config.ts) as static constants
2. **Tax Configuration**: Stored in database with effective dates, supports multiple rate types (PAYE, SHIF, NSSF, Housing Levy)
3. **No Admin Dashboard**: All configuration changes require database access or code deployments
4. **Basic Reports**: Existing `reports` module provides limited functionality

---

## 2. Admin Console Options

### Option A: Separate Admin Application (Recommended)

**Approach**: Create a completely separate admin application (web-based) with its own codebase, deployed independently.

**Technology Options**:
- **React/Vue Admin Framework**: AdminJS, Refine, React-Admin
- **Custom React + Tailwind**: Maximum flexibility
- **NestJS Backend**: Reuse existing backend with admin-specific modules

**Pros**:
- ✅ Complete isolation from mobile app
- ✅ Independent deployment cycles
- ✅ Different authentication/authorization model
- ✅ No impact on mobile app performance
- ✅ Can use different UI framework (web vs mobile)
- ✅ Scalable to multi-tenant SaaS model

**Cons**:
- ❌ Higher initial development effort
- ❌ Duplication of some backend logic
- ❌ Separate maintenance burden

**Architecture**:
```
┌─────────────────────┐     ┌─────────────────────┐
│   Mobile App        │     │   Admin Console      │
│   (Flutter)         │     │   (React/Next.js)    │
└──────────┬──────────┘     └──────────┬──────────┘
           │                          │
           └───────────┬──────────────┘
                       │
           ┌───────────▼──────────────┐
           │   Shared Backend API    │
           │   (NestJS)              │
           │   • REST API            │
           │   • GraphQL (optional)  │
           └───────────┬──────────────┘
                       │
           ┌───────────▼──────────────┐
           │   PostgreSQL + Redis   │
           └─────────────────────────┘
```

### Option B: Admin Module Within Existing Backend

**Approach**: Add admin-specific controllers and routes to the existing NestJS backend, with a separate admin web UI.

**Pros**:
- ✅ Reuses existing backend infrastructure
- ✅ Consistent API design
- ✅ Easier to share data models

**Cons**:
- ❌ Mixed concerns in codebase
- ❌ Authentication complexity (admin vs user)
- ❌ Potential performance impact
- ❌ Deployment couples admin changes to main app

### Option C: Hybrid Approach (Backend Extensions + Admin UI)

**Approach**: Create admin-specific API endpoints in the backend, but use a lightweight admin UI framework that can be deployed separately.

**Pros**:
- ✅ Balanced separation and reuse
- ✅ Can use AdminJS or similar with custom endpoints

**Cons**:
- ❌ Customization of admin frameworks can be complex

---

## 3. Recommended Architecture: Option A

### Recommended Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Frontend** | React + Vite + Tailwind CSS | Modern, performant, large ecosystem |
| **UI Components** | shadcn/ui | Accessible, customizable, well-maintained |
| **State Management** | TanStack Query (React Query) | Excellent for server state |
| **Charts/Analytics** | Recharts or Tremor | Good React integration |
| **API Client** | Axios + TanStack Query | Type-safe API calls |
| **Backend** | Extend existing NestJS | Reuse authentication, services |
| **Admin Auth** | JWT with role-based access | Leverage existing auth module |

### Admin Console Directory Structure

```
admin-console/
├── src/
│   ├── app/
│   │   ├── layout/              # Admin layout with sidebar
│   │   ├── pages/                # Page components
│   │   ├── components/           # Shared UI components
│   │   ├── hooks/                # Custom React hooks
│   │   ├── services/             # API client services
│   │   ├── stores/               # State management
│   │   └── utils/                # Utility functions
│   ├── features/
│   │   ├── dashboard/           # Analytics dashboard
│   │   ├── subscriptions/        # Subscription management
│   │   ├── tax-config/           # Tax configuration
│   │   ├── users/                # User management
│   │   ├── reports/              # Analytics & reports
│   │   └── settings/             # System settings
│   └── main.tsx
├── package.json
├── vite.config.ts
└── tsconfig.json
```

---

## 4. Feature Specifications

### 4.1 Dashboard & Analytics

**Key Metrics to Display**:
```
┌────────────────────────────────────────────────────────────────┐
│  📊 ADMIN DASHBOARD                                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Total Users │  │ Active Subs │  │ MRR         │          │
│  │     1,247   │  │      892    │  │ $45,230     │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  📈 Revenue Trend (Last 12 Months)                      │  │
│  │                                                         │  │
│  │    $50K ┤                                                │  │
│  │    $40K ┤    ▂▃▅▇▆▄▃▅▆▄▃▅▆▄▃▅▆                          │  │
│  │    $30K ┤    ▂▃▅▇▆▄▃▅▆▄▃▅▆▄▃▅▆                          │  │
│  │    $20K ┤    ▂▃▅▇▆▄▃▅▆▄▃▅▆▄▃▅▆                          │  │
│  │    $10K ┤    ▂▃▅▇▆▄▃▅▆▄▃▅▆▄▃▅▆                          │  │
│  │        └────────────────────────────────────────────▶   │  │
│  │         Jan  Feb  Mar  Apr  May  Jun ...               │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌─────────────┐  ┌─────────────┐                             │
│  │ Subs by Plan│  │ Top Countries│                            │
│  │ Free:  35%  │  │ Kenya:  92%  │                             │
│  │ Basic: 40%  │  │ Uganda:  5%  │                             │
│  │ Gold:  18%  │  │ Tanzania: 3%│                             │
│  │ Platinum: 7%│  │             │                             │
│  └─────────────┘  └─────────────┘                             │
└────────────────────────────────────────────────────────────────┘
```

**Analytics Components**:
- Revenue metrics (MRR, ARR, churn rate)
- User growth trends
- Subscription distribution
- Geographic insights
- Feature usage analytics
- Payroll processed volume
- Tax submission statistics

### 4.2 Subscription Pricing Management

**Current Static Configuration**:
```typescript
// backend/src/modules/subscriptions/subscription-plans.config.ts
export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
  {
    tier: 'BASIC',
    name: 'Basic',
    priceUSD: 9.99,
    priceKES: 1300,
    priceUSDYearly: 99.99,
    priceKESYearly: 13000,
    workerLimit: 5,
    features: [...],
  },
  // ... other plans
];
```

**Required Changes for Admin Management**:
1. Move configuration from static code to database
2. Create admin UI to CRUD subscription plans
3. API endpoints for plan management
4. Version history for plan changes
5. Stripe price sync management

**Admin UI Requirements**:
```
┌────────────────────────────────────────────────────────────────┐
│  💰 SUBSCRIPTION PLANS                                         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  [+ Add New Plan]                                             │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 🥇 GOLD                                                     │ │
│  │ Price: $29.99/month (KES 3,900)                           │ │
│  │ Yearly: $299.99 (KES 39,000)                              │ │
│  │ Workers: 10                                               │ │
│  │ Features: • Up to 10 workers                              │ │
│  │           • Automatic tax calculations                    │ │
│  │           • M-Pesa payments                               │ │
│  │           • P9 Tax Cards                                  │ │
│  │           • Advanced reporting                            │ │
│  │           • Accounting exports                            │ │
│  │ [Edit] [Duplicate] [Deactivate]                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 💎 PLATINUM                                                 │ │
│  │ Price: $49.99/month (KES 6,500)                           │ │
│  │ [Edit] [Duplicate] [Deactivate]                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  ⚠️ Note: Changes to pricing require Stripe price ID updates  │
└────────────────────────────────────────────────────────────────┘
```

### 4.3 Tax Configuration Management

**Current Tax Config Entity**:
```typescript
// backend/src/modules/tax-config/entities/tax-config.entity.ts
export interface TaxConfiguration {
  // For percentage-based (SHIF, Housing Levy)
  percentage?: number;
  minAmount?: number;
  maxAmount?: number;
  
  // For graduated (PAYE)
  brackets?: TaxBracket[];
  
  // For tiered (NSSF)
  tiers?: TaxTier[];
  
  // For banded (NHIF)
  bands?: Array<{ from: number; to: number | null; amount: number }>;
  
  // Reliefs/deductions
  personalRelief?: number;
  insuranceRelief?: number;
  maxInsuranceRelief?: number;
}
```

**Admin UI Requirements**:
```
┌────────────────────────────────────────────────────────────────┐
│  📋 TAX CONFIGURATION                                           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Tax Year: [2025 ▼]                                            │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 📊 PAYE (Progressive Income Tax)      [Active] [Edit]     │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Rate Type: Graduated                                          │ │
│  │ Effective From: 2023-07-01                                  │ │
│  │                                                              │ │
│  │ Tax Brackets:                                               │ │
│  │ ┌────────────────────┬───────────────┬──────────┐            │ │
│  │ │ Monthly Income    │ Rate          │ Notes    │            │ │
│  │ ├────────────────────┼───────────────┼──────────┤            │ │
│  │ │ 0 - 24,000        │ 10%           │ ✓ Edit   │            │ │
│  │ │ 24,001 - 32,333   │ 25%           │ ✓ Edit   │            │ │
│  │ │ 32,334 - 500,000  │ 30%           │ ✓ Edit   │            │ │
│  │ │ 500,001 - 800,000 │ 32.5%         │ ✓ Edit   │            │ │
│  │ │ Above 800,000     │ 35%           │ ✓ Edit   │            │ │
│  │ └────────────────────┴───────────────┴──────────┘            │ │
│  │                                                              │ │
│  │ Personal Relief: KES 2,400          [Edit]                   │ │
│  │ Insurance Relief: 15% (max KES 5,000)  [Edit]               │ │
│  │ Payment Deadline: 9th of following month  [Edit]             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 🏥 SHIF (Social Health Insurance Fund)   [Active] [Edit]   │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Rate: 2.75% of gross salary                                   │ │
│  │ Min: KES 300        Max: No cap                            │ │
│  │ Effective From: 2024-10-01                                  │ │
│  │ [Add Historical Config]                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 🏦 NSSF (Social Security)               [Active] [Edit]     │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Tier 1: 6% of first KES 8,000 (max KES 480)                │ │
│  │ Tier 2: 6% of KES 8,001 - 72,000 (max KES 3,840)           │ │
│  │ Effective From: 2025-02-01                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 🏠 Housing Levy                      [Active] [Edit]        │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │ Employee: 1.5%        Employer: 1.5%                        │ │
│  │ Effective From: 2025-02-01                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  [+] Add New Tax Type                                          │
│  [📜 View Configuration History]                                │
└────────────────────────────────────────────────────────────────┘
```

**Key Features**:
- Visual tax bracket editor with live preview
- Effective dating (future-dated changes)
- Configuration versioning and rollback
- Bulk tax rate updates
- CSV import for multiple bracket updates
- Compliance checklist

### 4.4 User Management

```
┌────────────────────────────────────────────────────────────────┐
│  👥 USER MANAGEMENT                                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Search: [🔍 Search users...]           [Filter] [Export]      │
│                                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ #  │ User          │ Email              │ Plan    │ Status  │ │
│  │----│------------──│───────────────────┼─────────┼─────────│ │
│  │ 1  │ John Doe      │ john@example.com  │ GOLD    │ Active  │ │
│  │ 2  │ Sarah Smith  │ sarah@company.ke   │ PLATINUM│ Active  │ │
│  │ 3  │ Mike Jones   │ mike@startup.co    │ BASIC   │ Trial   │ │
│  │ 4  │ ...          │ ...               │ ...     │ ...     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                │
│  [← Previous] Page 1 of 15 [Next →]                           │
│                                                                │
│  Actions: [Assign Plan] [Export Data] [Send Notification]      │
└────────────────────────────────────────────────────────────────┘
```

---

## 5. Implementation Plan

### Phase 1: Foundation
1. Create admin console project structure (React + Vite)
2. Set up authentication (admin JWT tokens with role-based access)
3. Create base layout with sidebar navigation
4. Set up API client infrastructure
5. Implement admin guard/interceptor for route protection

### Phase 2: Subscription Management
1. Create database migration for subscription plans table
2. Build subscription plans CRUD API endpoints
3. Develop subscription plans admin UI
4. Implement plan change history/audit logging
5. Integrate Stripe price ID management

### Phase 3: Tax Configuration
1. Enhance existing TaxConfig entity for admin management
2. Add version history to tax configurations
3. Build tax configuration admin UI with bracket editors
4. Implement effective dating workflow
5. Add tax calculation preview functionality

### Phase 4: Analytics Dashboard
1. Design analytics data models and aggregation pipelines
2. Build analytics API endpoints
3. Implement dashboard with charts and metrics
4. Add custom report builder
5. Enable data export functionality

### Phase 5: Additional Features
1. System settings management
2. User management capabilities
3. Activity audit logs
4. Notification system
5. Multi-admin support with permissions

---

## 6. Database Schema Changes

### New/Modified Tables

```sql
-- Subscription Plans (new table)
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_usd DECIMAL(10, 2) NOT NULL,
    price_kes DECIMAL(10, 2) NOT NULL,
    price_usd_yearly DECIMAL(10, 2) NOT NULL,
    price_kes_yearly DECIMAL(10, 2) NOT NULL,
    worker_limit INTEGER NOT NULL,
    features JSONB DEFAULT '[]',
    import_access BOOLEAN DEFAULT FALSE,
    is_popular BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    stripe_price_id_monthly VARCHAR(255),
    stripe_price_id_yearly VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Plan Change History (new table)
CREATE TABLE subscription_plan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES subscription_plans(id),
    action VARCHAR(20) NOT NULL, -- CREATE, UPDATE, DEACTIVATE
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tax Config History (enhancement)
ALTER TABLE tax_configs ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;
ALTER TABLE tax_configs ADD COLUMN IF NOT EXISTS changed_by UUID REFERENCES users(id);

-- Admin Users (new table)
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) NOT NULL DEFAULT 'ADMIN', -- SUPER_ADMIN, ADMIN, VIEWER
    permissions JSONB DEFAULT '[]',
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admin Audit Log (new table)
CREATE TABLE admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 7. API Endpoints

### Subscription Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/subscriptions/plans` | List all plans |
| POST | `/admin/subscriptions/plans` | Create new plan |
| GET | `/admin/subscriptions/plans/:id` | Get plan details |
| PUT | `/admin/subscriptions/plans/:id` | Update plan |
| DELETE | `/admin/subscriptions/plans/:id` | Deactivate plan |
| GET | `/admin/subscriptions/plans/:id/history` | Get change history |

### Tax Configuration
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/taxes/configs` | List all tax configs |
| POST | `/admin/taxes/configs` | Create new tax config |
| PUT | `/admin/taxes/configs/:id` | Update tax config |
| GET | `/admin/taxes/configs/:id/history` | Get config history |
| POST | `/admin/taxes/configs/:id/activate` | Activate config |
| GET | `/admin/taxes/calculate-preview` | Preview calculations |

### Analytics
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/analytics/dashboard` | Dashboard metrics |
| GET | `/admin/analytics/revenue` | Revenue data |
| GET | `/admin/analytics/users` | User analytics |
| GET | `/admin/analytics/subscriptions` | Subscription analytics |
| GET | `/admin/analytics/payroll` | Payroll analytics |
| POST | `/admin/reports/custom` | Generate custom report |

### User Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/users` | List users |
| GET | `/admin/users/:id` | Get user details |
| PUT | `/admin/users/:id` | Update user |
| PUT | `/admin/users/:id/subscription` | Update user subscription |
| POST | `/admin/users/:id/notify` | Send notification |

---

## 8. Security Considerations

### Authentication
- Separate admin authentication system
- Super admin role with full access
- Role-based access control (RBAC)
- Session management with JWT
- Two-factor authentication (optional)

### Authorization
```
Admin Roles:
├── SUPER_ADMIN
│   └── Full system access
├── ADMIN
│   ├── Manage subscriptions
│   ├── Manage tax configs
│   ├── View analytics
│   └── Manage users
└── VIEWER
    ├── View analytics
    └── View users (no edit)
```

### Audit Logging
- All admin actions logged
- Change history with before/after values
- IP address and user agent tracking
- Immutable audit records

---

## 9. Recommended Technology Choices

### Frontend Libraries
| Category | Recommendation | Alternative |
|----------|---------------|-------------|
| UI Framework | React + Vite | Next.js |
| Styling | Tailwind CSS | Styled Components |
| UI Components | shadcn/ui | Material UI |
| Charts | Recharts | Chart.js, Tremor |
| Forms | React Hook Form + Zod | Formik |
| Data Fetching | TanStack Query | SWR |
| State Management | Zustand | Redux Toolkit |
| Date Handling | date-fns | Day.js |

### Backend Enhancements
| Component | Recommendation |
|-----------|---------------|
| API Versioning | URL-based versioning (/api/v1/admin/) |
| Rate Limiting | 100 requests/minute for admin |
| Request Validation | class-validator DTOs |
| Logging | Structured JSON logging |
| Monitoring | Add admin-specific metrics |

---

## 10. Estimated Effort by Phase

| Phase | Description | Complexity |
|-------|-------------|------------|
| Phase 1 | Foundation (auth, layout, API client) | Medium |
| Phase 2 | Subscription Management | Medium |
| Phase 3 | Tax Configuration | High (complex UI) |
| Phase 4 | Analytics Dashboard | High (charts, aggregation) |
| Phase 5 | Additional Features | Medium |

---

## 11. Next Steps

1. **Review and approve** this architectural plan
2. **Decide** on admin console technology stack (React recommended)
3. **Prioritize** which features to implement first
4. **Consider** budget and timeline constraints
5. **Begin** with Phase 1: Foundation setup

---

## Questions for Clarification

1. Should the admin console be accessible only internally or also by enterprise customers?
2. Do you need multi-tenant support for different countries' tax configurations?
3. What analytics are most important to you initially?
4. Do you have a preferred UI framework for the admin interface?
5. How many administrators will need access initially?
