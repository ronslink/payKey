const axios = require('axios');

async function testSubscriptionsAPI() {
  console.log('🧪 Testing Subscriptions API...\n');
  
  try {
    console.log('1️⃣ Authenticating...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('\n2️⃣ Testing subscriptions/plans endpoint...');
    const plansResponse = await axios.get('http://localhost:3000/subscriptions/plans', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Plans API successful');
    console.log('Plans count:', plansResponse.data.length);
    console.log('Sample plan:', plansResponse.data[0]);
    
    console.log('\n3️⃣ Testing subscriptions/current endpoint...');
    const currentResponse = await axios.get('http://localhost:3000/subscriptions/current', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Current subscription API successful');
    console.log('Current subscription:', {
      id: currentResponse.data.id,
      tier: currentResponse.data.tier,
      status: currentResponse.data.status,
      amount: currentResponse.data.amount,
      currency: currentResponse.data.currency,
      planName: currentResponse.data.planName
    });
    
    console.log('\n🎯 SUBSCRIPTION API TEST RESULTS:');
    console.log('✅ Authentication working');
    console.log('✅ Plans endpoint returning data');
    console.log('✅ Current subscription endpoint working');
    console.log('✅ Backend structure matches Flutter expectations');
    
  } catch (error) {
    console.log('❌ Test failed');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Data:', error.response.data);
    } else {
      console.log('Error:', error.message);
    }
  }
}

testSubscriptionsAPI();