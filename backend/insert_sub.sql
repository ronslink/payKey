INSERT INTO subscriptions (
  "id", "userId", "tier", "status", "billingPeriod", "currency", "autoRenewal", "renewalMethod", "createdAt", "updatedAt"
) VALUES (
  gen_random_uuid(), 'ec4e0331-6cf4-4542-b7bc-43f06a7ec39a', 'PLATINUM', 'ACTIVE', 'monthly', 'USD', true, 'NOTIFICATION', NOW(), NOW()
);
