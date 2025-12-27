// Native fetch used

// Configuration
const BASE_URL = 'http://localhost:3000';
const USER_EMAIL = 'testuser@paykey.com';
const USER_PASS = 'testuser123';

async function runBulkTest() {
    console.log('🚀 Starting Bulk Payroll Payout Test (15 Workers)...');

    // 1. Authenticate
    let token;
    try {
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: USER_EMAIL, password: USER_PASS }),
        });
        const loginData = await loginRes.json();
        if (!loginRes.ok) throw new Error(loginData.message || 'Login Failed');
        token = loginData.access_token;
        console.log('✅ logged in.');
    } catch (err) {
        console.error('Login Error:', err.message);
        process.exit(1);
    }

    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };

    // 2. Create Pay Period
    const periodName = `Bulk Test ${Date.now()}`;
    let payPeriodId;
    try {
        const periodRes = await fetch(`${BASE_URL}/pay-periods`, {
            method: 'POST',
            headers,
            body: JSON.stringify({ name: periodName, startDate: '2025-12-01', endDate: '2025-12-31' })
        });
        const periodData = await periodRes.json();
        console.log('Period Create Response:', JSON.stringify(periodData));

        // Check if ID is directly in root or in 'data'
        payPeriodId = periodData.id || (periodData.data && periodData.data.id);

        if (!payPeriodId) {
            // Fallback: fetch latest
            console.log('ID not returned. Fetching latest period...');
            const listRes = await fetch(`${BASE_URL}/pay-periods`, { headers });
            const listData = await listRes.json();
            // Assuming listData is array or { data: [] }
            const periods = Array.isArray(listData) ? listData : listData.data;
            if (periods && periods.length > 0) {
                payPeriodId = periods[0].id; // Most recent?
            }
        }

        if (!payPeriodId) {
            throw new Error('Could not determine Pay Period ID');
        }

        console.log(`✅ Pay Period Created/Found: ${payPeriodId}`);
    } catch (err) {
        console.error('Create Pay Period Error:', err.message);
        process.exit(1);
    }

    // 3. Create 15 Dummy Workers
    const workerIds = [];
    try {
        console.log('Creating 15 dummy workers...');
        for (let i = 1; i <= 15; i++) {
            const workerRes = await fetch(`${BASE_URL}/workers`, {
                method: 'POST',
                headers,
                body: JSON.stringify({
                    name: `Worker ${i}`,
                    phoneNumber: `2547${String(i).padStart(8, '0')}`,
                    paymentMethod: 'MPESA',
                    salaryGross: 1000 + i,
                    startDate: '2025-01-01'
                })
            });
            const workerData = await workerRes.json();
            // Add delay to avoid Throttler
            await new Promise(r => setTimeout(r, 200));

            if (workerRes.ok) {
                workerIds.push(workerData.id);
            } else {
                console.error(`Failed to create worker ${i}: ${JSON.stringify(workerData)}`);
            }
        }
        console.log(`✅ Created ${workerIds.length} workers.`);
    } catch (err) {
        console.error('Worker Creation Error:', err.message);
        // Continue if we have some
    }

    if (workerIds.length === 0) process.exit(1);

    // 4. Process Payroll (Draft -> Finalize -> Pay)
    // Calling POST /payroll/process
    try {
        console.log('Executing Bulk Payout...');
        const processRes = await fetch(`${BASE_URL}/payroll/process`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                payPeriodId,
                workerIds,
                skipPayout: false
            })
        });

        const processData = await processRes.json();
        console.log('Process Response:', JSON.stringify(processData, null, 2));

        if (processRes.ok) {
            console.log('✅ Bulk Payout Executed Successfully.');
        } else {
            console.error('❌ Bulk Payout Failed.');
        }

    } catch (err) {
        console.error('Payout Error:', err.message);
    }
}

runBulkTest();
