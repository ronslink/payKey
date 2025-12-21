-- Add missing columns to payroll_records table to match the TypeORM entity
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "payPeriodId" uuid;
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "bonuses" decimal(10,2) DEFAULT 0;
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "otherEarnings" decimal(10,2) DEFAULT 0;
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "otherDeductions" decimal(10,2) DEFAULT 0;
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "status" varchar DEFAULT 'draft';
ALTER TABLE "payroll_records" ADD COLUMN IF NOT EXISTS "finalizedAt" TIMESTAMP WITH TIME ZONE;

-- Add foreign key constraint if payPeriods table exists
ALTER TABLE "payroll_records" ADD CONSTRAINT IF NOT EXISTS "FK_payroll_records_payPeriodId" 
FOREIGN KEY ("payPeriodId") REFERENCES "pay_periods"("id") ON DELETE SET NULL;