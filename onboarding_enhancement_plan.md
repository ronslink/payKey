# Onboarding Enhancement Plan

## Current State Analysis

### What's Currently Collected
The onboarding page (`OnboardingPage`) currently collects:
- ✅ KRA PIN (required)
- ✅ ID/Passport Number (required)
- ✅ NSSF Number (optional)
- ✅ NHIF Number (optional)
- ✅ Physical Address (optional)
- ✅ City/County (optional)
- ✅ Country (required)

### Missing Critical Fields

Based on the `User` entity in the backend, the following fields are **missing** from onboarding:

#### Personal Information
1. **firstName** - Required for user identification
2. **lastName** - Required for user identification
3. **idType** - Enum: NATIONAL_ID, ALIEN_ID, PASSPORT (required for compliance)
4. **nationalityId** - Country of nationality (different from residence)

#### Residency & Tax Status
5. **isResident** - Boolean flag (critical for tax calculations)
6. **countryOfOrigin** - For non-residents

### Application Features Requiring Compliance Data

1. **Payroll Processing**
   - Requires: KRA PIN, NSSF, NHIF for tax calculations
   - Requires: Residency status for correct tax rates
   - Requires: ID Type for legal documentation

2. **Tax Management**
   - Requires: KRA PIN (mandatory)
   - Requires: Residency status (affects tax brackets)
   - Requires: Complete personal information for filing

3. **Workers Management**
   - Workers also need: KRA PIN, NSSF, NHIF, ID Number
   - Employer (User) must have complete profile to manage workers compliantly

4. **Time & Leave Tracking**
   - Requires: Employment start date (for leave accrual)
   - Requires: Legal identification

## Compliance Requirements

### Kenya Revenue Authority (KRA) Compliance
- **KRA PIN**: Mandatory for all taxpayers
- **ID Type**: Must specify NATIONAL_ID, ALIEN_ID, or PASSPORT
- **Residency Status**: Affects tax rates (residents vs non-residents)

### Social Security (NSSF/NHIF)
- **NSSF Number**: Required for pension contributions
- **NHIF/SHIF Number**: Required for health insurance

### Employment Law
- **Full Legal Name**: Required for contracts
- **ID Number**: Required for verification
- **Nationality**: Required for work permit validation

## Proposed Enhancements

### Phase 1: Add Missing Required Fields (CRITICAL)

#### Step 1: Personal Information Section
Add to onboarding form:
```dart
- First Name (required)
- Last Name (required)
- ID Type (dropdown: National ID, Alien ID, Passport) (required)
- Nationality (country dropdown) (required)
```

#### Step 2: Residency & Tax Status Section
Add to onboarding form:
```dart
- Are you a Kenya resident? (Yes/No toggle) (required)
- If No: Country of Origin (dropdown)
```

### Phase 2: Improve User Experience

#### Multi-Step Form
Instead of one long form, break into logical steps:

**Step 1: Personal Details**
- First Name
- Last Name
- Email (pre-filled from registration)

**Step 2: Identification**
- ID Type (National ID / Alien ID / Passport)
- ID Number
- Nationality

**Step 3: Tax & Compliance**
- KRA PIN
- Are you a Kenya resident?
- If non-resident: Country of Origin
- NSSF Number
- NHIF/SHIF Number

**Step 4: Location**
- Country of Residence
- City/County
- Physical Address

**Step 5: Review & Confirm**
- Summary of all entered data
- Checkbox: "I confirm this information is accurate"
- Submit button

### Phase 3: Validation & Help Text

#### Field-Level Validation
- **KRA PIN**: Format validation (A000000000A)
- **ID Number**: Length validation based on ID Type
- **NSSF**: Format validation if provided
- **NHIF**: Format validation if provided

#### Help Text & Tooltips
- Explain why each field is needed
- Link to KRA website for PIN registration
- Provide examples of correct formats

### Phase 4: Backend Updates

#### Update User Profile Endpoint
Ensure `updateUserProfile` accepts:
```typescript
{
  firstName: string;
  lastName: string;
  idType: IdType;
  idNumber: string;
  nationalityId: string;
  kraPin: string;
  nssfNumber?: string;
  nhifNumber?: string;
  isResident: boolean;
  countryOfOrigin?: string;
  countryId: string;
  city?: string;
  address?: string;
}
```

#### Set Onboarding Completion Flag
After successful submission:
```typescript
user.isOnboardingCompleted = true;
```

## Implementation Priority

### HIGH Priority (Blocking Compliance)
1. ✅ First Name, Last Name
2. ✅ ID Type selection
3. ✅ Nationality
4. ✅ Residency status (isResident)

### MEDIUM Priority (Improves UX)
1. Multi-step form
2. Field validation
3. Help text & tooltips

### LOW Priority (Nice to Have)
1. Auto-format inputs (KRA PIN, phone numbers)
2. Save progress (draft mode)
3. Skip for now option (with limitations)

## Success Criteria

- [ ] All required User entity fields are collected
- [ ] Form validates data before submission
- [ ] Backend correctly stores all onboarding data
- [ ] `isOnboardingCompleted` flag is set to true
- [ ] User can proceed to use all app features
- [ ] Tax calculations work correctly with collected data
- [ ] Payroll processing has all required compliance data

## Technical Notes

### Frontend Changes
- File: `mobile/lib/features/onboarding/presentation/pages/onboarding_page.dart`
- Add new form fields
- Implement multi-step navigation (optional)
- Add validation logic

### Backend Changes
- File: `backend/src/modules/users/users.service.ts`
- Update `updateUserProfile` to handle new fields
- Validate required fields
- Set `isOnboardingCompleted = true`

### Data Flow
```
OnboardingPage → ApiService.updateUserProfile() → UsersController → UsersService → User Entity
```
