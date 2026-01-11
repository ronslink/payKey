/**
 * Register Test User in Production
 * Creates the user via the production API
 */

const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function registerTestUser() {
    console.log('🚀 Registering Test User in Production...\n');
    console.log('   API:', API_URL);

    try {
        // Try to register
        const res = await axios.post(`${API_URL}/auth/register`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!',
            firstName: 'Test',
            lastName: 'User',
            businessName: 'Test Business'
        });

        console.log('✅ Registration successful!');
        console.log('   Response:', JSON.stringify(res.data, null, 2));

    } catch (err) {
        if (err.response?.status === 409 || err.response?.data?.message?.includes('exists')) {
            console.log('ℹ️  User already exists. Trying to login...');
        } else {
            console.error('❌ Registration failed:', err.response?.data?.message || err.message);
        }
    }

    // Try to login to verify
    console.log('\n🔐 Verifying login...');
    try {
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!',
        });

        console.log('✅ Login successful!');
        console.log('   Token:', loginRes.data.access_token?.substring(0, 50) + '...');

    } catch (err) {
        console.error('❌ Login failed:', err.response?.data?.message || err.message);
    }
}

registerTestUser();
