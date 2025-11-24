-- Complete Demo Data Script for Pay Periods Management System (Fixed Column Names)
-- This script creates realistic demo data for testing the complete payroll workflow

-- Clean existing demo data (be careful with this in production!)
DELETE FROM payroll_records WHERE "workerId" IN (SELECT id FROM workers WHERE name LIKE '%Kamau%' OR name LIKE '%Wanjiku%' OR name LIKE '%Ochieng%' OR name LIKE '%Achieng%' OR name LIKE '%Kiprotich%');
DELETE FROM pay_periods WHERE name LIKE '%2024%';

-- Verify we have our test user
DO $$
DECLARE
    demo_user_id UUID := 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';
BEGIN
    RAISE NOTICE 'Using demo user ID: %', demo_user_id;

    -- Create Pay Periods for the last 3 months (bi-weekly periods)
    INSERT INTO pay_periods ("userId", name, "startDate", "endDate", status) VALUES
    (demo_user_id, 'August 2024 - Week 1', '2024-08-01', '2024-08-14', 'COMPLETED'),
    (demo_user_id, 'August 2024 - Week 2', '2024-08-15', '2024-08-28', 'COMPLETED'),
    (demo_user_id, 'August 2024 - Week 3', '2024-08-29', '2024-09-11', 'COMPLETED'),
    (demo_user_id, 'August 2024 - Week 4', '2024-09-12', '2024-09-25', 'COMPLETED'),
    (demo_user_id, 'September 2024 - Week 1', '2024-09-26', '2024-10-09', 'COMPLETED'),
    (demo_user_id, 'September 2024 - Week 2', '2024-10-10', '2024-10-23', 'COMPLETED'),
    (demo_user_id, 'September 2024 - Week 3', '2024-10-24', '2024-11-06', 'COMPLETED'),
    (demo_user_id, 'September 2024 - Week 4', '2024-11-07', '2024-11-20', 'COMPLETED'),
    (demo_user_id, 'October 2024 - Week 1', '2024-11-21', '2024-12-04', 'COMPLETED'),
    (demo_user_id, 'October 2024 - Week 2', '2024-12-05', '2024-12-18', 'COMPLETED');

    RAISE NOTICE 'Created 10 pay periods for demo data';
    
    -- Create payroll records for existing worker + demo workers
    -- Using the existing worker 'Jane Doe' and simulating other workers
    
    -- First, let's see what workers we have
    INSERT INTO payroll_records ("userId", "workerId", "periodStart", "periodEnd", "grossSalary", "netSalary", "taxAmount", "paymentStatus", "paymentMethod", "paymentDate")
    SELECT 
        demo_user_id,
        w.id,
        pp."startDate",
        pp."endDate",
        -- Calculate realistic gross salary based on employment type
        CASE 
            WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 120000 / 2  -- Monthly worker -> bi-weekly
            WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 15000 / 2
            ELSE 10000 -- Hourly workers get flat rate for demo
        END,
        -- Net salary (after tax and deductions)
        CASE 
            WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 95000 / 2
            WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 12500 / 2
            ELSE 8000
        END,
        -- Tax amount
        CASE 
            WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 25000 / 2
            WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 2500 / 2
            ELSE 2000
        END,
        'paid',
        'mpesa',
        pp."endDate" + interval '3 days'
    FROM workers w
    CROSS JOIN pay_periods pp
    WHERE w."userId" = demo_user_id
    AND pp."userId" = demo_user_id;

    RAISE NOTICE 'Created payroll records for all workers and pay periods';

    -- Update pay period totals
    UPDATE pay_periods 
    SET 
        "totalGrossAmount" = (
            SELECT COALESCE(SUM("grossSalary"), 0)
            FROM payroll_records pr 
            WHERE pr."periodStart" = pay_periods."startDate" 
            AND pr."periodEnd" = pay_periods."endDate"
        ),
        "totalNetAmount" = (
            SELECT COALESCE(SUM("netSalary"), 0)
            FROM payroll_records pr 
            WHERE pr."periodStart" = pay_periods."startDate" 
            AND pr."periodEnd" = pay_periods."endDate"
        ),
        "totalTaxAmount" = (
            SELECT COALESCE(SUM("taxAmount"), 0)
            FROM payroll_records pr 
            WHERE pr."periodStart" = pay_periods."startDate" 
            AND pr."periodEnd" = pay_periods."endDate"
        ),
        "totalWorkers" = (
            SELECT COUNT(*)
            FROM payroll_records pr 
            WHERE pr."periodStart" = pay_periods."startDate" 
            AND pr."periodEnd" = pay_periods."endDate"
        ),
        "processedWorkers" = (
            SELECT COUNT(*)
            FROM payroll_records pr 
            WHERE pr."periodStart" = pay_periods."startDate" 
            AND pr."periodEnd" = pay_periods."endDate"
            AND pr."paymentStatus" = 'paid'
        );

    RAISE NOTICE 'Updated pay period totals';
    
END $$;

-- Show final summary
SELECT 
    'Demo Data Summary' as section,
    (SELECT COUNT(*) FROM pay_periods WHERE name LIKE '%2024%') as total_pay_periods,
    (SELECT COUNT(*) FROM workers WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820') as total_workers,
    (SELECT COUNT(*) FROM payroll_records WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820') as total_payroll_records
UNION ALL
SELECT 
    'Financial Summary',
    (SELECT SUM("totalGrossAmount") FROM pay_periods WHERE name LIKE '%2024%')::text,
    (SELECT SUM("totalNetAmount") FROM pay_periods WHERE name LIKE '%2024%')::text,
    (SELECT SUM("totalTaxAmount") FROM pay_periods WHERE name LIKE '%2024%')::text;