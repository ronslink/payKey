-- Backfill IntaSend Wallet IDs for users with completed onboarding

-- 1. Create a function to generate a deterministic wallet ID based on user ID
-- (or just use a simple update query)

-- Update users who have completed onboarding but lack a wallet ID
UPDATE "users"
SET "intasend_wallet_id" = 'WALLET-' || UPPER(SUBSTRING("id"::text, 1, 8))
WHERE "isOnboardingCompleted" = true
  AND "intasend_wallet_id" IS NULL;

-- Verify the update
SELECT "id", "email", "intasend_wallet_id"
FROM "users"
WHERE "isOnboardingCompleted" = true;
