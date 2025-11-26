-- Fix user table columns with proper case sensitivity
-- This script will drop any existing columns and recreate them with the correct case

-- First, drop the lowercase versions if they exist
ALTER TABLE users DROP COLUMN IF EXISTS payfrequency;
ALTER TABLE users DROP COLUMN IF EXISTS employeepaymentmethod;
ALTER TABLE users DROP COLUMN IF EXISTS mpesanumber;
ALTER TABLE users DROP COLUMN IF EXISTS bankname;
ALTER TABLE users DROP COLUMN IF EXISTS bankaccount;
ALTER TABLE users DROP COLUMN IF EXISTS bankbranchcode;

-- Create columns with proper case using quoted identifiers
ALTER TABLE users ADD COLUMN "payFrequency" VARCHAR(20) DEFAULT 'MONTHLY' NOT NULL;
ALTER TABLE users ADD COLUMN "employeePaymentMethod" VARCHAR(20) DEFAULT 'MPESA' NOT NULL;
ALTER TABLE users ADD COLUMN "mpesaNumber" VARCHAR(20);
ALTER TABLE users ADD COLUMN "bankName" VARCHAR(100);
ALTER TABLE users ADD COLUMN "bankAccount" VARCHAR(50);
ALTER TABLE users ADD COLUMN "bankBranchCode" VARCHAR(20);

-- Verify the columns were created correctly
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
AND column_name IN ('payFrequency', 'employeePaymentMethod', 'mpesaNumber', 'bankName', 'bankAccount', 'bankBranchCode')
ORDER BY column_name;