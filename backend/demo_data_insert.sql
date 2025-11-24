-- Pay Periods Demo Data SQL Script
-- This script creates demo data for the Pay Periods Management system

-- First, clean existing demo data
DELETE FROM payroll_records WHERE userId IN (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM pay_periods WHERE userId IN (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM workers WHERE userId IN (SELECT id FROM users WHERE email = 'testuser@paykey.com');
DELETE FROM users WHERE email = 'testuser@paykey.com';

-- Create demo user
INSERT INTO users (id, email, passwordHash, firstName, lastName, createdAt, updatedAt) 
VALUES (
  gen_random_uuid(),
  'testuser@paykey.com',
  '$2b$10$hash.password123.bcrypt',  -- This would be the actual hash in real execution
  'Test',
  'User',
  now(),
  now()
);

-- Get the user ID for reference
DO $$
DECLARE
    demo_user_id UUID;
BEGIN
    SELECT id INTO demo_user_id FROM users WHERE email = 'testuser@paykey.com';
    
    -- Create 5 demo workers
    INSERT INTO workers (id, userId, name, email, phoneNumber, idNumber, kraPin, nssfNumber, nhifNumber, jobTitle, salaryGross, hourlyRate, employmentType, paymentFrequency, startDate, isActive, housingAllowance, transportAllowance, mpesaNumber, createdAt, updatedAt) VALUES
    (gen_random_uuid(), demo_user_id, 'John Kamau Mwangi', 'john.kamau@company.com', '+254701234567', '12345678', 'A123456789B', 'NSSF123456', 'NHIF789012', 'Software Developer', 120000, 692.31, 'FIXED', 'MONTHLY', '2023-01-15', true, 25000, 15000, '+254701234567', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Sarah Wanjiku Njeri', 'sarah.wanjiku@company.com', '+254702345678', '23456789', 'B987654321C', 'NSSF234567', 'NHIF890123', 'Marketing Manager', 85000, 489.66, 'FIXED', 'MONTHLY', '2022-08-01', true, 18000, 12000, '+254702345678', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Michael Ochieng Otieno', 'michael.ochieng@company.com', '+254703456789', '34567890', 'C876543210D', 'NSSF345678', 'NHIF901234', 'Construction Worker', 0, 500, 'HOURLY', 'WEEKLY', '2023-06-01', true, 0, 0, '+254703456789', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Grace Achieng Adhiambo', 'grace.achieng@company.com', '+254704567890', '45678901', 'D765432109E', 'NSSF456789', 'NHIF012345', 'HR Specialist', 65000, 374.14, 'FIXED', 'MONTHLY', '2023-03-01', true, 15000, 10000, '+254704567890', now(), now()),
    (gen_random_uuid(), demo_user_id, 'David Kiprotich Chepkemoi', 'david.kiprotich@company.com', '+254705678901', '56789012', 'E654321098F', 'NSSF567890', 'NHIF123456', 'Accountant', 95000, 546.51, 'FIXED', 'MONTHLY', '2022-11-01', true, 20000, 14000, '+254705678901', now(), now());

    -- Create pay periods for the last 3 months (bi-weekly)
    INSERT INTO pay_periods (id, userId, name, startDate, endDate, status, createdAt, updatedAt) VALUES
    (gen_random_uuid(), demo_user_id, 'Aug 2024 - Week 1', '2024-08-01', '2024-08-14', 'COMPLETED', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Aug 2024 - Week 2', '2024-08-15', '2024-08-28', 'COMPLETED', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Sep 2024 - Week 1', '2024-09-01', '2024-09-14', 'COMPLETED', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Sep 2024 - Week 2', '2024-09-15', '2024-09-28', 'COMPLETED', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Oct 2024 - Week 1', '2024-10-01', '2024-10-14', 'COMPLETED', now(), now()),
    (gen_random_uuid(), demo_user_id, 'Oct 2024 - Week 2', '2024-10-15', '2024-10-28', 'COMPLETED', now(), now());
    
    -- Create payroll records for each worker and pay period
    -- Note: This is a simplified version with basic calculations
    INSERT INTO payroll_records (id, userId, workerId, periodStart, periodEnd, grossSalary, netSalary, taxAmount, paymentStatus, paymentMethod, paymentDate, createdAt, updatedAt)
    SELECT 
        gen_random_uuid(),
        demo_user_id,
        w.id,
        pp.startDate,
        pp.endDate,
        -- Simplified salary calculation (bi-weekly for monthly workers)
        CASE 
            WHEN w.employmentType = 'FIXED' THEN w.salaryGross / 2 + COALESCE(w.housingAllowance, 0) + COALESCE(w.transportAllowance, 0)
            ELSE 10000 -- Hourly worker default
        END,
        8000, -- Simplified net salary
        2000, -- Simplified tax amount
        'paid',
        'mpesa',
        pp.endDate + interval '3 days',
        now(),
        now()
    FROM workers w
    CROSS JOIN pay_periods pp
    WHERE w.userId = demo_user_id;

END $$;

-- Update pay period totals
UPDATE pay_periods 
SET 
    totalGrossAmount = (
        SELECT COALESCE(SUM(grossSalary), 0)
        FROM payroll_records pr 
        WHERE pr.periodStart = pay_periods.startDate 
        AND pr.periodEnd = pay_periods.endDate
    ),
    totalNetAmount = (
        SELECT COALESCE(SUM(netSalary), 0)
        FROM payroll_records pr 
        WHERE pr.periodStart = pay_periods.startDate 
        AND pr.periodEnd = pay_periods.endDate
    ),
    totalTaxAmount = (
        SELECT COALESCE(SUM(taxAmount), 0)
        FROM payroll_records pr 
        WHERE pr.periodStart = pay_periods.startDate 
        AND pr.periodEnd = pay_periods.endDate
    ),
    totalWorkers = (
        SELECT COUNT(*)
        FROM payroll_records pr 
        WHERE pr.periodStart = pay_periods.startDate 
        AND pr.periodEnd = pay_periods.endDate
    ),
    processedWorkers = (
        SELECT COUNT(*)
        FROM payroll_records pr 
        WHERE pr.periodStart = pay_periods.startDate 
        AND pr.periodEnd = pay_periods.endDate
    );

-- Show summary
SELECT 
    'Demo Data Created Successfully!' as status,
    (SELECT COUNT(*) FROM users WHERE email = 'testuser@paykey.com') as users_created,
    (SELECT COUNT(*) FROM workers WHERE userId = (SELECT id FROM users WHERE email = 'testuser@paykey.com')) as workers_created,
    (SELECT COUNT(*) FROM pay_periods WHERE userId = (SELECT id FROM users WHERE email = 'testuser@paykey.com')) as pay_periods_created,
    (SELECT COUNT(*) FROM payroll_records WHERE userId = (SELECT id FROM users WHERE email = 'testuser@paykey.com')) as payroll_records_created;
