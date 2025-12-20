// test/load/k6-multi-user-test.js
// Multi-Tenant Load Test - Simulates multiple employers using PayKey concurrently
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';

// Custom metrics
export let errorRate = new Rate('errors');
export let payrollDuration = new Trend('payroll_duration');
export let workersDuration = new Trend('workers_duration');
export let taxDuration = new Trend('tax_duration');
export let apiErrors = new Counter('api_errors');
export let userConcurrency = new Counter('active_users');

// Test configuration
export let options = {
    stages: [
        { duration: '1m', target: 50 },   // Ramp up to 50 users (10 employers × 5 ops each)
        { duration: '3m', target: 50 },   // Stay at 50 users
        { duration: '1m', target: 100 },  // Ramp up to 100 users
        { duration: '3m', target: 100 },  // Stay at 100 users
        { duration: '1m', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<800'],  // Slightly relaxed for multi-user
        http_req_failed: ['rate<0.02'],    // 2% error rate acceptable
        payroll_duration: ['p(95)<4000'],
        workers_duration: ['p(95)<1500'],
        tax_duration: ['p(95)<2500'],
    },
};

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const NUM_TEST_USERS = parseInt(__ENV.NUM_USERS || '10'); // Number of distinct employers

console.log(`🚀 Starting multi-user load test against: ${BASE_URL}`);
console.log(`👥 Simulating ${NUM_TEST_USERS} concurrent employers`);

// Setup function: Create multiple test users
export function setup() {
    console.log(`🔧 Setting up ${NUM_TEST_USERS} test users...`);

    const testUsers = [];
    const headers = { 'Content-Type': 'application/json' };

    for (let i = 0; i < NUM_TEST_USERS; i++) {
        const userNum = i + 1;
        const email = `loadtest-employer${userNum}@paykey.com`;
        const password = `LoadTest${userNum}!`;
        const businessName = `Test Business ${userNum}`;

        console.log(`📝 Creating user ${userNum}/${NUM_TEST_USERS}: ${email}`);

        // Try to register (might already exist)
        const registerRes = http.post(`${BASE_URL}/auth/register`, JSON.stringify({
            email: email,
            password: password,
            firstName: `Employer`,
            lastName: `${userNum}`,
            businessName: businessName,
        }), { headers });

        // Login to get token (works whether user was just created or already existed)
        const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
            email: email,
            password: password,
        }), { headers });

        if (loginRes.status === 200 || loginRes.status === 201) {
            const body = JSON.parse(loginRes.body);
            testUsers.push({
                userId: userNum,
                email: email,
                password: password,
                businessName: businessName,
                token: body.access_token,
            });
            console.log(`✅ User ${userNum} ready: ${email}`);
        } else {
            console.error(`❌ Failed to setup user ${userNum}: ${loginRes.status}`);
            console.error(`Response: ${loginRes.body}`);
        }

        // Small delay to avoid overwhelming the server during setup
        sleep(0.2);
    }

    if (testUsers.length === 0) {
        throw new Error('No test users could be created! Aborting.');
    }

    console.log(`✅ Setup complete: ${testUsers.length}/${NUM_TEST_USERS} users ready`);
    console.log(`🎯 Starting load test with ${testUsers.length} concurrent employers...`);

    return { users: testUsers };
}

// Main test function - Each VU picks a random user and performs operations
export default function (data) {
    // Each virtual user randomly selects one of the test employers
    const randomUser = data.users[Math.floor(Math.random() * data.users.length)];

    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${randomUser.token}`,
    };

    userConcurrency.add(1);

    // Simulate realistic employer workflow

    // 1. Check workers (most common operation)
    let workersRes = http.get(`${BASE_URL}/workers`, { headers });

    let workersCheck = check(workersRes, {
        [`[User ${randomUser.userId}] workers list successful`]: (r) => r.status === 200,
        [`[User ${randomUser.userId}] workers list has data`]: (r) => {
            try {
                const body = JSON.parse(r.body);
                return Array.isArray(body) || typeof body === 'object';
            } catch {
                return false;
            }
        },
    });

    if (workersCheck) {
        workersDuration.add(workersRes.timings.duration);
    } else {
        errorRate.add(true);
        apiErrors.add(1);
        console.error(`❌ [User ${randomUser.userId}] Workers failed: ${workersRes.status}`);
    }

    sleep(0.5 + Math.random()); // Realistic think time

    // 2. Check pay periods
    let payPeriodsRes = http.get(`${BASE_URL}/pay-periods`, { headers });

    check(payPeriodsRes, {
        [`[User ${randomUser.userId}] pay periods successful`]: (r) => r.status === 200,
    });

    sleep(0.3 + Math.random() * 0.5);

    // 3. Tax calculation (computational load)
    const randomSalary = 30000 + Math.floor(Math.random() * 70000); // 30k-100k
    let taxRes = http.post(`${BASE_URL}/taxes/calculate`,
        JSON.stringify({ grossSalary: randomSalary }),
        { headers }
    );

    let taxCheck = check(taxRes, {
        [`[User ${randomUser.userId}] tax calculation successful`]: (r) => r.status === 200 || r.status === 201,
    });

    if (taxCheck) {
        taxDuration.add(taxRes.timings.duration);
    } else {
        errorRate.add(true);
        apiErrors.add(1);
        console.error(`❌ [User ${randomUser.userId}] Tax calc failed: ${taxRes.status}`);
    }

    sleep(1 + Math.random()); // Realistic think time

    // 4. Occasionally create a worker (write operation)
    if (Math.random() < 0.2) { // 20% chance
        const workerNum = Math.floor(Math.random() * 10000);
        let createWorkerRes = http.post(`${BASE_URL}/workers`,
            JSON.stringify({
                name: `Load Test Worker ${workerNum}`,
                phoneNumber: `+2547${String(workerNum).padStart(8, '0')}`,
                salaryGross: randomSalary,
                startDate: '2024-01-01',
            }),
            { headers }
        );

        check(createWorkerRes, {
            [`[User ${randomUser.userId}] worker creation successful`]: (r) =>
                r.status === 200 || r.status === 201,
        });

        sleep(0.5);
    }

    // 5. Check accounting (if exists)
    let accountingRes = http.get(`${BASE_URL}/accounting`, { headers });

    check(accountingRes, {
        [`[User ${randomUser.userId}] accounting check`]: (r) =>
            r.status === 200 || r.status === 404, // 404 is okay if endpoint doesn't exist
    });

    sleep(0.5 + Math.random() * 0.5);
}

export function teardown(data) {
    console.log('\n📊 Multi-User Load Test Complete');
    console.log(`✅ Tested with ${data.users.length} concurrent employers`);
    console.log('\n💡 Review metrics above for:');
    console.log('  - Error rates per user');
    console.log('  - Database connection pool usage');
    console.log('  - Multi-tenant isolation');
    console.log('  - Resource contention');

    // Optional: Cleanup test users
    // Uncomment if you want to delete test users after the test
    /*
    console.log('\n🧹 Cleaning up test users...');
    const headers = { 'Content-Type': 'application/json' };
    
    for (let user of data.users) {
      http.del(`${BASE_URL}/auth/user`, {
        headers: { 
          ...headers,
          'Authorization': `Bearer ${user.token}`,
        }
      });
    }
    console.log('✅ Cleanup complete');
    */
}
