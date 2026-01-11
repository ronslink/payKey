const axios = require('axios');

const API_URL = process.env.API_URL || 'http://localhost:3000';

// Helper to delay (avoid rate limits)
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function seedPayrollData() {
    console.log('🚀 Seeding payroll data via API...\n');
    console.log('Target API:', API_URL);

    let token;
    let user;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'kingpublish@gmail.com', // Sam Olago's email
            password: 'Sam2026test!',
        });
        token = loginResponse.data.access_token;
        user = loginResponse.data.user;
        console.log('✅ Authenticated as Sam Olago');
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

    // 1a. Cleanup & Filter Workers
    const targetNames = ['Musulwa Janet Ngoyisi', 'Kefa Nicholas Luvaga'];
    const keptWorkers = [];

    // Helper to normalize names for comparison (remove commas, extra spaces, lowercase)
    const normalize = (name) => name.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();

    console.log('\n🧹 Cleaning up unauthorized workers...');
    for (const worker of workers) {
        const normalizedWorkerName = normalize(worker.name);

        const isTarget = targetNames.some(target =>
            normalizedWorkerName.includes(normalize(target)) ||
            normalize(target).includes(normalizedWorkerName)
        );

        if (isTarget) {
            keptWorkers.push(worker);
            console.log(`   ✅ Keeping: ${worker.name}`);
        } else {
            try {
                await axios.delete(`${API_URL}/workers/${worker.id}`, { headers: authHeaders });
                console.log(`   🗑️  Deleted: ${worker.name}`);
            } catch (delErr) {
                console.error(`   ❌ Failed to delete ${worker.name}: ${delErr.message}`);
            }
        }
    }
    workers = keptWorkers;

    if (workers.length === 0) {
        console.log('⚠️ No target workers found after cleanup. Please ensure they are created.');
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
        },
        {
            name: 'March 2025',
            startDate: '2025-03-01',
            endDate: '2025-03-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-04-01'
        },
        {
            name: 'April 2025',
            startDate: '2025-04-01',
            endDate: '2025-04-30',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-05-01'
        },
        {
            name: 'May 2025',
            startDate: '2025-05-01',
            endDate: '2025-05-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-06-01'
        },
        {
            name: 'June 2025',
            startDate: '2025-06-01',
            endDate: '2025-06-30',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-07-01'
        },
        {
            name: 'July 2025',
            startDate: '2025-07-01',
            endDate: '2025-07-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-08-01'
        },
        {
            name: 'August 2025',
            startDate: '2025-08-01',
            endDate: '2025-08-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-09-01'
        },
        {
            name: 'September 2025',
            startDate: '2025-09-01',
            endDate: '2025-09-30',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-10-01'
        },
        {
            name: 'October 2025',
            startDate: '2025-10-01',
            endDate: '2025-10-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-11-01'
        },
        {
            name: 'November 2025',
            startDate: '2025-11-01',
            endDate: '2025-11-30',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2025-12-01'
        },
        {
            name: 'December 2025',
            startDate: '2025-12-01',
            endDate: '2025-12-31',
            frequency: 'MONTHLY',
            status: 'DRAFT',
            payDate: '2026-01-01'
        }
    ];

    for (const periodData of payPeriods) {
        try {
            console.log(`\n📅 Processing Period: ${periodData.name}`);
            await delay(1000); // 1s delay per period

            // A. Create Pay Period (Force Clean State)
            let payPeriod;

            // 1. Fetch all periods (with high limit to handle pagination)
            const allPeriodsRes = await axios.get(`${API_URL}/pay-periods?limit=100`, { headers: authHeaders });
            const allPeriods = Array.isArray(allPeriodsRes.data.data) ? allPeriodsRes.data.data : allPeriodsRes.data;

            // 2. Find existing collision
            // Match by Name OR Same Month/Year
            const targetDate = new Date(periodData.startDate);
            const existingPeriod = allPeriods.find(p => {
                if (p.name === periodData.name) return true;
                const pDate = new Date(p.startDate);
                return pDate.getFullYear() === targetDate.getFullYear() && pDate.getMonth() === targetDate.getMonth();
            });

            if (existingPeriod) {
                console.log(`   found existing period: ${existingPeriod.id} (${existingPeriod.status}). Re-opening...`);
                payPeriod = existingPeriod;

                try {
                    // Walk back status: COMPLETED -> PROCESSING -> ACTIVE -> DRAFT
                    while (payPeriod.status !== 'DRAFT') {
                        let nextStatus = '';
                        if (payPeriod.status === 'COMPLETED') nextStatus = 'PROCESSING';
                        else if (payPeriod.status === 'PROCESSING') nextStatus = 'ACTIVE';
                        else if (payPeriod.status === 'ACTIVE') nextStatus = 'DRAFT';
                        else if (payPeriod.status === 'CLOSED') {
                            // CLOSED -> ? (Usually terminal, checking controller)
                            // Controller: [PayPeriodStatus.CLOSED]: []
                            // If CLOSED, we might be stuck unless we have force override.
                            // But let's try PROCESSING just in case implementation allows it or we made a mistake in reading.
                            // Attempt to force DRAFT or delete if Closed.
                            // For now, assume not closed.
                            console.log('   ⚠️ Period is CLOSED. Cannot re-open via API standard transitions.');
                            break;
                        }

                        if (nextStatus) {
                            console.log(`   🔄 Transitioning ${payPeriod.status} -> ${nextStatus}...`);
                            const res = await axios.patch(`${API_URL}/pay-periods/${payPeriod.id}`, {
                                status: nextStatus
                            }, { headers: authHeaders });
                            payPeriod = res.data;
                        } else {
                            break; // Should be DRAFT
                        }
                    }
                    console.log(`   ✅ Period is now ${payPeriod.status}`);

                } catch (updateErr) {
                    console.error(`   ❌ Failed to re-open period: ${updateErr.response?.data?.message || updateErr.message}`);
                }
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

            // Only proceed if we successfully got it to DRAFT (or it ends up Processing/Active which is okay for Calc)
            // But finalize needs Draft usually?
            // Actually Calculate can work on Active/Processing. Finalize pushes to Completed.
            let isCompleted = (payPeriod.status === 'COMPLETED' || payPeriod.status === 'CLOSED');



            if (isCompleted) {
                console.log('   ⏭️  Period already completed. Checking transactions/taxes...');
            } else {
                // B. Calculate Payroll
                console.log(`   💰 Calculating per worker...`);
                const draftItems = [];
                for (const worker of workers) {
                    await delay(200);
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
                        console.error(`      ❌ Calc failed for ${worker.name}: ${calcErr.message}`);
                    }
                }

                if (draftItems.length > 0) {
                    // C. Save Draft
                    console.log(`   📝 Saving ${draftItems.length} draft records...`);
                    await axios.post(`${API_URL}/payroll/draft`, {
                        payPeriodId: payPeriod.id,
                        payrollItems: draftItems
                    }, { headers: authHeaders });

                    // D. Finalize
                    console.log(`   🔒 Finalizing (Generating Payslips/Tax)...`);
                    try {
                        const finalizeRes = await axios.post(`${API_URL}/payroll/finalize/${payPeriod.id}`, {
                            skipPayout: true
                        }, { headers: authHeaders });

                        // Poll
                        console.log('   ⏳ Waiting for finalization job...');
                        let isFin = false;
                        let att = 0;
                        while (!isFin && att < 10) {
                            await delay(2000);
                            const checkRes = await axios.get(`${API_URL}/pay-periods`, { headers: authHeaders });
                            const cPeriod = (Array.isArray(checkRes.data.data) ? checkRes.data.data : checkRes.data)
                                .find(p => p.id === payPeriod.id);
                            if (cPeriod && cPeriod.status === 'COMPLETED') isFin = true;
                            else att++;
                        }
                    } catch (finErr) {
                        console.error(`   ❌ Finalize failed: ${finErr.message}`);
                    }
                }
            }

            // E. Create Manual Transactions (For everyone, even if previously completed)
            console.log(`   💳 Creating Transactions...`);
            try {
                const recordsRes = await axios.get(`${API_URL}/payroll/period-records/${payPeriod.id}`, { headers: authHeaders });
                const finalRecords = recordsRes.data;

                for (const record of finalRecords) {
                    try {
                        if (!record.netPay) continue;
                        // Check for duplicates? For now, we assume if it fails 400/409 it might exist, or we just push.
                        // But transactions table might not have unique constraint on payPeriod+worker.
                        // We'll just try to create. 

                        await axios.post(`${API_URL}/transactions`, {
                            userId: record.workerId,
                            type: 'SALARY_PAYMENT',
                            amount: parseFloat(record.netPay),
                            status: 'COMPLETED',
                            description: `Salary for ${periodData.name}`,
                            date: new Date().toISOString(),
                            payPeriodId: payPeriod.id,
                            workerId: record.workerId
                        }, { headers: authHeaders });
                        console.log(`      ✅ Txn created for ${record.worker?.name || record.workerId}`);
                    } catch (txErr) {
                        // Ignore duplicate errors if needed, or log
                        // console.error(`      ❌ Txn failed: ${txErr.message}`);
                    }
                }
            } catch (recErr) {
                console.error(`   ❌ Failed to fetch finalized records for txn: ${recErr.message}`);
            }

            // F. Handle Taxes (Complete/Pay)
            console.log(`   🏛️  Processing Taxes...`);
            try {
                // Get pending payments
                const taxesRes = await axios.get(`${API_URL}/tax-payments/pending`, { headers: authHeaders });
                const pendingTaxes = taxesRes.data;

                const pDate = new Date(periodData.startDate);
                const pMonth = pDate.getMonth() + 1;
                const pYear = pDate.getFullYear();

                const relevantTaxes = pendingTaxes.filter(t => t.paymentYear === pYear && t.paymentMonth === pMonth);

                if (relevantTaxes.length > 0) {
                    console.log(`      Found ${relevantTaxes.length} pending tax payments.`);
                    for (const tax of relevantTaxes) {
                        await axios.patch(`${API_URL}/tax-payments/${tax.id}/status`, {
                            status: 'PAID'
                        }, { headers: authHeaders });
                        console.log(`      ✅ Paid Tax: ${tax.taxType} (${tax.amount})`);
                    }
                } else {
                    console.log(`      ⚠️  No pending taxes found for this period.`);
                }

            } catch (taxErr) {
                console.error(`      ❌ Tax processing failed: ${taxErr.message}`);
            }

            console.log(`   ✨ Period ${periodData.name} done.`);

        } catch (error) {
            console.error(`❌ Error processing period ${periodData.name}:`, error.message);
        }
    }

    console.log('\n✅ Payroll seeding completed!');
}

seedPayrollData();
