-- Add demo workers for the demo user
-- Demo user ID: b0f45d1f-10a2-4bc8-ada3-48289edd9820

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
    'WEEKLY',  -- Using WEEKLY instead of bi-weekly
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

-- Final count
SELECT 
    COUNT(*) as total_workers,
    COUNT(CASE WHEN "employmentType" = 'FIXED' THEN 1 END) as fixed_employees,
    COUNT(CASE WHEN "employmentType" = 'HOURLY' THEN 1 END) as hourly_employees
FROM workers 
WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';