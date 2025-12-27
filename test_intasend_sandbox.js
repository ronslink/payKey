// Native fetch used
const BASE_URL = 'http://localhost:3000';
const USER_EMAIL = 'testuser@paykey.com';
const USER_PASS = 'testuser123';
const TEST_PHONE = '254708374149'; // Official IntaSend Test Number

async function main() {
    try {
        console.log('🚀 Starting Real IntaSend Sandbox Test...');

        // 1. Login
        console.log('\n🔐 Logging in...');
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: USER_EMAIL, password: USER_PASS }),
        });

        if (!loginRes.ok) throw new Error(`Login failed: ${loginRes.status}`);
        const { access_token: token } = await loginRes.json();
        console.log('✅ Login successful');

        // 2. Initiate Real STK Push (Amount !== 777)
        console.log(`\n💳 Initiating REAL STK Push to ${TEST_PHONE}...`);
        const stkRes = await fetch(`${BASE_URL}/payments/initiate-stk`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                phoneNumber: TEST_PHONE,
                amount: 10 // Normal amount
            }),
        });

        const stkData = await stkRes.json();

        if (!stkRes.ok) {
            console.log('❌ API Error Response:', JSON.stringify(stkData, null, 2));
            throw new Error(`STK Push failed with status: ${stkRes.status}`);
        }

        console.log('✅ STK Push Response:', JSON.stringify(stkData, null, 2));

        // Check for Invoice ID (Standard IntaSend response structure)
        if (stkData.invoice && stkData.invoice.invoice_id) {
            console.log(`✅ Success! Invoice ID: ${stkData.invoice.invoice_id}`);

            if (stkData.invoice.invoice_id.includes('SIM')) {
                console.error('⛔ FAILURE: Got a SIMULATED ID! The bypass logic is broken.');
            } else {
                console.log('🎉 CONFIRMED: This processed via the REAL IntaSend Sandbox API.');
            }
        } else {
            console.warn('⚠️ Response format ambiguous. Check logs above.');
        }

    } catch (error) {
        console.error('❌ Test Failed:', error.message);
    }
}

main();
