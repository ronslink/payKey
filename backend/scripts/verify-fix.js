const axios = require('axios');

const API_URL = 'http://localhost:3000';
const EMAIL = 'testuser@paykey.com';
const PASSWORD = 'testuser123';

async function verifyFix() {
    try {
        console.log('🔍 Verifying Partial Payroll Fix...');

        // 1. Login
        console.log('1. Logging in...');
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: EMAIL,
            password: PASSWORD
        });
        const token = loginResponse.data.access_token;
        console.log('✅ Login successful');

        // 2. Get Workers
        console.log('2. Fetching workers...');
        const workersResponse = await axios.get(`${API_URL}/workers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const workers = workersResponse.data;
        console.log(`📊 Found ${workers.length} workers`);

        if (workers.length < 2) {
            console.error('❌ Need at least 2 workers to test partial selection.');
            return;
        }

        const worker1 = workers[0];
        const worker2 = workers[1];
        console.log(`   Selected Worker 1: ${worker1.name} (${worker1.id}) - Gross: ${worker1.salaryGross}`);
        console.log(`   Selected Worker 2: ${worker2.name} (${worker2.id}) - Gross: ${worker2.salaryGross}`);

        // 3. Find/Create Pay Period (Dec 2026)
        let payPeriodId;
        try {
            console.log('   Generating/Fetching period for Dec 2026...');
            // Try to generate directly
            const genRes = await axios.post(`${API_URL}/pay-periods/generate`, {
                frequency: 'MONTHLY',
                startDate: '2026-12-01',
                endDate: '2026-12-31'
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            const periods = genRes.data;
            if (periods && periods.length > 0) {
                const p = periods[0];
                payPeriodId = p.id;
                console.log(`3. Using PayPeriod: ${p.name} (${payPeriodId}) - Status: ${p.status}`);
            } else {
                throw new Error('Generate returned no periods');
            }
        } catch (e) {
            console.error('❌ FATAL: Error generating periods:', e.message);
            if (e.response) console.error('   Response:', e.response.data);
            return;
        }

        // 4. Save Draft for BOTH workers
        console.log('4. Saving draft for both workers...');
        const draftItems = [
            { workerId: worker1.id, grossSalary: worker1.salaryGross },
            { workerId: worker2.id, grossSalary: worker2.salaryGross }
        ];

        try {
            await axios.post(`${API_URL}/payroll/draft`, {
                payPeriodId,
                payrollItems: draftItems
            }, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            console.log('✅ Draft saved.');
        } catch (e) {
            console.error('❌ Failed to save draft:', e.message);
            if (e.response) console.error('   Response:', e.response.data);
            return;
        }

        // 5. Verify Funds for BOTH (Legacy/Default behavior)
        console.log('5. Verifying funds for ALL...');
        const verifyAll = await axios.post(`${API_URL}/payroll/verify-funds/${payPeriodId}`, {}, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const amountAll = verifyAll.data.requiredAmount;
        console.log(`   Required Amount (All): ${amountAll}`);

        // 6. Verify Funds for ONLY WORKER 1 (New Fix)
        console.log(`6. Verifying funds for ONLY ${worker1.name}...`);
        const verifyPartial = await axios.post(`${API_URL}/payroll/verify-funds/${payPeriodId}`, {
            workerIds: [worker1.id]
        }, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const amountPartial = verifyPartial.data.requiredAmount;
        console.log(`   Required Amount (Partial): ${amountPartial}`);

        // Validation
        if (amountPartial < amountAll) {
            console.log('✅ SUCCESS: Partial amount is less than total amount!');
            console.log(`   Difference: ${amountAll - amountPartial}`);
        } else {
            // If amounts are equal, check if they are same worker?
            console.error('❌ FAILURE: Partial amount equals total amount (Fix not working)');
        }

        if (amountPartial > 0) {
            console.log('✅ Partial amount is > 0');
        } else {
            console.error('❌ FAILURE: Partial amount is 0 (Something went wrong)');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
        if (error.response) {
            console.error('   Status:', error.response.status);
            console.error('   Data:', JSON.stringify(error.response.data, null, 2));
        }
    }
}

verifyFix();
