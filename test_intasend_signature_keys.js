const crypto = require('crypto');

// From production environment
const PUBLISHABLE_KEY = 'ISPubKey_live_93f44245-3b36-4419-b0f4-dd9ea6111aa1';
const SECRET_KEY = 'ISSecretKey_live_54b010ea-db92-40dc-ad78-60b0ef48f4d0';

// Sample webhook payload (simplified from IntaSend screenshot)
const webhookPayload = {
    "invoice_id": "KZ5MM24",
    "state": "COMPLETE",
    "provider": "M-PESA",
    "value": 207,
    "account": "254726641088"
};

const payloadString = JSON.stringify(webhookPayload);

console.log('='.repeat(80));
console.log('WEBHOOK SIGNATURE TEST');
console.log('='.repeat(80));
console.log('');

// Test with Secret Key (what PayKey currently uses)
const signatureWithSecret = crypto
    .createHmac('sha256', SECRET_KEY)
    .update(payloadString)
    .digest('hex');

// Test with Publishable Key  
const signatureWithPublishable = crypto
    .createHmac('sha256', PUBLISHABLE_KEY)
    .update(payloadString)
    .digest('hex');

console.log('Payload:', payloadString);
console.log('');
console.log('Signature using SECRET KEY:');
console.log(` ${signatureWithSecret}`);
console.log('');
console.log('Signature using PUBLISHABLE KEY:');
console.log(`  ${signatureWithPublishable}`);
console.log('');
console.log('='.repeat(80));
console.log('INSTRUCTIONS:');
console.log('='.repeat(80));
console.log('1. Look at the IntaSend webhook failure log');
console.log('2. Find the X-IntaSend-Signature value they sent');
console.log('3. Compare with the signatures above');
console.log('4. If it matches SECRET KEY → webhook verification code is correct');
console.log('5. If it matches PUBLISHABLE KEY → we need to fix the verification');
console.log('6. If neither matches → payload format might be different');
console.log('');

// SOLUTION if it's the publishable key
console.log('='.repeat(80));
console.log('IF PUBLISHABLE KEY MATCHES:');
console.log('='.repeat(80));
console.log('');
console.log('Add this environment variable to production:');
console.log('  INTASEND_WEBHOOK_SECRET=ISPubKey_live_93f44245-3b36-4419-b0f4-dd9ea6111aa1');
console.log('');
console.log('Update intasend.service.ts line 80 to use webhook secret:');
console.log('  const webhookSecret = this.configService.get("INTASEND_WEBHOOK_SECRET") || this.secretKey;');
console.log('  const hmac = crypto.createHmac("sha256", webhookSecret)...');
console.log('');
