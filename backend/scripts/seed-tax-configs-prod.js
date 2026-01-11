const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function seedTaxConfigs() {
    console.log('🚀 Seeding Tax Configurations in Production...\n');
    console.log('Target API:', API_URL);

    let token;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!',
        });
        token = loginResponse.data.access_token;
        console.log('✅ Authenticated successfully');
    } catch (error) {
        console.error('❌ Authentication failed:', error.response?.data?.message || error.message);
        return;
    }

    // Trigger the seed endpoint
    try {
        console.log('🔄 Triggering standard config seeding...');
        await axios.post(`${API_URL}/tax-config/seed`, {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('✅ Tax configs seeded successfully');
    } catch (error) {
        console.error('❌ Failed to seed tax configs:', error.response?.data?.message || error.message);
        if (error.response?.status === 201 || error.response?.status === 200) {
            console.log('(But it might have worked if response is empty)');
        }
    }

    // Verify by checking configs
    try {
        console.log('\n🔍 Verifying tax configs...');
        const configsRes = await axios.get(`${API_URL}/tax-config/active`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('📊 Tax Configs Found:', configsRes.data.length);
        configsRes.data.forEach(c => console.log(`   - ${c.taxType}: ${c.rateType} (${c.effectiveFrom})`));
    } catch (error) {
        console.log('❌ Failed to fetch tax configs:', error.response?.data?.message || error.message);
    }
}

seedTaxConfigs();
