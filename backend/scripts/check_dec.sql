-- Check December payroll records
SELECT 
  pr.id, 
  pr.status, 
  pr."paymentStatus",
  w.name as worker_name,
  pr."netSalary"
FROM payroll_records pr
JOIN workers w ON pr."workerId" = w.id
WHERE pr."payPeriodId" = '16781505-7550-40b7-8eb3-a7edd2ddccb6';
