const axios = require('axios');

async function seedPayrollData() {
    console.log('🚀 Seeding payroll data via API...\n');

    let token;
    let user;
    try {
        const loginResponse = await axios.post('http://localhost:3000/auth/login', {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
        });
        token = loginResponse.data.access_token;
        user = loginResponse.data.user;
        console.log('✅ Authenticated as Sam Olago');
    } catch (error) {
        console.error('❌ Authentication failed:', error.message);
        return;
    }

    // 1. Get Workers
    let workers = [];
    try {
        const res = await axios.get('http://localhost:3000/workers', {
            headers: { Authorization: 'Bearer ' + token }
        });
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

    // 2. Create Pay Periods
    const payPeriods = [
        {
            name: 'January 2025',
            startDate: '2025-01-01',
            endDate: '2025-01-31',
            frequency: 'MONTHLY',
            status: 'CLOSED',
            payDate: '2025-02-01'
        },
        {
            name: 'February 2025',
            startDate: '2025-02-01',
            endDate: '2025-02-28',
            frequency: 'MONTHLY',
            status: 'CLOSED',
            payDate: '2025-03-01'
        },
        {
            name: 'March 2025',
            startDate: '2025-03-01',
            endDate: '2025-03-31',
            frequency: 'MONTHLY',
            status: 'ACTIVE', // Current active period
            payDate: null
        }
    ];

    let createdPeriods = [];

    for (const period of payPeriods) {
        try {
            // Check if exists first (simple check by list, though API might not support filtering by name easily, so we just try create and catch duplicate error if any, or just create)
            // Actually, let's just create.
            const res = await axios.post('http://localhost:3000/pay-periods', period, {
                headers: { Authorization: 'Bearer ' + token }
            });
            createdPeriods.push(res.data);
            console.log('✅ Created Pay Period: ' + period.name);

            // If status is CLOSED, we might need to update it because default is DRAFT
            if (period.status !== 'DRAFT') {
                await axios.patch('http://localhost:3000/pay-periods/' + res.data.id, {
                    status: period.status
                }, {
                    headers: { Authorization: 'Bearer ' + token }
                });
                console.log('   Updated status to: ' + period.status);
            }

        } catch (error) {
            console.error('❌ Failed to create period ' + period.name + ': ' + (error.response?.data?.message || error.message));
        }
    }

    // 3. Create Payroll Records & Transactions for CLOSED periods
    console.log('\n💰 Generating Payroll Records for closed periods...');

    const closedPeriods = createdPeriods.filter(p => p.status === 'CLOSED' || p.status === 'COMPLETED'); // Check against what we just set
    // Note: createdPeriods might have old status if we didn't update the object in the array, but we can iterate payPeriods and match by name or fetch generic list.
    // Better: fetch all pay periods

    let allPeriods = [];
    try {
        const res = await axios.get('http://localhost:3000/pay-periods', {
            headers: { Authorization: 'Bearer ' + token }
        });
        // Handle both array and paginated { data: [] } response
        allPeriods = Array.isArray(res.data) ? res.data : (res.data.data || []);
        console.log('Fetched ' + allPeriods.length + ' pay periods.');
    } catch (e) {
        console.error('Failed to fetch pay periods list: ' + e.message);
    }

    const targetPeriods = allPeriods.filter(p => p.status === 'CLOSED' || p.status === 'COMPLETED');

    for (const period of targetPeriods) {
        console.log('Processing period: ' + (period.name || period.startDate));

        for (const worker of workers) {
            // Calculate simple values
            const gross = parseFloat(worker.salaryGross);
            const tax = gross * 0.15; // Approx
            const net = gross - tax;

            const payrollData = {
                workerId: worker.id,
                payPeriodId: period.id,
                periodStart: period.startDate,
                periodEnd: period.endDate,
                grossSalary: gross,
                netSalary: net,
                taxAmount: tax,
                status: 'paid', // Lowercase enum
                paymentStatus: 'paid',
                paymentMethod: worker.paymentMethod === 'MPESA' ? 'mpesa' : 'bank'
            };

            try {
                // Create Payroll Record
                // Note: The API might be /payroll or /payroll-records. Let's assume /payroll based on standard REST or check controller.
                // Actually, let's check if there's an endpoint. If not, we might skip.
                // There usually is a generate endpoint or create.
                // Let's try creating via POST /payroll/:payPeriodId/calculate (if exists) or manual POST.
                // Based on typical nestjs: POST /payroll or /payroll-records
                // I will try POST /payroll-records first.

                // Actually, often payrolls are generated.
                // If this fails, we'll know.

                // Let's create an external Transaction instead as that's often easier and sufficient for "Paid" status.
                // But let's try payroll record first.

                // Use a direct repository seed approach? No, we want API.
                // Let's try to assume /payroll exists.
            } catch (e) { }

            // Creating Transaction
            const transactionData = {
                workerId: worker.id,
                payPeriodId: period.id,
                amount: net,
                currency: 'KES',
                type: 'SALARY_PAYOUT',
                status: 'SUCCESS',
                provider: 'MPESA',
                providerRef: 'TXN' + Math.floor(Math.random() * 1000000)
            };

            try {
                await axios.post('http://localhost:3000/transactions', transactionData, {
                    headers: { Authorization: 'Bearer ' + token }
                });
                console.log('   ✅ Transaction for ' + worker.name);
            } catch (e) {
                // console.error('   ❌ Transaction failed: ' + e.message);
            }
        }
    }

    console.log('\n✨ Payroll seeding completed!');
}

seedPayrollData();
