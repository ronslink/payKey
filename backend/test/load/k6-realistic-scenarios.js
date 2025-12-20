// test/load/k6-realistic-scenarios.js
// Realistic Business Scenario Testing - Multiple employers running payroll simultaneously
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let payrollProcessingTime = new Trend('payroll_processing_time');
export let payrollSuccessRate = new Rate('payroll_success');
export let workerCreationTime = new Trend('worker_creation_time');
export let concurrentPayrolls = new Counter('concurrent_payrolls');

// Test configuration - Peak usage scenario (end of month)
export let options = {
    scenarios: {
        // Scenario 1: Multiple employers processing monthly payroll
        monthly_payroll_rush: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '2m', target: 20 },  // 20 employers start payroll
                { duration: '5m', target: 20 },  // They all process simultaneously
                { duration: '1m', target: 0 },   // Complete
            ],
            exec: 'payrollProcessing',
        },

        // Scenario 2: Continuous worker management (background activity)
        worker_management: {
            executor: 'constant-vus',
            vus: 10,
            duration: '8m',
            exec: 'workerManagement',
            startTime: '0s',
        },

        // Scenario 3: Tax filing spike (quarterly deadline)
        tax_filing_deadline: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '1m', target: 30 },  // Sudden spike
                { duration: '2m', target: 30 },  // Sustained load
                { duration: '1m', target: 0 },   // Drop off
            ],
            exec: 'taxFiling',
            startTime: '2m', // Start after payroll begins
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<1500'],       // More relaxed for complex operations
        http_req_failed: ['rate<0.05'],           // 5% error rate max
        payroll_processing_time: ['p(95)<10000'], // Payroll can take up to 10s
        payroll_success_rate: ['rate>0.95'],      // 95% payroll success
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const NUM_TEST_USERS = 30; // 30 different employers

// Global test data
let testUsers = [];

export function setup() {
    console.log(`🏢 Setting up ${NUM_TEST_USERS} test employers for realistic scenario testing...`);

    const headers = { 'Content-Type': 'application/json' };
    const users = [];

    for (let i = 0; i < NUM_TEST_USERS; i++) {
        const userNum = i + 1;
        const email = `scenario-employer${userNum}@paykey.com`;
        const password = `Scenario${userNum}!`;

        // Register
        http.post(`${BASE_URL}/auth/register`, JSON.stringify({
            email: email,
            password: password,
            firstName: `Business`,
            lastName: `Owner ${userNum}`,
            businessName: `Scenario Test Business ${userNum}`,
        }), { headers });

        // Login
        const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
            email: email,
            password: password,
        }), { headers });

        if (loginRes.status === 200 || loginRes.status === 201) {
            const body = JSON.parse(loginRes.body);
            users.push({
                id: userNum,
                email: email,
                token: body.access_token,
                workers: [], // Track workers created for this user
            });

            // Create 3-5 workers for each employer
            const workerCount = 3 + Math.floor(Math.random() * 3);
            for (let w = 0; w < workerCount; w++) {
                const workerRes = http.post(`${BASE_URL}/workers`,
                    JSON.stringify({
                        name: `Worker ${w + 1} for Employer ${userNum}`,
                        phoneNumber: `+2547${String(userNum * 100 + w).padStart(8, '0')}`,
                        salaryGross: 30000 + Math.floor(Math.random() * 50000),
                        startDate: '2024-01-01',
                    }),
                    { headers: { ...headers, 'Authorization': `Bearer ${body.access_token}` } }
                );

                if (workerRes.status === 200 || workerRes.status === 201) {
                    users[users.length - 1].workers.push(JSON.parse(workerRes.body));
                }
            }

            console.log(`✅ Employer ${userNum} setup with ${workerCount} workers`);
        }

        sleep(0.1);
    }

    console.log(`✅ Setup complete: ${users.length} employers with workers ready`);
    return { users: users };
}

// Scenario 1: Payroll Processing (most resource-intensive)
export function payrollProcessing(data) {
    const user = data.users[__VU % data.users.length];
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${user.token}`,
    };

    group('Monthly Payroll Processing', function () {
        concurrentPayrolls.add(1);
        const startTime = Date.now();

        // Step 1: Create pay period
        let payPeriodRes = http.post(`${BASE_URL}/pay-periods`,
            JSON.stringify({
                frequency: 'MONTHLY',
                startDate: '2024-12-01',
                endDate: '2024-12-31',
            }),
            { headers }
        );

        let payPeriodId = null;
        if (payPeriodRes.status === 200 || payPeriodRes.status === 201) {
            try {
                const body = JSON.parse(payPeriodRes.body);
                payPeriodId = body.id || body.payPeriodId;
            } catch (e) {
                // If creation fails, try to get existing pay periods
                const periodsRes = http.get(`${BASE_URL}/pay-periods`, { headers });
                if (periodsRes.status === 200) {
                    const periods = JSON.parse(periodsRes.body);
                    if (Array.isArray(periods) && periods.length > 0) {
                        payPeriodId = periods[0].id;
                    }
                }
            }
        }

        sleep(0.5);

        // Step 2: Calculate payroll
        if (payPeriodId) {
            let calculateRes = http.post(`${BASE_URL}/pay-periods/${payPeriodId}/calculate`,
                null,
                { headers }
            );

            check(calculateRes, {
                [`[Employer ${user.id}] payroll calculated`]: (r) =>
                    r.status === 200 || r.status === 201,
            });

            sleep(1);

            // Step 3: Review statistics
            let statsRes = http.get(`${BASE_URL}/pay-periods/${payPeriodId}/statistics`, { headers });

            check(statsRes, {
                [`[Employer ${user.id}] stats retrieved`]: (r) => r.status === 200,
            });

            sleep(0.5);

            // Step 4: Process payroll
            let processRes = http.post(`${BASE_URL}/pay-periods/${payPeriodId}/process`,
                null,
                { headers }
            );

            const success = check(processRes, {
                [`[Employer ${user.id}] payroll processed`]: (r) =>
                    r.status === 200 || r.status === 201,
            });

            payrollSuccessRate.add(success);

            const totalTime = Date.now() - startTime;
            payrollProcessingTime.add(totalTime);

            if (!success) {
                errorRate.add(true);
                console.error(`❌ [Employer ${user.id}] Payroll failed at processing step`);
            }
        } else {
            errorRate.add(true);
            console.error(`❌ [Employer ${user.id}] No pay period ID obtained`);
        }
    });

    sleep(2);
}

// Scenario 2: Worker Management (background operations)
export function workerManagement(data) {
    const user = data.users[__VU % data.users.length];
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${user.token}`,
    };

    group('Worker Management', function () {
        // List workers
        let workersRes = http.get(`${BASE_URL}/workers`, { headers });
        check(workersRes, {
            [`[Employer ${user.id}] workers listed`]: (r) => r.status === 200,
        });

        sleep(1 + Math.random());

        // 30% chance to add a new worker
        if (Math.random() < 0.3) {
            const startTime = Date.now();
            const workerNum = Math.floor(Math.random() * 100000);

            let createRes = http.post(`${BASE_URL}/workers`,
                JSON.stringify({
                    name: `New Worker ${workerNum}`,
                    phoneNumber: `+2547${String(workerNum).padStart(8, '0')}`,
                    salaryGross: 30000 + Math.floor(Math.random() * 70000),
                    startDate: new Date().toISOString().split('T')[0],
                }),
                { headers }
            );

            check(createRes, {
                [`[Employer ${user.id}] worker created`]: (r) =>
                    r.status === 200 || r.status === 201,
            });

            workerCreationTime.add(Date.now() - startTime);
        }

        // 10% chance to update worker
        if (Math.random() < 0.1 && user.workers.length > 0) {
            const randomWorker = user.workers[Math.floor(Math.random() * user.workers.length)];
            if (randomWorker && randomWorker.id) {
                http.patch(`${BASE_URL}/workers/${randomWorker.id}`,
                    JSON.stringify({
                        salaryGross: 35000 + Math.floor(Math.random() * 60000),
                    }),
                    { headers }
                );
            }
        }
    });

    sleep(2 + Math.random() * 2);
}

// Scenario 3: Tax Filing (deadline rush)
export function taxFiling(data) {
    const user = data.users[__VU % data.users.length];
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${user.token}`,
    };

    group('Tax Filing', function () {
        // Get tax submissions
        let submissionsRes = http.get(`${BASE_URL}/taxes/submissions`, { headers });
        check(submissionsRes, {
            [`[Employer ${user.id}] tax submissions retrieved`]: (r) =>
                r.status === 200 || r.status === 404, // 404 OK if none exist
        });

        sleep(0.5);

        // Calculate taxes for multiple workers
        for (let i = 0; i < 3; i++) {
            const salary = 30000 + Math.floor(Math.random() * 70000);
            let taxRes = http.post(`${BASE_URL}/taxes/calculate`,
                JSON.stringify({ grossSalary: salary }),
                { headers }
            );

            check(taxRes, {
                [`[Employer ${user.id}] tax calculated for ${salary}`]: (r) =>
                    r.status === 200 || r.status === 201,
            });

            sleep(0.3);
        }

        // Submit tax return (if endpoint exists)
        let submitRes = http.post(`${BASE_URL}/taxes/submit`,
            JSON.stringify({
                period: '2024-12',
                type: 'PAYE',
            }),
            { headers }
        );

        check(submitRes, {
            [`[Employer ${user.id}] tax submission attempted`]: (r) =>
                r.status === 200 || r.status === 201 || r.status === 404,
        });
    });

    sleep(1 + Math.random());
}

export function teardown(data) {
    console.log('\n📊 Realistic Scenario Testing Complete');
    console.log(`\n🏢 Tested ${data.users.length} employers with realistic workflows:`);
    console.log(`   - Monthly payroll processing rush`);
    console.log(`   - Continuous worker management`);
    console.log(`   - Tax filing deadline spike`);
    console.log('\n💡 Key insights to review:');
    console.log('   - Database connection pool saturation');
    console.log('   - Payroll processing latency under load');
    console.log('   - Multi-tenant data isolation');
    console.log('   - Transaction deadlocks or conflicts');
}
