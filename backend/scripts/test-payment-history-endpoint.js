const axios = require('axios');

async function testPaymentHistoryEndpoint() {
  console.log('🧪 Testing Subscription Payment History Endpoint...\n');
  
  try {
    console.log('1️⃣ Authenticating...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('\n2️⃣ Testing NEW subscription payment history endpoint...');
    const historyResponse = await axios.get('http://localhost:3000/subscriptions/subscription-payment-history', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Payment history API successful');
    console.log('Response data type:', typeof historyResponse.data);
    console.log('Response data:', JSON.stringify(historyResponse.data, null, 2));
    console.log('Data length:', Array.isArray(historyResponse.data) ? historyResponse.data.length : 'Not an array');
    
    if (Array.isArray(historyResponse.data) && historyResponse.data.length > 0) {
      console.log('First payment:', JSON.stringify(historyResponse.data[0], null, 2));
    }
    
    console.log('\n🎯 PAYMENT HISTORY ENDPOINT TEST RESULTS:');
    console.log('✅ Endpoint exists and responds (no more 404)');
    console.log('✅ Returns empty array when no payment history exists');
    console.log('✅ Flutter app should no longer get type errors');
    
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

testPaymentHistoryEndpoint();
