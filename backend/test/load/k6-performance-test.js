// test/load/k6-performance-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export let errorRate = new Rate('errors');

// Test configuration
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
    http_req_failed: ['rate<0.1'],    // Error rate must be below 10%
  },
};

const BASE_URL = 'http://localhost:3000';
const TEST_USER = {
  email: 'loadtest@paykey.com',
  password: 'password123',
};

export function setup() {
  // Login and get auth token
  const loginResponse = http.post(`${BASE_URL}/auth/login`, JSON.stringify(TEST_USER), {
    headers: { 'Content-Type': 'application/json' },
  });

  const loginCheck = check(loginResponse, {
    'login successful': (r) => r.status === 200,
  });

  if (!loginCheck) {
    throw new Error('Login failed - cannot proceed with load test');
  }

  const authToken = JSON.parse(loginResponse.body).access_token;

  return { authToken: authToken };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.authToken}`,
  };

  // Test 1: Payroll Calculation (Critical Path)
  let payrollResponse = http.post(`${BASE_URL}/payroll/calculate`, 
    JSON.stringify({ userId: 'loadtest-user-123' }), 
    { headers }
  );

  let payrollCheck = check(payrollResponse, {
    'payroll calculation successful': (r) => r.status === 200,
    'payroll calculation fast': (r) => r.timings.duration < 3000,
  });

  errorRate.add(!payrollCheck);

  sleep(1);

  // Test 2: Worker Management
  let workersResponse = http.get(`${BASE_URL}/workers`, { headers });

  let workersCheck = check(workersResponse, {
    'workers list successful': (r) => r.status === 200,
    'workers list fast': (r) => r.timings.duration < 1000,
  });

  errorRate.add(!workersCheck);

  sleep(0.5);

  // Test 3: Tax Calculation (High CPU)
  let taxResponse = http.post(`${BASE_URL}/taxes/calculate`, 
    JSON.stringify({ grossSalary: 50000 }), 
    { headers }
  );

  let taxCheck = check(taxResponse, {
    'tax calculation successful': (r) => r.status === 200,
    'tax calculation fast': (r) => r.timings.duration < 2000,
  });

  errorRate.add(!taxCheck);

  sleep(1);
}

export function teardown(data) {
  // Cleanup can be added here if needed
  console.log('Load test completed');
}