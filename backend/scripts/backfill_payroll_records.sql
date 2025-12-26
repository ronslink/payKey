-- Backfill payroll_records for imported pay periods
-- This script creates payroll_records for pay periods that don't have any records

-- First, let's see which pay periods have no records
SELECT pp.id, pp.name, pp."userId"
FROM pay_periods pp
WHERE NOT EXISTS (
    SELECT 1 FROM payroll_records pr WHERE pr."payPeriodId" = pp.id
);

-- For each pay period without records, create records for all workers belonging to that user
INSERT INTO payroll_records (
    id,
    "userId",
    "workerId", 
    "payPeriodId",
    "grossSalary",
    "housingLevy",
    "nhif",
    "nssf",
    "paye",
    "totalDeductions",
    "netSalary",
    status,
    "createdAt",
    "updatedAt"
)
SELECT 
    gen_random_uuid() as id,
    pp."userId",
    w.id as "workerId",
    pp.id as "payPeriodId",
    w."grossSalary",
    ROUND(w."grossSalary" * 0.015, 2) as "housingLevy",
    CASE 
        WHEN w."grossSalary" <= 5999 THEN 150
        WHEN w."grossSalary" <= 7999 THEN 300
        WHEN w."grossSalary" <= 11999 THEN 400
        WHEN w."grossSalary" <= 14999 THEN 500
        WHEN w."grossSalary" <= 19999 THEN 600
        WHEN w."grossSalary" <= 24999 THEN 750
        WHEN w."grossSalary" <= 29999 THEN 850
        WHEN w."grossSalary" <= 34999 THEN 900
        WHEN w."grossSalary" <= 39999 THEN 950
        WHEN w."grossSalary" <= 44999 THEN 1000
        WHEN w."grossSalary" <= 49999 THEN 1100
        WHEN w."grossSalary" <= 59999 THEN 1200
        WHEN w."grossSalary" <= 69999 THEN 1300
        WHEN w."grossSalary" <= 79999 THEN 1400
        WHEN w."grossSalary" <= 89999 THEN 1500
        WHEN w."grossSalary" <= 99999 THEN 1600
        ELSE 1700
    END as "nhif",
    LEAST(ROUND(w."grossSalary" * 0.06, 2), 2160) as "nssf",
    GREATEST(0, ROUND((w."grossSalary" - 24000) * 0.25, 2)) as "paye",
    -- Total deductions (approximate)
    ROUND(w."grossSalary" * 0.015, 2) + 
    LEAST(ROUND(w."grossSalary" * 0.06, 2), 2160) +
    CASE 
        WHEN w."grossSalary" <= 5999 THEN 150
        WHEN w."grossSalary" <= 7999 THEN 300
        WHEN w."grossSalary" <= 11999 THEN 400
        WHEN w."grossSalary" <= 14999 THEN 500
        WHEN w."grossSalary" <= 19999 THEN 600
        WHEN w."grossSalary" <= 24999 THEN 750
        WHEN w."grossSalary" <= 29999 THEN 850
        WHEN w."grossSalary" <= 34999 THEN 900
        WHEN w."grossSalary" <= 39999 THEN 950
        WHEN w."grossSalary" <= 44999 THEN 1000
        WHEN w."grossSalary" <= 49999 THEN 1100
        WHEN w."grossSalary" <= 59999 THEN 1200
        WHEN w."grossSalary" <= 69999 THEN 1300
        WHEN w."grossSalary" <= 79999 THEN 1400
        WHEN w."grossSalary" <= 89999 THEN 1500
        WHEN w."grossSalary" <= 99999 THEN 1600
        ELSE 1700
    END +
    GREATEST(0, ROUND((w."grossSalary" - 24000) * 0.25, 2)) as "totalDeductions",
    -- Net salary
    w."grossSalary" - (
        ROUND(w."grossSalary" * 0.015, 2) + 
        LEAST(ROUND(w."grossSalary" * 0.06, 2), 2160) +
        CASE 
            WHEN w."grossSalary" <= 5999 THEN 150
            WHEN w."grossSalary" <= 7999 THEN 300
            WHEN w."grossSalary" <= 11999 THEN 400
            WHEN w."grossSalary" <= 14999 THEN 500
            WHEN w."grossSalary" <= 19999 THEN 600
            WHEN w."grossSalary" <= 24999 THEN 750
            WHEN w."grossSalary" <= 29999 THEN 850
            WHEN w."grossSalary" <= 34999 THEN 900
            WHEN w."grossSalary" <= 39999 THEN 950
            WHEN w."grossSalary" <= 44999 THEN 1000
            WHEN w."grossSalary" <= 49999 THEN 1100
            WHEN w."grossSalary" <= 59999 THEN 1200
            WHEN w."grossSalary" <= 69999 THEN 1300
            WHEN w."grossSalary" <= 79999 THEN 1400
            WHEN w."grossSalary" <= 89999 THEN 1500
            WHEN w."grossSalary" <= 99999 THEN 1600
            ELSE 1700
        END +
        GREATEST(0, ROUND((w."grossSalary" - 24000) * 0.25, 2))
    ) as "netSalary",
    'finalized' as status,
    pp."createdAt",
    NOW() as "updatedAt"
FROM pay_periods pp
CROSS JOIN workers w
WHERE pp."userId" = w."userId"
  AND w."isActive" = true
  AND NOT EXISTS (
    SELECT 1 FROM payroll_records pr WHERE pr."payPeriodId" = pp.id
  );

-- Show count of records created
SELECT 'Payroll records backfilled' as message, COUNT(*) as count FROM payroll_records;
