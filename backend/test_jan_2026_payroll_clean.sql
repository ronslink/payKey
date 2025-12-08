-- Test payroll calculations for January 2026
-- This script verifies that all tax configurations are accessible for Jan 2026

-- Test 1: Check if all tax configurations exist for Jan 2026
SELECT 
    'PAYE Config' as config_type,
    tc.taxType,
    tc.effectiveFrom,
    tc.configuration->'brackets' as brackets,
    tc.isActive
FROM tax_configs tc 
WHERE tc.taxType = 'PAYE' 
  AND tc.effectiveFrom <= '2026-01-15'::date
  AND (tc.effectiveTo IS NULL OR tc.effectiveTo >= '2026-01-15'::date)
  AND tc.isActive = true
ORDER BY tc.effectiveFrom DESC 
LIMIT 1

UNION ALL

SELECT 
    'NSSF_TIER1 Config' as config_type,
    tc.taxType,
    tc.effectiveFrom,
    tc.configuration->'tiers' as tiers,
    tc.isActive
FROM tax_configs tc 
WHERE tc.taxType = 'NSSF_TIER1' 
  AND tc.effectiveFrom <= '2026-01-15'::date
  AND (tc.effectiveTo IS NULL OR tc.effectiveTo >= '2026-01-15'::date)
  AND tc.isActive = true
ORDER BY tc.effectiveFrom DESC 
LIMIT 1

UNION ALL

SELECT 
    'NSSF_TIER2 Config' as config_type,
    tc.taxType,
    tc.effectiveFrom,
    tc.configuration->'tiers' as tiers,
    tc.isActive
FROM tax_configs tc 
WHERE tc.taxType = 'NSSF_TIER2' 
  AND tc.effectiveFrom <= '2026-01-15'::date
  AND (tc.effectiveTo IS NULL OR tc.effectiveTo >= '2026-01-15'::date)
  AND tc.isActive = true
ORDER BY tc.effectiveFrom DESC 
LIMIT 1

UNION ALL

SELECT 
    'SHIF Config' as config_type,
    tc.taxType,
    tc.effectiveFrom,
    json_build_object('percentage', tc.configuration->'percentage', 'minAmount', tc.configuration->'minAmount') as config,
    tc.isActive
FROM tax_configs tc 
WHERE tc.taxType = 'SHIF' 
  AND tc.effectiveFrom <= '2026-01-15'::date
  AND (tc.effectiveTo IS NULL OR tc.effectiveTo >= '2026-01-15'::date)
  AND tc.isActive = true
ORDER BY tc.effectiveFrom DESC 
LIMIT 1

UNION ALL

SELECT 
    'HOUSING_LEVY Config' as config_type,
    tc.taxType,
    tc.effectiveFrom,
    json_build_object('percentage', tc.configuration->'percentage') as config,
    tc.isActive
FROM tax_configs tc 
WHERE tc.taxType = 'HOUSING_LEVY' 
  AND tc.effectiveFrom <= '2026-01-15'::date
  AND (tc.effectiveTo IS NULL OR tc.effectiveTo >= '2026-01-15'::date)
  AND tc.isActive = true
ORDER BY tc.effectiveFrom DESC 
LIMIT 1;