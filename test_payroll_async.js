// const fetch = require('node-fetch'); // Native fetch in Node 18+

// Configuration
const BASE_URL = 'http://localhost:3000';
const USER_EMAIL = 'testuser@paykey.com';
const USER_PASS = 'testuser123';

async function main() {
    try {
        console.log('🚀 Starting Async Payroll Test...');

        // 1. Login
        console.log('\n🔐 Logging in...');
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: USER_EMAIL, password: USER_PASS }),
        });

        if (!loginRes.ok) throw new Error(`Login failed: ${loginRes.status}`);
        const loginData = await loginRes.json();
        const token = loginData.access_token;
        console.log('✅ Login successful');

        // 2. Create Pay Period
        console.log('\n📅 Creating Pay Period...');
        const periodRes = await fetch(`${BASE_URL}/pay-periods`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                startDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(), // +60 days (Future)
                endDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
                frequency: 'MONTHLY'
            }),
        });

        let payPeriodId;
        if (periodRes.ok) {
            const periodData = await periodRes.json();
            payPeriodId = periodData.id || periodData.data?.id;
        }

        // Fallback: Get latest if creation failed (e.g. overlap)
        if (!payPeriodId) {
            console.log('⚠️  Creation might have failed or overlapped. Fetching latest...');
            const listRes = await fetch(`${BASE_URL}/pay-periods?limit=1`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const listData = await listRes.json();
            payPeriodId = listData.data?.[0]?.id || listData[0]?.id;
        }

        if (!payPeriodId) throw new Error('Could not get Pay Period ID');
        console.log(`✅ Using Pay Period ID: ${payPeriodId}`);

        // 3. Create Dummy Workers (Just 2 for speed, assume existing ones work)
        // We will skip creating new ones if there are already some to save time, 
        // or create 2 just to be sure.
        // 3. Get or Create Workers
        let workerIds = [];
        console.log('\n👷 Fetching existing workers...');
        const existingWorkersRes = await fetch(`${BASE_URL}/workers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (existingWorkersRes.ok) {
            const wData = await existingWorkersRes.json();
            const existing = wData.data || wData;
            if (Array.isArray(existing) && existing.length > 0) {
                workerIds = existing.map(w => w.id).slice(0, 5); // Take up to 5
                console.log(`✅ Found ${workerIds.length} existing workers`);
            }
        }

        if (workerIds.length < 2) {
            console.log('\n👷 Creating additional Test Workers...');
            for (let i = 0; i < 2; i++) {
                const salary = 30000 + i * 1000;
                const workerRes = await fetch(`${BASE_URL}/workers`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        name: `Async Worker ${Date.now()}_${i}`,
                        phoneNumber: `25471234567${i}`,
                        salaryGross: salary,
                        employmentType: 'FULL_TIME',
                        status: 'ACTIVE',
                        startDate: new Date().toISOString()
                    }),
                });
                const wData = await workerRes.json();
                if (wData.id) {
                    workerIds.push(wData.id);
                } else {
                    console.error('⚠️ Failed to create worker:', wData);
                }
            }
        }
        console.log(`✅ Created ${workerIds.length} workers`);

        if (workerIds.length === 0) throw new Error('No workers to process');

        // 4. Trigger Async Processing
        console.log('\n⚡ Triggering Payroll Processing (Async)...');
        const start = Date.now();
        const processRes = await fetch(`${BASE_URL}/payroll/process`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                payPeriodId,
                workerIds,
                skipPayout: true // SKIP PAYOUT to avoid real IntaSend calls in this quick test, verify Queue Logic
            }),
        });

        const processData = await processRes.json();
        console.log('📩 Response:', processData);

        if (processData.status !== 'PROCESSING') {
            throw new Error(`Expected status PROCESSING, got ${processData.status}`);
        }
        console.log('✅ Async Request Accepted!');

        // 5. Poll for Completion
        console.log('\n⏳ Polling for completion...');
        let attempts = 0;
        while (attempts < 20) {
            const checkRes = await fetch(`${BASE_URL}/pay-periods/${payPeriodId}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const checkData = await checkRes.json();
            const status = checkData.status; // PayPeriod status

            console.log(`... Attempt ${attempts + 1}: Status = ${status}`);

            if (status === 'COMPLETED') {
                const timeTaken = Date.now() - start;
                console.log(`\n🎉 Payroll Completed in ${timeTaken}ms!`);
                break;
            }

            if (status === 'FAILED') { // Hypothetical status if we added it
                throw new Error('Payroll Failed');
            }

            await new Promise(r => setTimeout(r, 1000)); // Wait 1s
            attempts++;
        }

        if (attempts >= 20) {
            console.error('❌ Timeout waiting for completion');
        }

    } catch (error) {
        console.error('❌ Test Failed:', error.message);
    }
}

// Check for native fetch
if (!globalThis.fetch) {
    console.error('Native fetch not found. Run with node 18+ or install node-fetch');
    process.exit(1);
}

main();
