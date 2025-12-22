-- Find and delete duplicate Paul Wangigi December records (keep oldest)
WITH duplicates AS (
  SELECT id, 
    ROW_NUMBER() OVER (PARTITION BY "workerId" ORDER BY "createdAt" ASC) as rn
  FROM payroll_records 
  WHERE "payPeriodId" = '16781505-7550-40b7-8eb3-a7edd2ddccb6'
    AND "workerId" = '3afd08f6-a7fd-4402-935b-352d21ea7c6c'
)
DELETE FROM payroll_records 
WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);
