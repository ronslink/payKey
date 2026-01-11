-- Fix NSSF in payroll_records for Sam Olago's 2025 data
-- NSSF 2025 Rates:
-- Tier 1: 6% of first KES 8,000 = KES 480
-- Tier 2: 6% of (salary - 8,000) up to 72,000

DO $$
DECLARE
    v_user_id UUID;
    v_updated INT := 0;
BEGIN
    -- Get Sam's user ID
    SELECT id INTO v_user_id FROM users WHERE email = 'kingpublish@gmail.com';
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE 'User not found';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found user ID: %', v_user_id;
    
    -- Update all payroll_records for 2025 periods where NSSF is 0
    UPDATE payroll_records pr
    SET 
        "taxBreakdown" = jsonb_set(
            jsonb_set(
                COALESCE("taxBreakdown"::jsonb, '{}'::jsonb),
                '{nssf}',
                to_jsonb(
                    ROUND(
                        LEAST("grossSalary"::numeric, 8000) * 0.06 +
                        GREATEST(0, LEAST("grossSalary"::numeric - 8000, 64000)) * 0.06,
                        2
                    )
                )
            ),
            '{totalDeductions}',
            to_jsonb(
                ROUND(
                    LEAST("grossSalary"::numeric, 8000) * 0.06 +
                    GREATEST(0, LEAST("grossSalary"::numeric - 8000, 64000)) * 0.06 +
                    COALESCE(("taxBreakdown"::jsonb->>'nhif')::numeric, 0) +
                    COALESCE(("taxBreakdown"::jsonb->>'housingLevy')::numeric, 0) +
                    COALESCE(("taxBreakdown"::jsonb->>'paye')::numeric, 0),
                    2
                )
            )
        ),
        "netSalary" = ROUND(
            "grossSalary"::numeric - (
                LEAST("grossSalary"::numeric, 8000) * 0.06 +
                GREATEST(0, LEAST("grossSalary"::numeric - 8000, 64000)) * 0.06 +
                COALESCE(("taxBreakdown"::jsonb->>'nhif')::numeric, 0) +
                COALESCE(("taxBreakdown"::jsonb->>'housingLevy')::numeric, 0) +
                COALESCE(("taxBreakdown"::jsonb->>'paye')::numeric, 0)
            ),
            2
        )
    WHERE "userId" = v_user_id
      AND "payPeriodId" IN (
          SELECT id FROM pay_periods 
          WHERE "userId" = v_user_id 
          AND name LIKE '%2025%'
      )
      AND COALESCE(("taxBreakdown"::jsonb->>'nssf')::numeric, 0) = 0;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RAISE NOTICE 'Updated % payroll records with correct NSSF', v_updated;
    
END $$;

-- Show updated records
SELECT 
    w.name as worker_name,
    pp.name as period,
    pr."grossSalary",
    pr."taxBreakdown"->>'nssf' as nssf,
    pr."taxBreakdown"->>'nhif' as nhif,
    pr."taxBreakdown"->>'housingLevy' as housing_levy,
    pr."taxBreakdown"->>'totalDeductions' as total_deductions,
    pr."netSalary"
FROM payroll_records pr
JOIN workers w ON w.id = pr."workerId"
JOIN pay_periods pp ON pp.id = pr."payPeriodId"
WHERE pr."userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
  AND pp.name LIKE '%2025%'
ORDER BY pp."startDate" DESC, w.name
LIMIT 10;
