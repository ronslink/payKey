const axios = require('axios');

const API_URL = 'https://api.paydome.co';

// Helper to delay (avoid rate limits)
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function seedPayrollData() {
    console.log('🚀 Seeding payroll data for Test User via API...\n');
    console.log('Target API:', API_URL);

    let token;
    let user;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!',
        });
        token = loginResponse.data.access_token;
        user = loginResponse.data.user;
        console.log('✅ Authenticated as Test User');
    } catch (error) {
        console.error('❌ Authentication failed:', error.message);
        return;
    }

    const authHeaders = { Authorization: 'Bearer ' + token };

    // 1. Get Workers
    let workers = [];
    try {
        const res = await axios.get(`${API_URL}/workers`, { headers: authHeaders });
        workers = res.data;
        console.log('📊 Found ' + workers.length + ' workers');

        if (workers.length === 0) {
            console.log('⚠️ No workers found. Run worker seed first.');
            return;
        }
    } catch (e) {
        console.error('❌ Failed to fetch workers:', e.message);
        return;
    }

    // 2. Define Pay Periods (Only 2025)
    // Adjust dates as needed. Assuming typical monthly cycle.
    const payPeriods = [
        {
            name: 'January 2025',
            startDate: '2025-01-01',
            endDate: '2025-01-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-02-01'
        },
        {
            name: 'February 2025',
            startDate: '2025-02-01',
            endDate: '2025-02-28',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-03-01'
        }
    ];

    for (const periodData of payPeriods) {
        try {
            console.log(`\n📅 Processing Period: ${periodData.name}`);
            await delay(1000); // 1s delay per period

            // A. Create Pay Period (Force Clean State)
            let payPeriod;

            // 1. Fetch all periods
            const allPeriodsRes = await axios.get(`${API_URL}/pay-periods?limit=100`, { headers: authHeaders });
            const allPeriods = Array.isArray(allPeriodsRes.data.data) ? allPeriodsRes.data.data : allPeriodsRes.data;

            // 2. Find existing collision
            const existingPeriod = allPeriods.find(p => p.name === periodData.name);

            if (existingPeriod) {
                console.log(`   found existing period: ${existingPeriod.id} (${existingPeriod.status}).`);
                payPeriod = existingPeriod;
            } else {
                // 3. Create Fresh
                try {
                    const res = await axios.post(`${API_URL}/pay-periods`, periodData, { headers: authHeaders });
                    payPeriod = res.data;
                    console.log(`   ✅ Pay Period Created: ${payPeriod.id}`);
                } catch (createError) {
                    console.log(`      ⚠️ Create failed: ${createError.response?.data?.message || createError.message}`);
                    continue;
                }
            }

            let isCompleted = (payPeriod.status === 'COMPLETED' || payPeriod.status === 'CLOSED');

            if (isCompleted) {
                console.log('   ⏭️  Period already completed.');
            } else {
                // B. Calculate Payroll
                console.log(`   💰 Calculating per worker...`);
                const draftItems = [];
                for (const worker of workers) {
                    // Skip if worker started after period
                    if (new Date(worker.startDate) > new Date(periodData.endDate)) continue;

                    try {
                        const calcRes = await axios.post(`${API_URL}/payroll/calculate`, {
                            payPeriodId: payPeriod.id,
                            workerIds: [worker.id]
                        }, { headers: authHeaders });

                        const result = calcRes.data;
                        if (result.payrollItems && result.payrollItems.length > 0) {
                            const item = result.payrollItems[0];
                            draftItems.push({
                                workerId: worker.id,
                                grossSalary: item.grossSalary,
                                bonuses: 0,
                                otherEarnings: 0,
                                otherDeductions: 0
                            });
                        }
                    } catch (calcErr) {
                        // Ignore calc errors (maybe already calculated)
                    }
                }

                if (draftItems.length > 0) {
                    // C. Save Draft
                    console.log(`   📝 Saving ${draftItems.length} draft records...`);
                    try {
                        await axios.post(`${API_URL}/payroll/draft`, {
                            payPeriodId: payPeriod.id,
                            payrollItems: draftItems
                        }, { headers: authHeaders });
                    } catch (draftErr) {
                        console.error(`      ❌ Draft save failed: ${draftErr.message}`);
                    }

                    // D. Finalize
                    console.log(`   🔒 Finalizing...`);
                    try {
                        const finalizeRes = await axios.post(`${API_URL}/payroll/finalize/${payPeriod.id}`, {
                            skipPayout: true
                        }, { headers: authHeaders });

                        console.log(`      ✅ Finalize trigger success`);

                    } catch (finErr) {
                        console.error(`   ❌ Finalize failed: ${finErr.message}`);
                    }
                }
            }

            console.log(`   ✨ Period ${periodData.name} done.`);

        } catch (error) {
            console.error(`❌ Error processing period ${periodData.name}:`, error.message);
        }
    }

    console.log('\n✅ Payroll seeding completed!');
}

seedPayrollData();
