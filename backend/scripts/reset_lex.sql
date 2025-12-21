
-- Reset Payroll Records for Lex (Dec 2025)
UPDATE payroll_records 
SET status = 'draft', "finalizedAt" = NULL, "paymentStatus" = 'pending'
WHERE "payPeriodId" = (
    SELECT id FROM pay_periods 
    WHERE "userId" = (SELECT id FROM users WHERE email = 'lex12@yahoo.com') 
    AND "startDate"::text LIKE '2025-12%'
);

-- Reset Pay Period Status
UPDATE pay_periods
SET status = 'DRAFT'
WHERE "userId" = (SELECT id FROM users WHERE email = 'lex12@yahoo.com') 
AND "startDate"::text LIKE '2025-12%';
