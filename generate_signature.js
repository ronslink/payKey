const crypto = require('crypto');

// 1. Enter your Webhook Secret here (from .env or IntaSend Dashboard)
const WEBHOOK_SECRET = 'YOUR_INTASEND_WEBHOOK_SECRET_HERE';

// 2. Paste your JSON payload here
const payload = {
    "invoice_id": "KZ5MM24",
    "state": "PENDING",
    "provider": "M-PESA",
    "charges": "0.00",
    "net_amount": "207.00",
    "currency": "KES",
    "value": "207.00",
    "account": "254726641088",
    "api_ref": "478cd522-ac41-44bc-b463-48df3cdfdf20",
    "mpesa_reference": null,
    "host": "46.101.95.200",
    "card_info": {
        "bin_country": null,
        "card_type": null
    },
    "retry_count": 0,
    "failed_reason": null,
    "failed_code": null,
    "failed_code_link": null,
    "created_at": "2026-02-07T16:42:46.298117+03:00",
    "updated_at": "2026-02-07T16:42:46.306405+03:00",
    "challenge": "PayKey2026"
};

// 3. Generate Signature
const payloadString = JSON.stringify(payload);
const signature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(payloadString)
    .digest('hex');

console.log('='.repeat(60));
console.log('INTASEND WEBHOOK SIGNATURE GENERATOR');
console.log('='.repeat(60));
console.log('\nPayload (Stringified):');
console.log(payloadString);
console.log('\nGenerated Signature (X-IntaSend-Signature):');
console.log(signature);
console.log('\n');
console.log('Instructions:');
console.log('1. Copy the signature above.');
console.log('2. In Postman/Curl, add a header:');
console.log('   Key:   X-IntaSend-Signature');
console.log('   Value: [The Signature]');
console.log('3. Send the request.');
console.log('='.repeat(60));
