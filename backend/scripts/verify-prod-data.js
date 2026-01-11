const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function verifyProdData() {
    console.log('🔍 Verifying Test User Data in Production...\n');

    let token;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!'
        });
        token = loginResponse.data.access_token;
        console.log('✅ Login successful');
    } catch (error) {
        console.error('❌ Login failed:', error.message);
        return;
    }

    const authHeaders = { Authorization: 'Bearer ' + token };

    // 1. Check Workers
    try {
        const workersRes = await axios.get(`${API_URL}/workers`, { headers: authHeaders });
        console.log(`\n📊 Workers Found: ${workersRes.data.length}`);
        workersRes.data.forEach(w => console.log(`   - ${w.name} (${w.employmentType})`));
    } catch (e) {
        console.error('❌ Failed to fetch workers:', e.message);
    }

    // 2. Check Pay Periods
    try {
        const periodsRes = await axios.get(`${API_URL}/pay-periods`, { headers: authHeaders });
        const periods = Array.isArray(periodsRes.data.data) ? periodsRes.data.data : periodsRes.data;
        console.log(`\n📅 Pay Periods Found: ${periods.length}`);
        periods.forEach(p => console.log(`   - ${p.name}: ${p.status} (End: ${p.endDate})`));
    } catch (e) {
        console.error('❌ Failed to fetch pay periods:', e.message);
    }

    // 3. Check Payroll Records (for latest period if exists)
    // We'll just check stats
    try {
        const statsRes = await axios.get(`${API_URL}/stats/dashboard`, { headers: authHeaders });
        console.log('\n📈 Dashboard Stats:', JSON.stringify(statsRes.data, null, 2));
    } catch (e) {
        // console.error('❌ Failed to fetch stats:', e.message); 
    }
}

verifyProdData();
