-- Migration to add missing payPeriodId column to payroll_records table
-- This fixes the error: column "payPeriodId" does not exist

-- Add the missing payPeriodId column to payroll_records table
ALTER TABLE payroll_records 
ADD COLUMN "payPeriodId" UUID REFERENCES pay_periods(id) ON DELETE SET NULL;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_payroll_records_payPeriodId 
ON payroll_records("payPeriodId");
