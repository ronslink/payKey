const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function seedMinimalWorker() {
    try {
        console.log('🔍 Testing MINIMAL worker seeding...');

        // Login first
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!'
        });
        const token = loginResponse.data.access_token;
        console.log('✅ Login successful');

        const rnd = Math.floor(Math.random() * 10000).toString();

        const minimalWorker = {
            name: 'Minimal Worker ' + rnd,
            phoneNumber: '+2547' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0'),
            salaryGross: 50000,
            startDate: '2024-01-01'
        };

        console.log('Payload:', JSON.stringify(minimalWorker, null, 2));

        try {
            const createResponse = await axios.post(`${API_URL}/workers`, minimalWorker, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            console.log(`✅ Added minimal worker: ${createResponse.data.name}`);
        } catch (error) {
            console.log(`❌ Failed to add minimal worker:`, error.message);
            if (error.response) {
                console.log('   Status:', error.response.status);
                // console.log('   Data:', JSON.stringify(error.response.data, null, 2));
            }
        }
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

seedMinimalWorker();
