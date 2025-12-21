const axios = require('axios');

async function testTransactionsAPI() {
  try {
    console.log('🔄 Testing Transactions API...');
    
    // Step 1: Login to get JWT token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'password123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Login successful');
    console.log('Login response status:', loginResponse.status);
    
    const token = loginResponse.data.token;
    console.log('Token received:', token ? 'YES' : 'NO');
    
    // Step 2: Test transactions endpoint
    console.log('\n🔄 Testing /transactions endpoint...');
    const transactionsResponse = await axios.get('http://localhost:3000/transactions', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Transactions endpoint working');
    console.log('Transactions response status:', transactionsResponse.status);
    console.log('Transactions data:', JSON.stringify(transactionsResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

testTransactionsAPI();
