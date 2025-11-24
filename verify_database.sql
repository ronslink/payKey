-- Verify database connectivity and data integrity
SELECT email, "firstName", "lastName" FROM users WHERE email = 'testuser@paykey.com';

-- Check pay periods created
SELECT COUNT(*) as pay_periods_count FROM pay_periods WHERE name LIKE '%2024%';

-- Check payroll records created  
SELECT COUNT(*) as payroll_records_count FROM payroll_records WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';