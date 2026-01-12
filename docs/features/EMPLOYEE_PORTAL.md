# Employee Portal Feature

## Overview
Self-service portal for employees to view their payslips, leave balances, and tax documents.

## Access
Employees login with credentials provided by their employer.

## Features Available

| Feature | Description |
|---------|-------------|
| **Dashboard** | Overview of employment status |
| **Payslips** | View past payslips by period |
| **P9 Certificate** | Annual tax certificate |
| **Leave Balance** | View remaining leave days |
| **Profile** | View personal details |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/employee-portal/dashboard` | Employee dashboard |
| GET | `/employee-portal/payslips` | List payslips |
| GET | `/employee-portal/payslips/:id` | View payslip details |
| GET | `/employee-portal/p9/:year` | Get P9 certificate |
| GET | `/employee-portal/leave-balance` | Leave balance |

## Mobile UI
- **Dashboard**: `mobile/lib/features/employee_portal/presentation/pages/employee_dashboard_page.dart`
- **Payslips**: `mobile/lib/features/employee_portal/presentation/pages/employee_payslips_page.dart`
- **P9**: `mobile/lib/features/employee_portal/presentation/pages/employee_p9_page.dart`

## Employee vs Employer Mode
App detects user role and shows appropriate interface:
- Employer: Full management features
- Employee: Read-only self-service portal

## Current Configuration Status
- ✅ Employee login
- ✅ Payslip viewing
- ✅ P9 certificate viewing
- ✅ Leave balance display

## Known Gaps
| Gap | Status |
|-----|--------|
| Payslip download/PDF | ❌ Coming soon |
| Leave request submission | ⚠️ Partial |
