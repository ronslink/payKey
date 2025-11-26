-- Migration to add missing columns to users table

-- Add isOnboardingCompleted column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS isOnboardingCompleted BOOLEAN DEFAULT FALSE;

-- Check the current users table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;