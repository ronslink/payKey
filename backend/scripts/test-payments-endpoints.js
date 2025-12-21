const axios = require('axios');

async function testPaymentsEndpoints() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('\n💳 Testing subscriptions endpoint...');
    try {
      const subscriptionsResponse = await axios.get('http://localhost:3000/subscriptions/current', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      console.log('✅ Subscriptions endpoint working');
      console.log(`📊 Response: ${JSON.stringify(subscriptionsResponse.data, null, 2)}`);
    } catch (error) {
      console.log('❌ Subscriptions endpoint failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.message}`);
      if (error.response?.data) {
        console.log(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
      }
    }
    
    console.log('\n💰 Testing transactions endpoint...');
    try {
      const transactionsResponse = await axios.get('http://localhost:3000/transactions', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      console.log('✅ Transactions endpoint working');
      console.log(`📊 Response type: ${Array.isArray(transactionsResponse.data) ? 'Array' : typeof transactionsResponse.data}`);
      console.log(`📊 Response keys: ${typeof transactionsResponse.data === 'object' ? Object.keys(transactionsResponse.data).join(', ') : 'N/A'}`);
      console.log(`📊 Response data type: ${typeof transactionsResponse.data}`);
      console.log(`📊 Response data length: ${Array.isArray(transactionsResponse.data) ? transactionsResponse.data.length : 'N/A'}`);
      console.log('📊 Full response:', JSON.stringify(transactionsResponse.data, null, 2));
      if (Array.isArray(transactionsResponse.data) && transactionsResponse.data.length > 0) {
        console.log(`📋 Sample transaction:`, transactionsResponse.data[0]);
      }
    } catch (error) {
      console.log('❌ Transactions endpoint failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.message}`);
      if (error.response?.data) {
        console.log(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Login failed:', error.message);
  }
}

testPaymentsEndpoints();
