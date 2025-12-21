-- Reset December 2025 payroll for lex12@yahoo.com
-- User ID: 4390dea3-373f-414d-91f3-7b1cbe2861ac

-- 1. Reset pay period status from CLOSED to DRAFT
UPDATE pay_periods 
SET status = 'DRAFT'
WHERE "userId" = '4390dea3-373f-414d-91f3-7b1cbe2861ac' 
  AND name LIKE '%December%2025%';

-- 2. Show results
SELECT 'Pay Period Reset' as info, id, name, status FROM pay_periods 
WHERE "userId" = '4390dea3-373f-414d-91f3-7b1cbe2861ac' 
  AND name LIKE '%December%2025%';

SELECT 'Payroll Records' as info, pr.id, pr.status, pr."paymentStatus" 
FROM payroll_records pr
WHERE pr."userId" = '4390dea3-373f-414d-91f3-7b1cbe2861ac' 
  AND pr."payPeriodId" IN (
    SELECT id FROM pay_periods 
    WHERE "userId" = '4390dea3-373f-414d-91f3-7b1cbe2861ac' 
    AND name LIKE '%December%2025%'
  );
