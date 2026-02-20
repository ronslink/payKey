According to IntaSend docs and the error we saw, here's what's likely happening:

## The Real Issue

**IntaSend uses the API SECRET KEY (not a separate webhook secret) to sign webhooks.**

Looking at line 80 of `intasend.service.ts`:
```typescript
const hmac = crypto
  .createHmac('sha256', this.secretKey)  // Uses INTASEND_SECRET_KEY
  .update(rawBody)
  .digest('hex');
```

PayKey correctly uses `INTASEND_SECRET_KEY` for verification.

## Potential Problems

1. **Raw Body Issue** - The payload IntaSend sends vs what PayKey receives might be different (encoding, whitespace, etc)
2. **Header Case Sensitivity** - `X-IntaSend-Signature` vs `x-intasend-signature`
3. **Environment Mismatch** - Using sandbox keys in production or vice versa

## Let's Test

Create this diagnostic script:

```javascript
const crypto = require('crypto');

// From IntaSend screenshot payload
const webhookPayload = {
  "invoice_id": "KZ5MM24",
  "state": "COMPLETE",
  "provider": "M-PESA",
  "charges": "6.21",
  "net_amount": "200.79",
  "currency": "KES",
  "value": 207,
  "account": "254726641088",
  "api_ref": "478cd522-ac41-44bc-b463-48df3cdfdf20",
  "mpesa_reference": null,
  "host": "46.101.95.200",
  "retry_count": 0,
  "failed_reason": null,
  "failed_code": null,
  "failed_code_link": null,
  "card_info": {
    "bin_country": null,
    "card_type": null
  },
  "created_at": "2026-02-07T16:42:46.298117+03:00",
  "updated_at": "2026-02-07T16:42:46.306405+03:00"
};

//YOUR production secret
const SECRET = 'ISSecretKey_live_54b010ea-db92-40dc-ad78-60b0ef48f4d0';

// Try different serializations
const payloadString1 = JSON.stringify(webhookPayload);  // No spaces
const payloadString2 = JSON.stringify(webhookPayload, null, 2);  // With spaces/newlines
const payloadString3 = JSON.stringify(webhookPayload, null, 0);  // Minimal

console.log('Testing webhook signature calculation...\n');

[payloadString1, payloadString2, payloadString3].forEach((payload, i) => {
  const signature = crypto
    .createHmac('sha256', SECRET)
    .update(payload)
    .digest('hex');
  
  console.log(`Variation ${i + 1}:`);
  console.log(`  Signature: ${signature}`);
  console.log(`  Payload length: ${payload.length} bytes`);
  console.log('');
});

console.log('Check IntaSend webhook log for the signature they sent');
console.log('Compare with signatures above to see which matches');
```

Save as `test_signature_variations.js` and run it.

## THE REAL SOLUTION

Based on IntaSend docs saying "challenge validates requests", I suspect:

**IntaSend might NOT be using HMAC signatures at all!**

They might only be using the **Challenge** field for validation. Let me check the webhook handler...
