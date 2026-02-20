# Webhook Secret Configuration Guide

## Setup Steps

### 1. Generate a Secure Challenge/Webhook Secret

```bash
# Generate a random secure secret (run this locally)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Example output: `a7f3e8b2c1d9f4e6a5b8c3d7e9f1a2b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0`

### 2. Configure IntaSend Dashboard

1. Go to IntaSend Dashboard → Integrations → Webhooks → Manage Webhook
2. In the **Challenge** field, paste your generated secret
3. Click **Save changes**

### 3. Configure Production Environment

SSH into production and add the webhook secret:

```bash
ssh -i C:\Users\ronon\.ssh\paykey_deploy root@46.101.95.200

# Add to .env file (or wherever environment variables are stored)
echo 'INTASEND_WEBHOOK_SECRET=a7f3e8b2c1d9f4e6a5b8c3d7e9f1a2b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0' >> /path/to/.env

# Restart backend
docker restart paykey_backend_prod
```

**IMPORTANT:** Use the same secret in both IntaSend Challenge field and `INTASEND_WEBHOOK_SECRET`.

### 4. Test the Configuration

After restarting the backend:

1. In IntaSend dashboard, go to the failed webhook for KZ5MM24
2. Click **Replay/Resend**
3. Check your backend logs:

```bash
docker logs paykey_backend_prod --tail 50 -f
```

You should see:
```
🔹 IntaSend Webhook Received: {...}
Using dedicated webhook secret for verification
✅ Webhook processed successfully
```

### 5. Verify Transaction Updated

Run the check script:

```bash
node check_transaction.js
```

Expected:
- Status: `CLEARING` or `SUCCESS`
- Wallet automatically credited

---

## Security Benefits

✅ **Separate Concerns:** Webhook secret is independent of API credentials  
✅ **Rotation:** Can change webhook secret without affecting API access  
✅ **Compromise Isolation:** If API key leaks, webhooks remain secure  
✅ **Best Practice:** Follows industry standard webhook security patterns

---

## Backward Compatibility

The code will automatically fallback to `INTASEND_SECRET_KEY` if `INTASEND_WEBHOOK_SECRET` is not set, so existing setups won't break.

---

## Troubleshooting

### Still Getting "Invalid Signature"?

1. **Check the secret matches exactly:**
   ```bash
   # On production
   docker exec paykey_backend_prod env | grep INTASEND_WEBHOOK_SECRET
   ```
   
2. **Compare with IntaSend Challenge field** - they must be identical

3. **Check logs for which secret is being used:**
   ```bash
   docker logs paykey_backend_prod | grep "Using.*webhook"
   ```

### How to Test Without Replaying

Create a test webhook:

```bash
WEBHOOK_SECRET="your_secret_here"
PAYLOAD='{"invoice_id":"TEST","state":"COMPLETE"}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | cut -d' ' -f2)

curl -X POST https://api.paydome.co/payments/intasend/webhook \
  -H "Content-Type: application/json" \
  -H "X-IntaSend-Signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

Should return success response.
