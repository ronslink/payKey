const axios = require('axios');

async function testMpesaFlow() {
    try {
        console.log('🔍 1. Logging in with testuser...');

        // Login to get JWT
        const loginRes = await axios.post('http://localhost:3000/auth/login', {
            email: 'testuser@paykey.com',
            password: 'testuser123'
        });

        const token = loginRes.data.access_token;
        console.log('✅ Login successful! Token received.');

        // API Config
        const config = {
            headers: { Authorization: `Bearer ${token}` }
        };

        console.log('\n🔍 2. Initiating M-Pesa Topup (STK Push)...');
        // Using a dummy phone number - typically Sandbox expects specific test numbers
        // 254708374149 is often used for success in Sandbox
        const phoneNumber = '254708374149';
        const amount = 100;

        const topupRes = await axios.post('http://localhost:3000/payments/unified/mpesa/topup', {
            phoneNumber,
            amount
        }, config);

        console.log('✅ STK Push Initiated!');
        console.log('Response:', topupRes.data);

        const checkoutRequestId = topupRes.data.checkoutRequestId;

        console.log('\n🔍 3. Verifying Transaction Record...');
        // We'll verify by listing recent transactions
        const dashboardRes = await axios.get('http://localhost:3000/payments/unified/dashboard', config);

        const transactions = dashboardRes.data.recentTransactions;
        const foundTransaction = transactions.find(t =>
            t.providerRef === checkoutRequestId ||
            (t.metadata && t.metadata.phoneNumber === phoneNumber && t.amount == amount)
        );

        if (foundTransaction) {
            console.log('✅ Transaction found in dashboard!');
            console.log('   ID:', foundTransaction.id);
            console.log('   Status:', foundTransaction.status);
            console.log('   Amount:', foundTransaction.amount);
        } else {
            console.warn('⚠️ Transaction NOT found in recent dashboard list (might be delayed or pagination issue).');
            console.log('Recent transactions:', transactions.map(t => ({ id: t.id, amount: t.amount, status: t.status })));
        }

    } catch (error) {
        if (error.response) {
            console.log('❌ Request failed');
            console.log('Status:', error.response.status);
            console.log('Response:', error.response.data);
        } else {
            console.log('❌ Network/Script error:', error.message);
        }
    }
}

testMpesaFlow();
