-- Clear all pay periods and related data for testing
-- This will delete ALL pay periods from the database

-- Delete all payroll records first (to maintain referential integrity)
DELETE FROM payroll_records;

-- Delete all pay periods
DELETE FROM pay_periods;

-- Reset sequences if needed (for PostgreSQL)
-- ALTER SEQUENCE pay_periods_id_seq RESTART WITH 1;
-- ALTER SEQUENCE payroll_records_id_seq RESTART WITH 1;

-- Verification query
SELECT 'Pay periods cleared successfully' as status, COUNT(*) as remaining_pay_periods 
FROM pay_periods;