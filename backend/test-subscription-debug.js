const axios = require('axios');

async function debugSubscriptionAPI() {
  console.log('🔍 Debugging Subscription API to identify type issues...\n');
  
  try {
    console.log('1️⃣ Authenticating...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful\n');
    
    // Test the exact endpoints Flutter app calls
    const endpoints = [
      { name: 'Plans', url: 'http://localhost:3000/subscriptions/plans' },
      { name: 'Current', url: 'http://localhost:3000/subscriptions/current' },
      { name: 'Payment History', url: 'http://localhost:3000/subscriptions/subscription-payment-history' }
    ];
    
    for (const endpoint of endpoints) {
      console.log(`2️⃣ Testing ${endpoint.name} API...`);
      console.log(`   URL: ${endpoint.url}`);
      
      try {
        const response = await axios.get(endpoint.url, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        
        console.log('   ✅ Request successful');
        console.log('   Response data type:', typeof response.data);
        console.log('   Response data:', JSON.stringify(response.data, null, 2));
        
        if (Array.isArray(response.data)) {
          console.log('   📊 Data is an Array with length:', response.data.length);
          console.log('   First item type:', typeof response.data[0]);
          if (response.data[0]) {
            console.log('   First item:', JSON.stringify(response.data[0], null, 2));
          }
        } else if (typeof response.data === 'object') {
          console.log('   📄 Data is an Object');
          console.log('   Keys:', Object.keys(response.data));
        } else {
          console.log('   ⚠️  Data is neither Array nor Object');
        }
        
      } catch (error) {
        console.log('   ❌ Request failed');
        if (error.response) {
          console.log('   Status:', error.response.status);
          console.log('   Data:', error.response.data);
        } else {
          console.log('   Error:', error.message);
        }
      }
      
      console.log(''); // Empty line for readability
    }
    
    console.log('🎯 DEBUG SUMMARY:');
    console.log('Check the response data types above to identify the exact source of "jsonmap vs list dynamic" error');
    
  } catch (error) {
    console.log('❌ Debug test failed:', error.message);
  }
}

debugSubscriptionAPI();