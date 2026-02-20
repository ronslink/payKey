const crypto = require('crypto');

// ---------------------------------------------------------
// SIMULATION SETUP
// ---------------------------------------------------------

// 1. The payload (what IntaSend sends)
const payload = {
    "invoice_id": "TEST_TRANSACTION_001",
    "state": "COMPLETE",
    "provider": "M-PESA",
    "amount": 1000
};
const rawBody = JSON.stringify(payload);

// 2. The Secret (Proposed "Challenge" value)
const PROPOSED_CHALLENGE = "PayKey2026";

// 3. The OLD Secret (Current API Key)
const OLD_API_KEY = "ISSecretKey_live_54b010ea-db92-40dc-ad78-60b0ef48f4d0";

// ---------------------------------------------------------
// INTASEND SIDE SIMULATION -> Generates the Header
// ---------------------------------------------------------
console.log('--- SIMULATING INTASEND SENDING WEBHOOK ---');
console.log(`Setting Challenge/Secret to: "${PROPOSED_CHALLENGE}"`);

// IntaSend calculates signature using the Challenge
const incomingSignature = crypto
    .createHmac('sha256', PROPOSED_CHALLENGE)
    .update(rawBody)
    .digest('hex');

console.log(`Generated X-IntaSend-Signature: ${incomingSignature}`);
console.log('');


// ---------------------------------------------------------
// PAYKEY BACKEND SIMULATION -> Verifies the Header
// ---------------------------------------------------------

// Mock of the new verifyWebhookSignature function
function verifyWebhookSignature(signature, bodyBuffer, configuredSecret) {
    const hmac = crypto
        .createHmac('sha256', configuredSecret)
        .update(bodyBuffer)
        .digest('hex');

    const isValid = (hmac === signature);

    console.log(`Verifying with secret: "${configuredSecret}"`);
    console.log(`  Calculated: ${hmac}`);
    console.log(`  Received:   ${signature}`);
    console.log(`  Match?      ${isValid ? '✅ YES' : '❌ NO'}`);
    return isValid;
}


// TEST 1: The Fix (Configured Secret matches Challenge)
console.log('--- TEST 1: PROPOSED FIX (Secrets Match) ---');
const isSuccess1 = verifyWebhookSignature(incomingSignature, rawBody, PROPOSED_CHALLENGE);

if (isSuccess1) {
    console.log('RESULT: PASSED. This confirms that if Challenge = EnvVar, verification works.');
} else {
    console.log('RESULT: FAILED.');
}
console.log('');


// TEST 2: The Current Bug (Configured Secret != Challenge)
console.log('--- TEST 2: CURRENT STATE (Secrets Mismatch) ---');
// Simulating what happens if we use the API Key but IntaSend signs with Challenge
const isSuccess2 = verifyWebhookSignature(incomingSignature, rawBody, OLD_API_KEY);

if (!isSuccess2) {
    console.log('RESULT: FAILED (As expected). This explains why it breaks if secrets don\'t match.');
} else {
    console.log('RESULT: PASSED (Unexpected).');
}
