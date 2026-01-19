const axios = require('axios');

const BASE_URL = 'http://localhost:3000';
// Credentials for a test user (ensure this user exists or use seed)
const EMAIL = 'kingpublish@gmail.com';
const PASSWORD = 'Sam2026test!';

async function runTest() {
    try {
        console.log('1. Logging in...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: EMAIL,
            password: PASSWORD,
        });
        const token = loginRes.data.access_token;
        console.log('✅ Login Successful');

        console.log('2. Fetching Wallet Balance (Triggers Lazy Creation)...');
        const balanceRes = await axios.get(`${BASE_URL}/payments/wallet-balance`, {
            headers: { Authorization: `Bearer ${token}` },
        });
        console.log('✅ Balance Fetched:', balanceRes.data);

        if (!balanceRes.data.success) {
            throw new Error('Failed to fetch balance');
        }

        console.log('3. Initiating STK Push (Simulated)...');
        const stkRes = await axios.post(
            `${BASE_URL}/payments/initiate-stk`,
            { phoneNumber: '254700000000', amount: 100 },
            { headers: { Authorization: `Bearer ${token}` } }
        );
        console.log('✅ STK Push Initiated:', stkRes.data);

        console.log('🎉 Verification Complete: Wallet Architecture is ACTIVE');

    } catch (error) {
        console.error('❌ Test Failed:', error.response?.data || error.message || error);
        if (error.code === 'ECONNREFUSED') {
            console.error('Check if server is running on port 3001');
        }
        process.exit(1);
    }
}

runTest();
