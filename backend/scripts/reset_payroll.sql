-- Reset December 2025 pay period to DRAFT
UPDATE pay_periods SET status = 'DRAFT' WHERE id = '16781505-7550-40b7-8eb3-a7edd2ddccb6';

-- Reset payroll records for December 2025 to draft
UPDATE payroll_records SET status = 'draft', "finalizedAt" = NULL, "paymentStatus" = 'pending' WHERE "payPeriodId" = '16781505-7550-40b7-8eb3-a7edd2ddccb6';
