/**
 * Test IntaSend API Credentials
 * 
 * This script tests if the configured IntaSend credentials are valid
 * by making direct API calls to IntaSend's endpoints.
 */

const axios = require('axios');

// IntaSend Test Credentials - Use environment variables
const INTASEND_PUBLISHABLE_KEY = process.env.INTASEND_PUBLISHABLE_KEY_TEST || 'your_test_publishable_key';
const INTASEND_SECRET_KEY = process.env.INTASEND_SECRET_KEY_TEST || 'your_test_secret_key';

const BASE_URL = 'https://sandbox.intasend.com/api';

async function testCredentials() {
    console.log('🧪 Testing IntaSend API Credentials...\n');
    console.log(`📋 Publishable Key: ${INTASEND_PUBLISHABLE_KEY}`);
    console.log(`📋 Secret Key: ${INTASEND_SECRET_KEY.substring(0, 20)}...`);
    console.log('');

    try {
        // Test 1: Check if keys are in expected format
        console.log('✅ Step 1: Validating key format...');
        if (!INTASEND_PUBLISHABLE_KEY.startsWith('ISPubKey_test_')) {
            throw new Error('Invalid publishable key format. Expected ISPubKey_test_...');
        }
        if (!INTASEND_SECRET_KEY.startsWith('ISSecretKey_test_')) {
            throw new Error('Invalid secret key format. Expected ISSecretKey_test_...');
        }
        console.log('✅ Key format is valid\n');

        // Test 2: Get wallet balance
        console.log('🔄 Step 2: Testing wallet balance endpoint...');
        try {
            const balanceResponse = await axios.get(
                `${BASE_URL}/v1/wallets/`,
                {
                    headers: {
                        'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                        'Content-Type': 'application/json'
                    }
                }
            );
            console.log('✅ Wallet Balance:', JSON.stringify(balanceResponse.data, null, 2));
        } catch (error) {
            if (error.response) {
                console.log(`⚠️ Wallet endpoint returned: ${error.response.status}`);
                console.log('Response:', JSON.stringify(error.response.data, null, 2));
            } else {
                console.log(`⚠️ Wallet endpoint error: ${error.message}`);
            }
        }

        // Test 3: Send money initiate (for B2C payouts)
        console.log('\n🔄 Step 3: Testing send-money initiate endpoint...');
        try {
            const sendMoneyResponse = await axios.post(
                `${BASE_URL}/v1/send-money/initiate/`,
                {
                    currency: 'KES',
                    provider: 'MPESA-B2C',
                    transactions: [
                        {
                            account: '254708374149', // Test phone number
                            amount: 10,
                            narrative: 'Test payout'
                        }
                    ]
                },
                {
                    headers: {
                        'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                        'Content-Type': 'application/json'
                    }
                }
            );
            console.log('✅ Send Money Response:', JSON.stringify(sendMoneyResponse.data, null, 2));
        } catch (error) {
            if (error.response) {
                const status = error.response.status;
                const data = error.response.data;
                
                if (status === 401) {
                    console.log('❌ Authentication failed: Invalid credentials');
                    console.log('💡 The credentials may have expired or be incorrect');
                } else if (status === 400) {
                    console.log('⚠️ Bad request - checking if credentials work...');
                    console.log('Response:', JSON.stringify(data, null, 2));
                } else {
                    console.log(`⚠️ Send Money endpoint returned: ${status}`);
                    console.log('Response:', JSON.stringify(data, null, 2));
                }
            } else {
                console.log(`⚠️ Send Money error: ${error.message}`);
            }
        }

        // Test 4: STK Push endpoint
        console.log('\n🔄 Step 4: Testing STK Push endpoint...');
        try {
            const stkResponse = await axios.post(
                `${BASE_URL}/v1/payment/mpesa-stk-push/`,
                {
                    phone_number: '254708374149',
                    amount: 10,
                    currency: 'KES',
                    callback_url: 'http://localhost:3000/payments/callback'
                },
                {
                    headers: {
                        'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                        'Content-Type': 'application/json'
                    }
                }
            );
            console.log('✅ STK Push Response:', JSON.stringify(stkResponse.data, null, 2));
        } catch (error) {
            if (error.response) {
                console.log(`⚠️ STK Push endpoint returned: ${error.response.status}`);
                console.log('Response:', JSON.stringify(error.response.data, null, 2));
            } else {
                console.log(`⚠️ STK Push error: ${error.message}`);
            }
        }

        console.log('\n📝 Summary:');
        console.log('- Key format is valid ✓');
        console.log('- If endpoints return 401/403, credentials need updating');
        console.log('- Get new credentials from: https://sandbox.intasend.com/dashboard/settings/api/');
        console.log('- Current configuration is set to: SANDBOX MODE (INTASEND_IS_LIVE=false)');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

testCredentials();
