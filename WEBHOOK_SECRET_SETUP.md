# Webhook Secret Setup - PayKey2026

## Quick Setup Steps

### 1. Update IntaSend Dashboard
1. Go to IntaSend Dashboard → Integrations → Webhooks → Manage Webhook
2. Set **Challenge** field to: `PayKey2026`
3. Click **Save changes**

### 2. Update Production Environment

```bash
# SSH into production
ssh -i C:\Users\ronon\.ssh\paykey_deploy root@46.101.95.200

# Add webhook secret to environment
# (Adjust path to your actual .env file location)
echo 'INTASEND_WEBHOOK_SECRET=PayKey2026' >> /path/to/.env

# Restart backend
docker restart paykey_backend_prod

# Verify it's set
docker exec paykey_backend_prod env | grep INTASEND_WEBHOOK_SECRET
# Should output: INTASEND_WEBHOOK_SECRET=PayKey2026
```

### 3. Test Webhook

After restarting, go to IntaSend dashboard and click **Replay/Resend** on the failed KZ5MM24 webhook.

**Expected result:**
- Webhook processes successfully
- Transaction updates to CLEARING
- User wallet credited automatically

### 4. Verify Transaction

```bash
node check_transaction.js
```

Should show:
- Status: `CLEARING`
- Clearing Balance: 200.79 KES

---

## Environment Variables Summary

```env
# API Credentials (for making API calls)
INTASEND_PUBLISHABLE_KEY=ISPubKey_live_93f44245-3b36-4419-b0f4-dd9ea6111aa1
INTASEND_SECRET_KEY=ISSecretKey_live_54b010ea-db92-40dc-ad78-60b0ef48f4d0
INTASEND_IS_LIVE=true

# Webhook Secret (for verifying incoming webhooks from IntaSend)
INTASEND_WEBHOOK_SECRET=PayKey2026
```

**Note:** The webhook secret is separate from API credentials for better security.

---

## Code Changes

Updated `backend/src/modules/payments/intasend.service.ts`:
- Now checks for `INTASEND_WEBHOOK_SECRET` environment variable
- Falls back to `INTASEND_SECRET_KEY` if not set (backward compatible)
- IntaSend Challenge field must match `INTASEND_WEBHOOK_SECRET`

---

## Deployment

```bash
# Commit changes
git add backend/src/modules/payments/intasend.service.ts
git commit -m "feat: Add INTASEND_WEBHOOK_SECRET support for webhook verification"
git push

# Deploy to production (adjust for your deployment method)
# Then follow steps 2-4 above
```
