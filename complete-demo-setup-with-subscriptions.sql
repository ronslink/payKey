-- Complete Demo Data Setup for testuser@paykey.com
-- This script creates all necessary demo data including workers, subscriptions, payroll, and tax records

-- =============================================================================
-- 1. DEMO WORKERS
-- =============================================================================

-- First, check if workers already exist
DO $$
DECLARE
    worker_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO worker_count FROM workers WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';
    RAISE NOTICE 'Current workers count for demo user: %', worker_count;
END $$;

-- Insert demo workers if they don't exist
INSERT INTO workers (
    "userId", name, "phoneNumber", "salaryGross", "startDate", 
    "employmentType", "isActive", "paymentFrequency", "jobTitle", 
    "hourlyRate", "housingAllowance", "transportAllowance", "mpesaNumber"
) VALUES 
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Jane Doe', 
    '+254700123456', 
    15000.00, 
    '2024-01-15', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Accountant', 
    865.38, 
    0, 
    0, 
    '+254700123456'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Kamau Wanjiku', 
    '+254700234567', 
    120000.00, 
    '2024-02-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Manager', 
    6923.08, 
    15000, 
    8000, 
    '+254700234567'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Ochieng Achieng', 
    '+254700345678', 
    120000.00, 
    '2024-03-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Developer', 
    6923.08, 
    12000, 
    5000, 
    '+254700345678'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Kiprotich Ngeny', 
    '+254700456789', 
    10000.00, 
    '2024-04-01', 
    'HOURLY', 
    true, 
    'WEEKLY', 
    'Contractor', 
    200.00, 
    0, 
    0, 
    '+254700456789'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820', 
    'Mwangi Kamau', 
    '+254700567890', 
    120000.00, 
    '2024-05-01', 
    'FIXED', 
    true, 
    'WEEKLY', 
    'Supervisor', 
    6923.08, 
    10000, 
    6000, 
    '+254700567890'
)
ON CONFLICT (name, "userId") DO NOTHING;

-- =============================================================================
-- 2. SUBSCRIPTION DATA
-- =============================================================================

-- Create subscription for demo user (GOLD tier - supports up to 10 workers)
INSERT INTO subscriptions (
    "userId", tier, status, amount, currency, "startDate", "endDate", "nextBillingDate", 
    "stripeSubscriptionId", "stripePriceId", notes
) VALUES 
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'GOLD',
    'ACTIVE',
    3600.00,  -- KES price
    'KES',
    '2024-01-01'::timestamptz,
    '2025-01-01'::timestamptz,
    '2024-12-01'::timestamptz,
    'sub_demo_gold_123456789',
    'price_demo_gold_123456789',
    'Demo user with GOLD subscription for testing'
)
ON CONFLICT ("userId", tier) DO UPDATE SET
    status = EXCLUDED.status,
    amount = EXCLUDED.amount,
    "startDate" = EXCLUDED."startDate",
    "endDate" = EXCLUDED."endDate",
    "nextBillingDate" = EXCLUDED."nextBillingDate",
    notes = EXCLUDED.notes;

-- =============================================================================
-- 3. PAY PERIODS
-- =============================================================================

-- Create recent pay periods for the demo
INSERT INTO pay_periods (
    "userId", "startDate", "endDate", "status", "totalGrossAmount", 
    "totalNetAmount", "totalTaxAmount", "totalWorkers", "processedWorkers"
) VALUES 
-- November 2024 periods
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    '2024-11-01'::date,
    '2024-11-15'::date,
    'completed',
    125000.00,  -- Sum of gross salaries for this period
    95000.00,   -- Sum of net salaries for this period  
    30000.00,   -- Sum of tax amounts for this period
    5,          -- 5 workers
    5           -- All processed
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    '2024-11-16'::date,
    '2024-11-30'::date,
    'completed',
    125000.00,
    95000.00,
    30000.00,
    5,
    5
),
-- December 2024 periods
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    '2024-12-01'::date,
    '2024-12-15'::date,
    'completed',
    125000.00,
    95000.00,
    30000.00,
    5,
    5
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    '2024-12-16'::date,
    '2024-12-31'::date,
    'active',
    125000.00,
    95000.00,
    30000.00,
    5,
    0  -- Not processed yet
)
ON CONFLICT ("userId", "startDate", "endDate") DO NOTHING;

-- =============================================================================
-- 4. PAYROLL RECORDS
-- =============================================================================

-- Get worker IDs and create payroll records for each pay period
WITH worker_data AS (
    SELECT id, name, "employmentType", "salaryGross" 
    FROM workers 
    WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'
),
period_data AS (
    SELECT id as period_id, "startDate", "endDate"
    FROM pay_periods 
    WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'
)
INSERT INTO payroll_records (
    "userId", "workerId", "periodStart", "periodEnd", "grossSalary", 
    "netSalary", "taxAmount", "status", "paymentStatus", "paymentMethod", "paymentDate"
)
SELECT 
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820' as "userId",
    w.id as "workerId",
    p."startDate" as "periodStart",
    p."endDate" as "periodEnd",
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 60000.00  -- Bi-weekly half of monthly
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 7500.00   -- Half of 15000
        ELSE 5000.00 -- Hourly workers get flat rate for demo
    END as "grossSalary",
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 48000.00
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 6250.00
        ELSE 4000.00
    END as "netSalary",
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 12000.00
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 1250.00
        ELSE 1000.00
    END as "taxAmount",
    'finalized' as status,
    'paid' as "paymentStatus",
    'mpesa' as "paymentMethod",
    p."endDate" + INTERVAL '3 days' as "paymentDate"
FROM worker_data w
CROSS JOIN period_data p
WHERE p."status" = 'completed'  -- Only for completed periods
ON CONFLICT ("userId", "workerId", "periodStart", "periodEnd") DO NOTHING;

-- =============================================================================
-- 5. TRANSACTIONS (PAYMENTS)
-- =============================================================================

-- Create payment transactions for completed payroll records
INSERT INTO transactions (
    "userId", "workerId", amount, currency, type, status, "providerRef"
)
SELECT 
    pr."userId",
    pr."workerId",
    pr."netSalary",
    'KES',
    'salary',
    'completed',
    'TXN_DEMO_' || EXTRACT(YEAR FROM pr."paymentDate") || '_' || 
    EXTRACT(MONTH FROM pr."paymentDate") || '_' || 
    EXTRACT(DAY FROM pr."paymentDate") || '_' || 
    SUBSTRING(pr."workerId"::text, 1, 8)
FROM payroll_records pr
WHERE pr."paymentStatus" = 'paid'
AND NOT EXISTS (
    SELECT 1 FROM transactions t 
    WHERE t."userId" = pr."userId" 
    AND t."workerId" = pr."workerId" 
    AND t."periodStart" = pr."periodStart"
)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 6. TAX PAYMENT RECORDS
-- =============================================================================

-- Create tax payment records for the demo user
INSERT INTO tax_payments (
    "userId", tax_type, amount, currency, status, "dueDate", "paymentDate", notes
) VALUES 
-- PAYE tax payments
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'PAYE',
    30000.00,
    'KES',
    'completed',
    '2024-12-15'::date,
    '2024-12-14'::date,
    'November 2024 PAYE tax payment'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'PAYE',
    30000.00,
    'KES',
    'pending',
    '2025-01-15'::date,
    NULL,
    'December 2024 PAYE tax payment'
),
-- NSSF contributions
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'NSSF',
    2400.00,
    'KES',
    'completed',
    '2024-12-15'::date,
    '2024-12-14'::date,
    'November 2024 NSSF contribution'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'NSSF',
    2400.00,
    'KES',
    'pending',
    '2025-01-15'::date,
    NULL,
    'December 2024 NSSF contribution'
),
-- NHIF contributions
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'NHIF',
    1600.00,
    'KES',
    'completed',
    '2024-12-15'::date,
    '2024-12-14'::date,
    'November 2024 NHIF contribution'
),
(
    'b0f45d1f-10a2-4bc8-ada3-48289edd9820',
    'NHIF',
    1600.00,
    'KES',
    'pending',
    '2025-01-15'::date,
    NULL,
    'December 2024 NHIF contribution'
)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 7. SUMMARY REPORT
-- =============================================================================

-- Display summary of created demo data
SELECT 
    'Demo Data Summary' as section,
    'Workers' as item,
    COUNT(*)::text || ' employees created' as details
FROM workers WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

UNION ALL

SELECT 
    'Demo Data Summary' as section,
    'Subscription' as item,
    CONCAT(tier, ' plan - ', status) as details
FROM subscriptions WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

UNION ALL

SELECT 
    'Demo Data Summary' as section,
    'Pay Periods' as item,
    COUNT(*)::text || ' periods created' as details
FROM pay_periods WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

UNION ALL

SELECT 
    'Demo Data Summary' as section,
    'Payroll Records' as item,
    COUNT(*)::text || ' records created' as details
FROM payroll_records WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

UNION ALL

SELECT 
    'Demo Data Summary' as section,
    'Transactions' as item,
    COUNT(*)::text || ' payment transactions' as details
FROM transactions WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

UNION ALL

SELECT 
    'Demo Data Summary' as section,
    'Tax Payments' as item,
    COUNT(*)::text || ' tax payment records' as details
FROM tax_payments WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'

ORDER BY section, item;