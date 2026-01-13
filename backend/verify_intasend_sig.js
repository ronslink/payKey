
require('dotenv').config();
const crypto = require('crypto');
const axios = require('axios');

// Determine which key to use logic matching intasend.service.ts
let secret = process.env.INTASEND_SECRET_KEY_TEST;
if (!secret) {
    secret = process.env.INTASEND_SECRET_KEY;
}

if (!secret) {
    console.error('❌ No IntaSend Secret Key found in .env');
    process.exit(1);
}

console.log('Using Secret Key ending in:', secret.slice(-4));

const payload = {
    tracking_id: 'B2C_BATCH_' + Date.now(),
    state: 'COMPLETE',
    api_ref: 'TestRef',
    value: 5000,
    account: '254700000000',
    transactions: []
};

// JSON stringify the payload
const rawBody = JSON.stringify(payload);

// Generate HMAC signature
const signature = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');

console.log('Generated Signature:', signature);

// Send Request
axios.post('http://localhost:3000/payments/intasend/webhook', payload, {
    headers: {
        'x-intasend-signature': signature,
        'Content-Type': 'application/json'
    }
})
    .then(res => {
        console.log('✅ Response:', res.status, res.data);
    })
    .catch(err => {
        console.error('❌ Error:', err.response ? err.response.data : err.message);
    });
