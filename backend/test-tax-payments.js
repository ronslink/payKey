const axios = require('axios');

async function testTaxPayments() {
  try {
    // First login to get a fresh token
    console.log('Logging in...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'SecurePass123!'
    });
    
    const token = loginResponse.data.access_token;
    console.log('Login successful, token received');

    // Test Payment History endpoint
    console.log('\n🧪 Testing /tax-payments/history endpoint...');
    const historyResponse = await axios.get('http://localhost:3000/tax-payments/history', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Payment History endpoint working!');
    console.log('Status Code:', historyResponse.status);
    console.log('Cache Headers:', {
      'cache-control': historyResponse.headers['cache-control'],
      'pragma': historyResponse.headers['pragma'],
      'expires': historyResponse.headers['expires']
    });
    console.log('Response Data:', historyResponse.data);

    // Test Active Tax Config endpoint
    console.log('\n🧪 Testing /tax-config/active endpoint...');
    const taxConfigResponse = await axios.get('http://localhost:3000/tax-config/active', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Tax Config endpoint working!');
    console.log('Status Code:', taxConfigResponse.status);
    console.log('Response Data:', taxConfigResponse.data);

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
    }
  }
}

testTaxPayments();