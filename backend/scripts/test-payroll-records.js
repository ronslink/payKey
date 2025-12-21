const axios = require('axios');

async function testPayrollRecords() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('📊 Fetching payroll records...');
    
    // Now test the payroll records endpoint
    const payrollResponse = await axios.get('http://localhost:3000/payroll-records', {
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('🎉 SUCCESS! Payroll records endpoint is working');
    console.log(`📋 Found ${payrollResponse.data.length} payroll records`);
    
    if (payrollResponse.data.length > 0) {
      console.log('\n📄 Sample payroll record:');
      const sample = payrollResponse.data[0];
      console.log(`   ID: ${sample.id}`);
      console.log(`   Worker: ${sample.worker?.name || 'Unknown'}`);
      console.log(`   Period: ${sample.periodStart} to ${sample.periodEnd}`);
      console.log(`   Gross Salary: ${sample.grossSalary}`);
      console.log(`   Net Salary: ${sample.netSalary}`);
      console.log(`   Status: ${sample.status || 'draft'}`);
    }
    
  } catch (error) {
    console.error('❌ Error testing payroll records:', error.message);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

testPayrollRecords();
