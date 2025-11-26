const axios = require('axios');

async function testTimeTracking() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('🔍 Getting a worker ID to test with...');
    
    // Get workers to get a valid worker ID
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (workersResponse.data.length === 0) {
      console.log('❌ No workers found - cannot test time tracking');
      return;
    }
    
    const workerId = workersResponse.data[0].id;
    console.log(`📋 Using worker: ${workersResponse.data[0].name} (${workerId})`);
    
    console.log('⏰ Testing time tracking active endpoint...');
    
    // Test the time tracking active endpoint that was failing
    const timeTrackingResponse = await axios.get(`http://localhost:3000/time-tracking/active?workerId=${workerId}`, {
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('🎉 SUCCESS! Time tracking endpoint is working');
    console.log(`📊 Response: ${JSON.stringify(timeTrackingResponse.data, null, 2)}`);
    
  } catch (error) {
    console.error('❌ Error testing time tracking:', error.message);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

testTimeTracking();