-- Create demo workers for the user
INSERT INTO workers ("userId", name, "phoneNumber", "salaryGross", "startDate", "employmentType") VALUES
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'Jane Doe', '+254700123456', 15000.00, '2024-01-15', 'FIXED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'Kamau Wanjiku', '+254700234567', 120000.00, '2024-02-01', 'FIXED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'Ochieng Achieng', '+254700345678', 120000.00, '2024-03-01', 'FIXED'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'Kiprotich Ngeny', '+254700456789', 10000.00, '2024-04-01', 'HOURLY'),
('b0f45d1f-10a2-4bc8-ada3-48289edd9820', 'Mwangi Kamau', '+254700567890', 120000.00, '2024-05-01', 'FIXED');

-- Now create payroll records for these workers and the pay periods
INSERT INTO payroll_records ("userId", "workerId", "periodStart", "periodEnd", "grossSalary", "netSalary", "taxAmount", "paymentStatus", "paymentMethod", "paymentDate")
SELECT 
    w."userId",
    w.id,
    pp."startDate",
    pp."endDate",
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 120000 / 2  -- Monthly worker -> bi-weekly
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 15000 / 2
        ELSE 10000 -- Hourly workers get flat rate for demo
    END,
    CASE 
        WHEN w."employmentType" = 'FIXED' AND w.name != 'Jane Doe' THEN 95000 / 2
        WHEN w."employmentType" = 'FIXED' AND w.name = 'Jane Doe' THEN 12500 / 2
        ELSE 8000
    END,
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
WHERE w."userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820'
AND pp."userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';

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
    )
WHERE "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820';