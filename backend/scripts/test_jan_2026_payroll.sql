ackend/test_jan_2026_payroll.sql</path>
<content">-- Test payroll calculations for January 2026
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

-- Test 2: Simulate payroll calculation for KES 50,000 salary in Jan 2026
WITH sample_salary AS (
  SELECT 50000 as gross_salary, '2026-01-15'::date as calc_date
),
nssf_calc AS (
  SELECT 
    s.gross_salary,
    CASE 
      WHEN t.taxType = 'NSSF_TIER1' THEN
        LEAST(s.gross_salary, (t.configuration->'tiers'->0->>'salaryTo')::numeric) * (t.configuration->'tiers'->0->>'rate')::numeric
      ELSE 0
    END as tier1_amount,
    CASE 
      WHEN t.taxType = 'NSSF_TIER2' AND s.gross_salary > 8000 THEN
        LEAST(
          s.gross_salary - 8000,
          ((t.configuration->'tiers'->0->>'salaryTo')::numeric - (t.configuration->'tiers'->0->>'salaryFrom')::numeric)
        ) * (t.configuration->'tiers'->0->>'rate')::numeric
      ELSE 0
    END as tier2_amount
  FROM sample_salary s
  CROSS JOIN tax_configs t
  WHERE t.taxType IN ('NSSF_TIER1', 'NSSF_TIER2')
    AND t.effectiveFrom <= s.calc_date
    AND (t.effectiveTo IS NULL OR t.effectiveTo >= s.calc_date)
    AND t.isActive = true
),
nssf_total AS (
  SELECT 
    gross_salary,
    SUM(tier1_amount) as total_nssf_tier1,
    SUM(tier2_amount) as total_nssf_tier2,
    SUM(tier1_amount + tier2_amount) as total_nssf
  FROM nssf_calc
  GROUP BY gross_salary
),
shif_calc AS (
  SELECT 
    s.gross_salary,
    GREATEST(
      s.gross_salary * (t.configuration->>'percentage')::numeric / 100,
      COALESCE(t.configuration->>'minAmount', '0')::numeric
    ) as shif_amount
  FROM sample_salary s
  CROSS JOIN tax_configs t
  WHERE t.taxType = 'SHIF'
    AND t.effectiveFrom <= s.calc_date
    AND (t.effectiveTo IS NULL OR t.effectiveTo >= s.calc_date)
    AND t.isActive = true
  LIMIT 1
),
housing_calc AS (
  SELECT 
    s.gross_salary,
    s.gross_salary * (t.configuration->>'percentage')::numeric / 100 as housing_amount
  FROM sample_salary s
  CROSS JOIN tax_configs t
  WHERE t.taxType = 'HOUSING_LEVY'
    AND t.effectiveFrom <= s.calc_date
    AND (t.effectiveTo IS NULL OR t.effectiveTo >= s.calc_date)
    AND t.isActive = true
  LIMIT 1
)
SELECT 
  'JAN 2026 PAYROLL CALCULATION' as test_name,
  n.gross_salary as gross_salary,
  n.total_nssf as nssf_deduction,
  s.shif_amount as shif_deduction,
  h.housing_amount as housing_levy_deduction,
  -- PAYE calculation (simplified)
  CASE 
    WHEN n.gross_salary <= 24000 THEN n.gross_salary * 0.10
    WHEN n.gross_salary <= 32333 THEN 24000 * 0.10 + (n.gross_salary - 24000) * 0.25
    WHEN n.gross_salary <= 500000 THEN 24000 * 0.10 + (32333 - 24000) * 0.25 + (n.gross_salary - 32333) * 0.30
    ELSE 24000 * 0.10 + (32333 - 24000) * 0.25 + (500000 - 32333) * 0.30 + (n.gross_salary - 500000) * 0.325
  END - 2400 as paye_deduction, -- Simplified with personal relief
  (n.total_nssf + s.shif_amount + h.housing_amount + 
   CASE 
    WHEN n.gross_salary <= 24000 THEN n.gross_salary * 0.10
    WHEN n.gross_salary <= 32333 THEN 24000 * 0.10 + (n.gross_salary - 24000) * 0.25
    WHEN n.gross_salary <= 500000 THEN 24000 * 0.10 + (32333 - 24000) * 0.25 + (n.gross_salary - 32333) * 0.30
    ELSE 24000 * 0.10 + (32333 - 24000) * 0.25 + (500000 - 32333) * 0.30 + (n.gross_salary - 500000) * 0.325
   END - 2400) as total_deductions,
  n.gross_salary - (n.total_nssf + s.shif_amount + h.housing_amount + 
   CASE 
    WHEN n.gross_salary <= 24000 THEN n.gross_salary * 0.10
    WHEN n.gross_salary <= 32333 THEN 24000 * 0.10 + (n.gross_salary - 24000) * 0.25
    WHEN n.gross_salary <= 500000 THEN 24000 * 0.10 + (32333 - 24000) * 0.25 + (n.gross_salary - 32333) * 0.30
    ELSE 24000 * 0.10 + (32333 - 24000) * 0.25 + (500000 - 32333) * 0.30 + (n.gross_salary - 500000) * 0.325
   END - 2400) as net_pay
FROM nssf_total n
CROSS JOIN shif_calc s
CROSS JOIN housing_calc h;
