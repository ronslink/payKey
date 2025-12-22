-- Add Paul Wangigi to October, November, December pay periods
INSERT INTO payroll_records (
  id, "userId", "workerId", "payPeriodId", 
  "grossSalary", "netSalary", "taxAmount",
  bonuses, "otherEarnings", "otherDeductions",
  "holidayHours", "sundayHours", "overtimePay",
  status, "periodStart", "periodEnd", 
  "paymentStatus", "paymentMethod",
  deductions, "taxBreakdown",
  "createdAt", "updatedAt"
) VALUES 
-- October 2025 (CLOSED)
(gen_random_uuid(), '4390dea3-373f-414d-91f3-7b1cbe2861ac', '3afd08f6-a7fd-4402-935b-352d21ea7c6c', 
 '1d92adbe-913b-41ec-9b61-5137b72b11b9', 45000, 35000, 5000,
 0, 0, 0, 0, 0, 0,
 'finalized', '2025-10-01', '2025-10-31', 
 'paid', 'mpesa',
 '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb, '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb,
 NOW(), NOW()),
-- November 2025 (CLOSED)
(gen_random_uuid(), '4390dea3-373f-414d-91f3-7b1cbe2861ac', '3afd08f6-a7fd-4402-935b-352d21ea7c6c', 
 '73c69455-8285-4b1d-81ed-5e68758eeb7c', 45000, 35000, 5000,
 0, 0, 0, 0, 0, 0,
 'finalized', '2025-11-01', '2025-11-30', 
 'paid', 'mpesa',
 '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb, '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb,
 NOW(), NOW()),
-- December 2025 (DRAFT)
(gen_random_uuid(), '4390dea3-373f-414d-91f3-7b1cbe2861ac', '3afd08f6-a7fd-4402-935b-352d21ea7c6c', 
 '16781505-7550-40b7-8eb3-a7edd2ddccb6', 45000, 35000, 5000,
 0, 0, 0, 0, 0, 0,
 'draft', '2025-12-01', '2025-12-31', 
 'pending', 'mpesa',
 '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb, '{"nssf":2160,"nhif":1700,"paye":2700}'::jsonb,
 NOW(), NOW());
