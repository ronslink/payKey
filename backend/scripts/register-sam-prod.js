/**
 * Register Sam Olago in Production
 * Creates the user via the production API
 */

const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function registerSam() {
    console.log('🚀 Registering Sam Olago in Production...\n');
    console.log('   API:', API_URL);

    try {
        // Try to register
        const res = await axios.post(`${API_URL}/auth/register`, {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
            firstName: 'Sam',
            lastName: 'Olago',
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
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
        });

        console.log('✅ Login successful!');
        console.log('   Token:', loginRes.data.access_token?.substring(0, 50) + '...');

    } catch (err) {
        console.error('❌ Login failed:', err.response?.data?.message || err.message);
    }
}

registerSam();
