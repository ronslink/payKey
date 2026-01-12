# Onboarding & Guided Tour Feature

## Overview
First-time user onboarding flow and guided tour for new employers.

## Onboarding Flow
1. **Registration** → User creates account
2. **Company Setup** → Enter company details
3. **First Worker** → Add first employee
4. **Guided Tour** → Interactive walkthrough of features

## Guided Tour Steps
The tour highlights key features for new users:
1. Dashboard overview
2. Adding workers
3. Running payroll
4. Viewing reports
5. Managing subscriptions

## Mobile UI
- **Onboarding Pages**: `mobile/lib/features/onboarding/presentation/pages/`
- **Guided Tour**: Triggered after first login post-onboarding
- **Tour Component**: Overlay-based step-by-step walkthrough

## Tour Behavior
- Shows only once (on first navigation from onboarding)
- Stored flag in local storage to prevent repeat
- Can be manually re-triggered from settings

## Employee Portal
Separate portal for employees to:
- View payslips
- Check leave balance
- View P9 tax certificates

**Employee Portal Path**: `mobile/lib/features/employee_portal/`

## Current Configuration Status
- ✅ Onboarding screens implemented
- ✅ Guided tour with step highlights
- ✅ One-time display logic
- ✅ Employee self-service portal

## Known Gaps
| Gap | Status |
|-----|--------|
| Tour replay button | ⚠️ Needs settings integration |
| Video tutorials | ❌ Not implemented |
