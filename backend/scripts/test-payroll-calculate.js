const axios = require('axios');

async function testPayrollCalculate() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful\n');
    
    // Test 1: GET /payroll/calculate
    console.log('📊 Test 1: Testing GET /payroll/calculate...');
    try {
      const getResponse = await axios.get('http://localhost:3000/payroll/calculate', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ GET /payroll/calculate SUCCESS!');
      console.log(`   Found ${getResponse.data.payrollItems?.length || 0} workers`);
      console.log(`   Total Gross: KES ${getResponse.data.summary?.totalGross || 0}`);
      console.log(`   Total Deductions: KES ${getResponse.data.summary?.totalDeductions || 0}`);
      console.log(`   Total Net Pay: KES ${getResponse.data.summary?.totalNetPay || 0}`);
      
      if (getResponse.data.payrollItems?.length > 0) {
        const sample = getResponse.data.payrollItems[0];
        console.log('\n   Sample payroll item:');
        console.log(`   - Worker: ${sample.workerName}`);
        console.log(`   - Gross: KES ${sample.grossSalary}`);
        console.log(`   - PAYE: KES ${sample.taxBreakdown?.paye || 0}`);
        console.log(`   - NSSF: KES ${sample.taxBreakdown?.nssf || 0}`);
        console.log(`   - NHIF: KES ${sample.taxBreakdown?.nhif || 0}`);
        console.log(`   - Housing Levy: KES ${sample.taxBreakdown?.housingLevy || 0}`);
        console.log(`   - Net Pay: KES ${sample.netPay}`);
        if (sample.error) {
          console.log(`   ⚠️  Error: ${sample.error}`);
        }
      }
    } catch (error) {
      console.error('❌ GET /payroll/calculate FAILED');
      console.error(`   Status: ${error.response?.status}`);
      console.error(`   Message: ${error.response?.data?.message || error.message}`);
    }
    
    // Test 2: POST /payroll/calculate with specific workers
    console.log('\n📊 Test 2: Testing POST /payroll/calculate with worker IDs...');
    try {
      // First get list of workers
      const workersResponse = await axios.get('http://localhost:3000/workers', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      const workerIds = workersResponse.data.slice(0, 2).map(w => w.id);
      
      if (workerIds.length > 0) {
        const postResponse = await axios.post('http://localhost:3000/payroll/calculate', {
          workerIds
        }, {
          headers: { 
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log('✅ POST /payroll/calculate SUCCESS!');
        console.log(`   Calculated for ${postResponse.data.payrollItems?.length || 0} workers`);
        console.log(`   Total Net Pay: KES ${postResponse.data.summary?.totalNetPay || 0}`);
      } else {
        console.log('⚠️  No workers found to test with');
      }
    } catch (error) {
      console.error('❌ POST /payroll/calculate FAILED');
      console.error(`   Status: ${error.response?.status}`);
      console.error(`   Message: ${error.response?.data?.message || error.message}`);
    }
    
    console.log('\n🎉 All payroll/calculate endpoint tests completed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

testPayrollCalculate();
