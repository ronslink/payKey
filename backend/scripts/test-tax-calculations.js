const axios = require('axios');

const API_BASE = 'http://localhost:3000';

// Login first
async function login() {
  try {
    const response = await axios.post(`${API_BASE}/auth/login`, {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    console.log('Login response:', JSON.stringify(response.data, null, 2));
    
    // Try different possible token field names
    const token = response.data.token || response.data.accessToken || response.data.access_token || response.data.jwt;
    
    if (!token) {
      throw new Error('No token found in response');
    }
    
    return token;
  } catch (error) {
    console.error('Login failed:', error.response?.data || error.message);
    throw error;
  }
}

// Test tax calculation
async function testTaxCalculation(token) {
  try {
    console.log('Testing tax calculation with KES 50,000 gross salary...');
    console.log('Token available:', token ? 'Yes' : 'No');
    
    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
    console.log('Headers:', JSON.stringify(headers, null, 2));
    
    const response = await axios.post(`${API_BASE}/taxes/calculate`, {
      grossSalary: 50000
    }, { headers });
    
    console.log('✅ Tax calculation successful!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
    return response.data;
  } catch (error) {
    console.error('❌ Tax calculation failed:', error.response?.data || error.message);
    console.error('Full error:', error.response || error);
    throw error;
  }
}

// Test tax configuration endpoints
async function testTaxConfigs(token) {
  try {
    console.log('\nTesting tax configuration endpoints...');
    
    // Get active tax configurations
    const configsResponse = await axios.get(`${API_BASE}/tax-config/active`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Active tax configurations retrieved!');
    console.log('Number of active configs:', configsResponse.data.length);
    configsResponse.data.forEach(config => {
      console.log(`- ${config.taxType}: ${config.configuration.description || config.configuration.name}`);
    });
    
    return configsResponse.data;
  } catch (error) {
    console.error('❌ Tax config retrieval failed:', error.response?.data || error.message);
    throw error;
  }
}

// Main test function
async function runTests() {
  try {
    console.log('🔍 Testing Tax Management Component\n');
    
    // Step 1: Login
    console.log('1. Authenticating...');
    const token = await login();
    console.log('✅ Login successful\n');
    
    // Step 2: Test tax calculations
    const taxResult = await testTaxCalculation(token);
    
    // Step 3: Test tax configurations
    const configs = await testTaxConfigs(token);
    
    // Step 4: Test with different salary amounts
    console.log('\nTesting with different salary amounts...');
    const testSalaries = [25000, 75000, 100000];
    
    for (const salary of testSalaries) {
      try {
        const response = await axios.post(`${API_BASE}/taxes/calculate`, {
          grossSalary: salary
        }, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`\nSalary: KES ${salary.toLocaleString()}`);
        console.log(`  PAYE: KES ${response.data.paye.toLocaleString()}`);
        console.log(`  NSSF: KES ${response.data.nssf.toLocaleString()}`);
        console.log(`  SHIF: KES ${response.data.nhif.toLocaleString()}`);
        console.log(`  Housing Levy: KES ${response.data.housingLevy.toLocaleString()}`);
        console.log(`  Total Deductions: KES ${response.data.totalDeductions.toLocaleString()}`);
        
      } catch (error) {
        console.error(`❌ Failed for salary ${salary}:`, error.response?.data || error.message);
      }
    }
    
    console.log('\n✅ All tax management tests completed!');
    
  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
    process.exit(1);
  }
}

runTests();
