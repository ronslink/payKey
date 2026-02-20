SELECT id, "providerRef", status, amount, currency, "createdAt", "paymentMethod", metadata::text 
FROM transactions 
WHERE "providerRef" = 'KZ5MM24';
