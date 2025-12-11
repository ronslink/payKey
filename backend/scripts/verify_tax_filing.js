const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

const BASE_URL = 'http://localhost:3000';
const EMAIL = 'testuser@paykey.com';
const PASSWORD = 'testuser123'; // Default dev password

async function verifyTaxFiling() {
    try {
        console.log('🔄 1. Logging in...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: EMAIL,
            password: PASSWORD
        });
        const token = loginRes.data.access_token;
        console.log('✅ Login successful.');

        const headers = { Authorization: `Bearer ${token}` };

        // 2. Get/Create Pay Period
        console.log('🔄 2. Getting current Pay Period...');
        let payPeriodId;
        try {
            const ppRes = await axios.get(`${BASE_URL}/pay-periods`, { headers });
            const periods = ppRes.data;
            if (periods.length > 0) {
                payPeriodId = periods[0].id;
                console.log(`✅ Found existing Pay Period: ${payPeriodId}`);
            } else {
                console.log('⚠️ No pay periods found. Creating one...');
                // Create a dummy pay period for validation
                const createRes = await axios.post(`${BASE_URL}/pay-periods`, {
                    name: 'January 2026',
                    startDate: '2026-01-01',
                    endDate: '2026-01-31',
                    frequency: 'MONTHLY'
                }, { headers });
                payPeriodId = createRes.data.id;
                console.log(`✅ Created Pay Period: ${payPeriodId}`);
            }
        } catch (e) {
            console.error('❌ Failed to get/create pay period:', e.message);
            if (e.response) console.error('Response Data:', JSON.stringify(e.response.data, null, 2));
            return;
        }

        // 3. Generate Tax Submission (Force it)
        console.log(`🔄 3. Generating Tax Submission for ${payPeriodId}...`);
        try {
            await axios.post(`${BASE_URL}/taxes/submissions/generate/${payPeriodId}`, {}, { headers });
            console.log('✅ Tax Submission generated/updated.');
        } catch (e) {
            console.warn('⚠️ Note: Generation might fail if no finalized payroll records exist. Continuing to check monthly summaries...');
            // We continue because maybe one already exists
        }

        // 4. Get Monthly Summaries and Check Status
        console.log('🔄 4. Fetching Monthly Summaries...');
        const summaryRes = await axios.get(`${BASE_URL}/taxes/submissions/monthly`, { headers });
        const summaries = summaryRes.data;

        if (summaries.length === 0) {
            console.error('❌ No monthly tax summaries found. Cannot verify filing.');
            return;
        }

        const targetSummary = summaries[0];
        console.log(`ℹ️ Target Summary: ${targetSummary.monthName} ${targetSummary.year} - Status: ${targetSummary.status}`);

        if (targetSummary.status === 'FILED') {
            console.log('✅ Target summary is already FILED. Testing re-filing or unfiling? (API only supports markAsFiled)');
            // Proceed to test checking API response for idempotency or verify historical logic
        }

        // 5. Mark as Filed
        console.log(`🔄 5. Marking ${targetSummary.monthName} ${targetSummary.year} as FILED...`);
        try {
            await axios.post(`${BASE_URL}/taxes/submissions/monthly/file`, {
                year: targetSummary.year,
                month: targetSummary.month
            }, { headers });
            console.log('✅ Mark as Filed request successful.');
        } catch (e) {
            console.error('❌ Failed to mark as filed:', e.response?.data || e.message);
            return;
        }

        // 6. Verify Status Update
        console.log('🔄 6. Verifying status update...');
        const verifyRes = await axios.get(`${BASE_URL}/taxes/submissions/monthly`, { headers });
        const updatedSummary = verifyRes.data.find(s => s.year === targetSummary.year && s.month === targetSummary.month);

        if (updatedSummary && updatedSummary.status === 'FILED') {
            console.log('✅ SUCCESS: Status updated to FILED.');
        } else {
            console.error(`❌ FAILURE: Status is still ${updatedSummary?.status}`);
        }

    } catch (error) {
        console.error('❌ Unexpected Error:', error.message);
        if (error.response) console.error('Response:', error.response.data);
    }
}

verifyTaxFiling();
