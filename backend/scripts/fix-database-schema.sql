-- Fix database schema for users table
-- This script adds all missing columns that are required by the User entity

-- Add missing columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS payFrequency VARCHAR(20) DEFAULT 'MONTHLY' NOT NULL;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS employeePaymentMethod VARCHAR(20) DEFAULT 'MPESA' NOT NULL;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS mpesaNumber VARCHAR(20);

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bankName VARCHAR(100);

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bankAccount VARCHAR(50);

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bankBranchCode VARCHAR(20);

-- Update existing users with default values for new columns
UPDATE users 
SET 
  payFrequency = 'MONTHLY',
  employeePaymentMethod = 'MPESA'
WHERE payFrequency IS NULL;

SELECT 'Database schema fixed successfully' as status;
