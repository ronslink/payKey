-- Check pay periods with null userId
SELECT id, name, "userId" FROM pay_periods WHERE "userId" IS NULL LIMIT 5;

-- Fix null userId by assigning them to our demo user
UPDATE pay_periods 
SET "userId" = 'b0f45d1f-10a2-4bc8-ada3-48289edd9820' 
WHERE "userId" IS NULL;