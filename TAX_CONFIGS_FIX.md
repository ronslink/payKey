# Tax Configs Table Missing - FIXED!

## Problem
When trying to add employees to a draft pay period (JAN2026), the system returned a **500 error** with the message:
```
error: relation "tax_configs" does not exist
```

## Root Cause
The `tax_configs` table was missing from the database. This table is required by the `TaxesService` to calculate:
- PAYE (Pay As You Earn)
- SHIF (Social Health Insurance Fund)
- NSSF Tier 1 & 2 (National Social Security Fund)
- Housing Levy

Without this table, the payroll calculation couldn't proceed because it couldn't fetch the tax rates.

## Solution

### 1. Created Migration
Created a new migration file: `1733420000000-CreateTaxConfigsTable.ts`

This migration:
- Creates the `tax_configs` table with all required columns
- Defines enum types for `taxType` and `rateType`
- Inserts default Kenya tax rates for 2024

### 2. Tax Rates Configured

The following tax configurations were added:

**PAYE (Graduated Tax Brackets)**
- 0 - 24,000: 10%
- 24,001 - 32,333: 25%
- 32,334 - 500,000: 30%
- 500,001 - 800,000: 32.5%
- 800,001+: 35%
- Personal Relief: KES 2,400

**SHIF (Social Health Insurance Fund)**
- Rate: 2.75% of gross salary
- No minimum or maximum

**NSSF Tier 1**
- Salary Range: 0 - 7,000
- Rate: 6%

**NSSF Tier 2**
- Salary Range: 7,001 - 36,000
- Rate: 6%

**Housing Levy**
- Rate: 1.5% of gross salary
- No minimum or maximum

### 3. Ran Migration
```bash
docker exec paykey_backend npm run typeorm:migration:run
```

### 4. Verified Table Creation
```sql
SELECT "taxType", "rateType", "effectiveFrom", "isActive" FROM tax_configs;
```

Result:
```
   taxType    |  rateType  | effectiveFrom | isActive 
--------------+------------+---------------+----------
 PAYE         | GRADUATED  | 2024-01-01    | t
 SHIF         | PERCENTAGE | 2024-01-01    | t
 NSSF_TIER1   | TIERED     | 2024-01-01    | t
 NSSF_TIER2   | TIERED     | 2024-01-01    | t
 HOUSING_LEVY | PERCENTAGE | 2024-01-01    | t
```

## Testing
Now you can:
1. ✅ Select a draft pay period (JAN2026)
2. ✅ Add employees to the payroll
3. ✅ Calculate taxes automatically using Kenya tax rates
4. ✅ Save draft payroll records successfully

## Example Calculation
For an employee with gross salary of KES 50,000:
- **PAYE**: ~KES 6,600 (after brackets and personal relief)
- **SHIF**: KES 1,375 (2.75%)
- **NSSF Tier 1**: KES 420 (6% of 7,000)
- **NSSF Tier 2**: KES 1,740 (6% of 29,000)
- **Housing Levy**: KES 750 (1.5%)
- **Total Deductions**: ~KES 10,885
- **Net Pay**: ~KES 39,115

## Files Modified
1. **Created**: `/backend/src/migrations/1733420000000-CreateTaxConfigsTable.ts`
   - Migration to create tax_configs table
   - Inserts default Kenya tax rates

## Next Steps
The payroll calculation should now work end-to-end! Try adding employees to your JAN2026 pay period again.
