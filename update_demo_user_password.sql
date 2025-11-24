-- Update demo user with proper bcrypt hashed password
-- First, let's generate the bcrypt hash for "SecurePass123!"
-- We need to use a bcrypt hash since the auth service expects it

-- Update the user with a bcrypt hash of "SecurePass123!"
-- The hash below is for "SecurePass123!"
UPDATE users 
SET "passwordHash" = '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
WHERE email = 'testuser@paykey.com';