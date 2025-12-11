const axios = require('axios');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const CREDENTIALS = {
    email: 'testuser@paykey.com',
    password: 'testuser123'
};

async function verifyExportFlow() {
    try {
        console.log('🔄 1. Logging in...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, CREDENTIALS);
        const token = loginRes.data.access_token;
        console.log('✅ Login successful. Token obtained.');

        const headers = { Authorization: `Bearer ${token}` };

        console.log('\n🔄 2. Requesting KRA P10 Export...');
        const startDate = new Date();
        startDate.setDate(1); // 1st of current month
        const endDate = new Date();

        const exportRes = await axios.post(
            `${BASE_URL}/export`,
            {
                exportType: 'KRA_P10_CSV',
                startDate: startDate.toISOString(),
                endDate: endDate.toISOString()
            },
            { headers }
        );

        console.log('✅ Export created successfully.');
        console.log('   ID:', exportRes.data.id);
        console.log('   File Name:', exportRes.data.fileName);
        console.log('   Record Count:', exportRes.data.recordCount);

        const exportId = exportRes.data.id;
        const downloadUrl = `${BASE_URL}/export/download/${exportId}`;

        console.log(`\n🔄 3. Downloading file from ${downloadUrl}...`);
        const downloadRes = await axios.get(downloadUrl, {
            headers,
            responseType: 'arraybuffer'
        });

        console.log('✅ Download successful.');
        console.log('   Content Length:', downloadRes.data.length, 'bytes');

        // Verify content snippet (first 100 chars)
        const content = downloadRes.data.toString('utf-8');
        console.log('   Preview (first 100 chars):');
        console.log('   ---------------------------------------------------');
        console.log('   ' + content.substring(0, 100));
        console.log('   ---------------------------------------------------');

        if (content.includes('PIN of Employee')) {
            console.log('✅ CONTENT CHECK PASSED: Found "PIN of Employee" header.');
        } else {
            console.error('❌ CONTENT CHECK FAILED: Header missing.');
        }

    } catch (error) {
        if (error.response) {
            console.error('❌ Request failed:', error.response.status, error.response.data);
        } else {
            console.error('❌ Error:', error.message);
        }
    }
}

verifyExportFlow();
