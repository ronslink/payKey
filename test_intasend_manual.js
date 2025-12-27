// Native fetch is available in Node 18+

// Configuration
const BASE_URL = 'http://localhost:3000';
const USER_EMAIL = 'testuser@paykey.com';
const USER_PASS = 'testuser123';
const TEST_PHONE = '254712345678'; // Safaricom Sandbox Test Number

async function runTest() {
    console.log('🚀 Starting IntaSend Connectivity Test...');

    // 1. Login
    console.log('\n--- Step 1: Login ---');
    let token;
    try {
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: USER_EMAIL, password: USER_PASS }),
        });

        if (!loginRes.ok) {
            const err = await loginRes.text();
            throw new Error(`Login Failed: ${loginRes.status} ${err}`);
        }

        const loginData = await loginRes.json();
        token = loginData.access_token; // Adjust based on actual response structure
        console.log('✅ Login Successful. Token acquired.');
    } catch (error) {
        console.error('Login Error:', error.message);
        process.exit(1);
    }

    // 2. Initiate STK Push (Top Up)
    console.log('\n--- Step 2: Test Top Up (STK Push) ---');
    try {
        const stkRes = await fetch(`${BASE_URL}/payments/initiate-stk`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ phoneNumber: TEST_PHONE, amount: 10 }), // Test amount 10 KES
        });

        const stkData = await stkRes.json();
        console.log('STK Response:', JSON.stringify(stkData, null, 2));

        if (stkRes.ok) {
            console.log('✅ Top Up Request sent successfully to IntaSend Sandbox.');
        } else {
            console.error('❌ Top Up Failed.');
        }
    } catch (error) {
        console.error('STK Push Error:', error.message);
    }

    // 3. Initiate Payout (B2C)
    // Note: Payouts usually require balance in the IntaSend wallet.
    // In Sandbox, you might need to mock balance or use test account.
    console.log('\n--- Step 3: Test Payout (B2C) ---');
    try {
        // We need a dummy transaction ID for the mapping, assuming generic structure
        const b2cRes = await fetch(`${BASE_URL}/payments/send-b2c`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                phoneNumber: TEST_PHONE,
                amount: 10,
                transactionId: `TEST_TRX_${Date.now()}`,
                remarks: 'Test Salary Payout'
            }),
        });

        const b2cData = await b2cRes.json();
        console.log('B2C Response:', JSON.stringify(b2cData, null, 2));

        if (b2cRes.ok) {
            console.log('✅ Payout Request sent successfully to IntaSend Sandbox.');
        } else {
            console.error('❌ Payout Failed.');
        }
    } catch (error) {
        console.error('B2C Error:', error.message);
    }

    console.log('\n🏁 Test Complete. Check Backend Logs for detailed debug info.');
}

runTest();
