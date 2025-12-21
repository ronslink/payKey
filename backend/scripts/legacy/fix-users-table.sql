-- Fix Users Table - Add Missing Columns
-- This updates the users table to match the User entity definition

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS "residentStatus" VARCHAR,
ADD COLUMN IF NOT EXISTS "countryCode" VARCHAR,
ADD COLUMN IF NOT EXISTS "nationalityId" UUID,
ADD COLUMN IF NOT EXISTS "idType" VARCHAR,
ADD COLUMN IF NOT EXISTS "isOnboardingCompleted" BOOLEAN DEFAULT false;

-- Also add any missing columns that might be referenced in the entity
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS "userTier" VARCHAR DEFAULT 'FREE',
ADD COLUMN IF NOT EXISTS "idType" VARCHAR,
ADD COLUMN IF NOT EXISTS "nationalityId" UUID,
ADD COLUMN IF NOT EXISTS "countryCode" VARCHAR,
ADD COLUMN IF NOT EXISTS "isOnboardingCompleted" BOOLEAN DEFAULT false;

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_users_resident_status ON users("residentStatus");
CREATE INDEX IF NOT EXISTS idx_users_country_code ON users("countryCode");
CREATE INDEX IF NOT EXISTS idx_users_nationality_id ON users("nationalityId");
CREATE INDEX IF NOT EXISTS idx_users_id_type ON users("idType");
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed ON users("isOnboardingCompleted");
-- Add missing columns to subscriptions table
ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS "createdAt" timestamptz NOT NULL DEFAULT now(),
ADD COLUMN IF NOT EXISTS "updatedAt" timestamptz NOT NULL DEFAULT now();

-- Create subscription_payments table if it does not exist
CREATE TABLE IF NOT EXISTS "subscription_payments" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    "subscriptionId" uuid,
    "userId" uuid,
    "amount" numeric,
    "currency" varchar,
    "status" varchar,
    "paymentMethod" varchar,
    "billingPeriod" varchar,
    "periodStart" timestamptz,
    "periodEnd" timestamptz,
    "dueDate" timestamptz,
    "paidDate" timestamptz,
    "invoiceNumber" varchar,
    "paymentProvider" varchar,
    "transactionId" varchar,
    "metadata" jsonb,
    "notes" text,
    "createdAt" timestamptz NOT NULL DEFAULT now(),
    "updatedAt" timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT "FK_subscription_payments_subscription" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON DELETE CASCADE
);