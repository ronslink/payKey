-- Create subscription_payments table
CREATE TABLE IF NOT EXISTS "subscription_payments" (
    "id" uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    "subscriptionId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "amount" decimal(10,2) NOT NULL,
    "currency" character varying NOT NULL DEFAULT 'USD',
    "status" character varying NOT NULL DEFAULT 'COMPLETED',
    "paymentMethod" character varying NOT NULL,
    "billingPeriod" character varying NOT NULL,
    "periodStart" timestamptz NOT NULL,
    "periodEnd" timestamptz NOT NULL,
    "dueDate" timestamptz NOT NULL,
    "paidDate" timestamptz,
    "invoiceNumber" character varying,
    "paymentProvider" character varying,
    "transactionId" character varying,
    "metadata" jsonb,
    "notes" text,
    "createdAt" timestamptz NOT NULL DEFAULT now(),
    "updatedAt" timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT "FK_subscription_payments_subscription" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON DELETE CASCADE,
    CONSTRAINT "FK_subscription_payments_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS "idx_subscription_payments_userId" ON "subscription_payments"("userId");
CREATE INDEX IF NOT EXISTS "idx_subscription_payments_subscriptionId" ON "subscription_payments"("subscriptionId");
CREATE INDEX IF NOT EXISTS "idx_subscription_payments_status" ON "subscription_payments"("status");
CREATE INDEX IF NOT EXISTS "idx_subscription_payments_createdAt" ON "subscription_payments"("createdAt");

-- Insert some sample payment history for testuser@paykey.com
INSERT INTO "subscription_payments" (
    "id",
    "subscriptionId", 
    "userId",
    "amount",
    "currency",
    "status",
    "paymentMethod",
    "billingPeriod",
    "periodStart",
    "periodEnd",
    "dueDate",
    "paidDate",
    "invoiceNumber",
    "paymentProvider",
    "transactionId",
    "metadata",
    "notes",
    "createdAt",
    "updatedAt"
) 
SELECT 
    uuid_generate_v4(),
    s.id,
    s."userId",
    9.99,
    'USD',
    'COMPLETED',
    'Credit Card',
    'monthly',
    '2024-11-01'::timestamptz,
    '2024-11-30'::timestamptz,
    '2024-11-01'::timestamptz,
    '2024-11-01'::timestamptz,
    'INV-2024-001',
    'stripe',
    'pi_3Qf8l2KkQGwOEc3x1ZxYzABC',
    '{"plan": "BASIC", "features": ["Up to 3 workers", "Basic tax calculations"]}',
    'Initial subscription payment for BASIC plan',
    now(),
    now()
FROM subscriptions s
WHERE s."userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com' LIMIT 1)
LIMIT 1;

-- Insert another payment record (for December)
INSERT INTO "subscription_payments" (
    "id",
    "subscriptionId", 
    "userId",
    "amount",
    "currency",
    "status",
    "paymentMethod",
    "billingPeriod",
    "periodStart",
    "periodEnd",
    "dueDate",
    "paidDate",
    "invoiceNumber",
    "paymentProvider",
    "transactionId",
    "metadata",
    "notes",
    "createdAt",
    "updatedAt"
) 
SELECT 
    uuid_generate_v4(),
    s.id,
    s."userId",
    9.99,
    'USD',
    'COMPLETED',
    'Credit Card',
    'monthly',
    '2024-12-01'::timestamptz,
    '2024-12-31'::timestamptz,
    '2024-12-01'::timestamptz,
    '2024-12-01'::timestamptz,
    'INV-2024-002',
    'stripe',
    'pi_3Qf8l2KkQGwOEc3x1ZxYzDEF',
    '{"plan": "BASIC", "features": ["Up to 3 workers", "Basic tax calculations"]}',
    'Monthly subscription payment for BASIC plan',
    now(),
    now()
FROM subscriptions s
WHERE s."userId" = (SELECT id FROM users WHERE email = 'testuser@paykey.com' LIMIT 1)
LIMIT 1;