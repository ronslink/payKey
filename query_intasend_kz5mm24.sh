#!/bin/bash

# IntaSend Production Query Script for Transaction KZ5MM24
# Run this on the production server

# IntaSend Live API credentials
SECRET_KEY="ISSecretKey_live_54b010ea-db92-40dc-ad78-60b0ef48f4d0"

echo "=================================="
echo "Querying IntaSend for KZ5MM24"
echo "=================================="

# Query by invoice_id
curl -X GET "https://payment.intasend.com/api/v1/payment/collection/?invoice_id=KZ5MM24" \
  -H "Authorization: Bearer ${SECRET_KEY}" \
  -H "Content-Type: application/json"

echo ""
echo "=================================="
echo "Checking webhook delivery logs"
echo "=================================="

# Check backend logs for webhook attempts
docker logs paykey_backend_prod --since "2026-02-07T15:40:00" --until "2026-02-07T16:00:00" 2>&1 | grep -i "KZ5MM24\|webhook\|intasend"
