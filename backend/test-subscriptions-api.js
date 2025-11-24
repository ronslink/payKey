const axios = require('axios');

async function testSubscriptionsAPI() {
  try {
    console.log('🔄 Testing Subscriptions API...');
    
    // Step 1: Login to get JWT token
    console.log('\n1️⃣ Logging in...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'SecurePass123!'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Login successful');
    const token = loginResponse.data.token;
    
    // Step 2: Test subscription plans endpoint
    console.log('\n2️⃣ Testing /subscriptions/plans endpoint...');
    const plansResponse = await axios.get('http://localhost:3000/subscriptions/plans', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('✅ Subscription plans endpoint working');
    console.log('Status:', plansResponse.status);
    console.log('Plans count:', plansResponse.data.length);
    console.log('Plans data:', JSON.stringify(plansResponse.data, null, 2));
    
    // Step 3: Test current subscription endpoint
    console.log('\n3️⃣ Testing /subscriptions/current endpoint...');
    const currentResponse = await axios.get('http://localhost:3000/subscriptions/current', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('✅ Current subscription endpoint working');
    console.log('Status:', currentResponse.status);
    console.log('Current subscription:', JSON.stringify(currentResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

testSubscriptionsAPI();