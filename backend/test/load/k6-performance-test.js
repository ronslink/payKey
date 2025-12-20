// test/load/k6-performance-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let payrollDuration = new Trend('payroll_duration');
export let workersDuration = new Trend('workers_duration');
export let taxDuration = new Trend('tax_duration');
export let apiErrors = new Counter('api_errors');

// Test configuration - Use environment variables for flexibility
export let options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete within 500ms
    http_req_failed: ['rate<0.01'],   // Error rate must be below 1%
    payroll_duration: ['p(95)<3000'], // Payroll under 3s
    workers_duration: ['p(95)<1000'], // Workers list under 1s
    tax_duration: ['p(95)<2000'],     // Tax calc under 2s
  },
};

// Configuration - Read from environment or use defaults
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TEST_USER = {
  email: __ENV.TEST_EMAIL || 'loadtest@paykey.com',
  password: __ENV.TEST_PASSWORD || 'LoadTest123!',
};

console.log(`🚀 Starting load test against: ${BASE_URL}`);

export function setup() {
  console.log(`🔐 Attempting login for user: ${TEST_USER.email}`);

  // Login and get auth token
  const loginResponse = http.post(`${BASE_URL}/auth/login`, JSON.stringify(TEST_USER), {
    headers: { 'Content-Type': 'application/json' },
  });

  const loginCheck = check(loginResponse, {
    'login successful': (r) => r.status === 200 || r.status === 201,
    'login response has body': (r) => r.body && r.body.length > 0,
  });

  if (!loginCheck) {
    console.error(`❌ Login failed with status: ${loginResponse.status}`);
    console.error(`Response: ${loginResponse.body}`);
    throw new Error(`Login failed - Status: ${loginResponse.status}. Please ensure test user exists and Docker backend is running.`);
  }

  const responseBody = JSON.parse(loginResponse.body);
  const authToken = responseBody.access_token;

  if (!authToken) {
    console.error(`❌ No access_token in response: ${loginResponse.body}`);
    throw new Error('Login response missing access_token');
  }

  console.log(`✅ Login successful - Token acquired`);
  return { authToken: authToken };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.authToken}`,
  };

  // Test 1: Worker Management (GET) - Most common operation
  let workersResponse = http.get(`${BASE_URL}/workers`, { headers });

  let workersCheck = check(workersResponse, {
    'workers list successful': (r) => r.status === 200,
    'workers list has data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) || typeof body === 'object';
      } catch {
        return false;
      }
    },
    'workers list fast': (r) => r.timings.duration < 1000,
  });

  if (workersCheck) {
    workersDuration.add(workersResponse.timings.duration);
  } else {
    errorRate.add(true);
    apiErrors.add(1);
    console.error(`❌ Workers endpoint failed: ${workersResponse.status} - ${workersResponse.body.substring(0, 100)}`);
  }

  sleep(0.5);

  // Test 2: Tax Calculation (High CPU) - Critical business logic
  let taxResponse = http.post(`${BASE_URL}/taxes/calculate`,
    JSON.stringify({ grossSalary: 50000 }),
    { headers }
  );

  let taxCheck = check(taxResponse, {
    'tax calculation successful': (r) => r.status === 200 || r.status === 201,
    'tax calculation has result': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.paye !== undefined || body.tax !== undefined;
      } catch {
        return false;
      }
    },
    'tax calculation fast': (r) => r.timings.duration < 2000,
  });

  if (taxCheck) {
    taxDuration.add(taxResponse.timings.duration);
  } else {
    errorRate.add(true);
    apiErrors.add(1);
    console.error(`❌ Tax calculation failed: ${taxResponse.status}`);
  }

  sleep(1);

  // Test 3: Pay Periods List - Common payroll operation
  let payPeriodsResponse = http.get(`${BASE_URL}/pay-periods`, { headers });

  let payPeriodsCheck = check(payPeriodsResponse, {
    'pay periods list successful': (r) => r.status === 200,
    'pay periods list fast': (r) => r.timings.duration < 1000,
  });

  if (!payPeriodsCheck) {
    errorRate.add(true);
    apiErrors.add(1);
  }

  sleep(0.5);
}

export function teardown(data) {
  // Cleanup can be added here if needed
  console.log('Load test completed');
}