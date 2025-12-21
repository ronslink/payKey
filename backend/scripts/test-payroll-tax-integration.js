const axios = require('axios');

const API_BASE = 'http://localhost:3000';

// Login first
async function login() {
  try {
    const response = await axios.post(`${API_BASE}/auth/login`, {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    console.log('✅ Login successful');
    return response.data.access_token;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    throw error;
  }
}

// Test payroll calculation with tax integration
async function testPayrollCalculation(token) {
  try {
    console.log('\n🔍 Testing Payroll Calculation with Modern Tax Service...\n');
    
    // First, check if we have workers to calculate payroll for
    const workersResponse = await axios.get(`${API_BASE}/workers`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    const workers = workersResponse.data;
    console.log(`Found ${workers.length} active workers`);
    
    if (workers.length === 0) {
      console.log('⚠️  No workers found. Creating a test worker first...');
      
      // Create a test worker
      const testWorker = {
        name: 'Test Payroll Worker',
        email: 'payroll.test@example.com',
        phoneNumber: '+254700000001',
        salaryGross: 50000,
        employmentType: 'FULL_TIME',
        jobTitle: 'Software Developer',
        nssfNumber: '123456789',
        nhifNumber: '987654321',
        kraPin: 'A123456789A'
      };
      
      const createWorkerResponse = await axios.post(`${API_BASE}/workers`, testWorker, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      console.log('✅ Test worker created:', createWorkerResponse.data.name);
      workers.push(createWorkerResponse.data);
    }
    
    // Calculate payroll for workers
    const workerIds = workers.map(w => w.id).slice(0, 2); // Test with up to 2 workers
    console.log(`\nCalculating payroll for ${workerIds.length} workers...`);
    
    const payrollResponse = await axios.post(`${API_BASE}/payroll/calculate`, {
      workerIds: workerIds
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('\n✅ Payroll calculation successful!');
    
    const payrollItems = payrollResponse.data.payrollItems || payrollResponse.data;
    
    payrollItems.forEach((item, index) => {
      console.log(`\n--- Worker ${index + 1} ---`);
      console.log(`Name: ${item.workerName}`);
      console.log(`Gross Salary: KES ${item.grossSalary?.toLocaleString()}`);
      console.log(`Tax Breakdown:`);
      console.log(`  PAYE: KES ${item.taxBreakdown?.paye?.toLocaleString()}`);
      console.log(`  NSSF: KES ${item.taxBreakdown?.nssf?.toLocaleString()}`);
      console.log(`  SHIF: KES ${item.taxBreakdown?.nhif?.toLocaleString()}`);
      console.log(`  Housing Levy: KES ${item.taxBreakdown?.housingLevy?.toLocaleString()}`);
      console.log(`  Total Deductions: KES ${item.taxBreakdown?.totalDeductions?.toLocaleString()}`);
      console.log(`Net Pay: KES ${item.netPay?.toLocaleString()}`);
    });
    
    // Test direct tax calculation for comparison
    console.log('\n🔍 Testing Direct Tax Calculation...');
    
    const testSalary = 50000;
    const taxResponse = await axios.post(`${API_BASE}/taxes/calculate`, {
      grossSalary: testSalary
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`\nDirect Tax Calculation for KES ${testSalary.toLocaleString()}:`);
    console.log(`  PAYE: KES ${taxResponse.data.paye?.toLocaleString()}`);
    console.log(`  NSSF: KES ${taxResponse.data.nssf?.toLocaleString()}`);
    console.log(`  SHIF: KES ${taxResponse.data.nhif?.toLocaleString()}`);
    console.log(`  Housing Levy: KES ${taxResponse.data.housingLevy?.toLocaleString()}`);
    console.log(`  Total Deductions: KES ${taxResponse.data.totalDeductions?.toLocaleString()}`);
    
    // Verify payroll vs direct calculation consistency
    const payrollTax = payrollItems[0]?.taxBreakdown;
    if (payrollTax && taxResponse.data) {
      console.log('\n🔍 Verifying Consistency...');
      console.log(`PAYE Match: ${Math.abs(payrollTax.paye - taxResponse.data.paye) < 1 ? '✅' : '❌'}`);
      console.log(`NSSF Match: ${Math.abs(payrollTax.nssf - taxResponse.data.nssf) < 1 ? '✅' : '❌'}`);
      console.log(`SHIF Match: ${Math.abs(payrollTax.nhif - taxResponse.data.nhif) < 1 ? '✅' : '❌'}`);
      console.log(`Housing Levy Match: ${Math.abs(payrollTax.housingLevy - taxResponse.data.housingLevy) < 1 ? '✅' : '❌'}`);
    }
    
    return {
      payrollItems,
      taxCalculation: taxResponse.data
    };
    
  } catch (error) {
    console.error('❌ Payroll calculation failed:', error.response?.data || error.message);
    throw error;
  }
}

// Main test function
async function runTests() {
  try {
    console.log('🧪 Testing Payroll-Tax Integration\n');
    
    // Step 1: Login
    const token = await login();
    
    // Step 2: Test payroll calculation with tax integration
    await testPayrollCalculation(token);
    
    console.log('\n✅ All payroll-tax integration tests completed!');
    
  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
    process.exit(1);
  }
}

runTests();
