-- Reset all data for testuser@paykey.com
-- This script deletes all user data and resets the user to first-time login state

-- First, get subscription IDs for this user and delete dependent records
DELETE FROM subscription_payments WHERE "subscriptionId" IN (
    SELECT id FROM subscriptions WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com')
);

-- Delete tax_submissions that reference this user's pay periods
DELETE FROM tax_submissions WHERE "payPeriodId" IN (
    SELECT id FROM pay_periods WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com')
);

-- Now delete the main tables
DELETE FROM transactions WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM payroll_records WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM tax_payments WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM activities WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM subscriptions WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM pay_periods WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM leave_requests WHERE "workerId" IN (SELECT id FROM workers WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com'));
DELETE FROM terminations WHERE "workerId" IN (SELECT id FROM workers WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com'));
DELETE FROM time_entries WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM workers WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM properties WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM exports WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM account_mappings WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM accounting_exports WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');

-- Reset user to fresh state (first-time login simulation)
UPDATE users SET 
    "isOnboardingCompleted" = false,
    tier = 'FREE',
    "kraPin" = NULL,
    "nssfNumber" = NULL,
    "shifNumber" = NULL,
    "idNumber" = NULL,
    address = NULL,
    city = NULL,
    "countryId" = NULL,
    "residentStatus" = NULL,
    "businessName" = NULL,
    "mpesaPaybill" = NULL,
    "mpesaTill" = NULL,
    "employerId" = NULL
WHERE email = 'testuser@paykey.com';

-- Verify the reset
SELECT '=== USER RESET COMPLETE ===' as status;
SELECT id, email, tier, "isOnboardingCompleted" FROM users WHERE email = 'testuser@paykey.com';
SELECT 'Workers:' as table_name, COUNT(*) as count FROM workers WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com')
UNION ALL
SELECT 'Pay periods:', COUNT(*) FROM pay_periods WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com')
UNION ALL
SELECT 'Subscriptions:', COUNT(*) FROM subscriptions WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com')
UNION ALL
SELECT 'Transactions:', COUNT(*) FROM transactions WHERE "userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com');
