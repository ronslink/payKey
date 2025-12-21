const axios = require('axios');

async function testWorkersCaching() {
  try {
    console.log('🔄 Testing Workers API with Caching Fix...');
    
    // Step 1: Login to get JWT token
    console.log('\n1️⃣ Logging in...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'password123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Login successful');
    const token = loginResponse.data.token;
    
    // Step 2: Test workers endpoint with cache prevention headers
    console.log('\n2️⃣ Testing /workers endpoint with cache prevention...');
    const workersResponse1 = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });

    console.log('✅ First request successful');
    console.log('Status:', workersResponse1.status);
    console.log('Cache-Control:', workersResponse1.headers['cache-control']);
    console.log('Workers count:', workersResponse1.data.length);
    
    // Step 3: Test second request to ensure no 304 response
    console.log('\n3️⃣ Testing second request to verify no 304...');
    const workersResponse2 = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });

    console.log('✅ Second request successful');
    console.log('Status:', workersResponse2.status);
    console.log('Workers count:', workersResponse2.data.length);
    
    // Verify no 304 response
    if (workersResponse1.status === 200 && workersResponse2.status === 200) {
      console.log('\n🎉 SUCCESS: No 304 responses detected!');
      console.log('✅ Workers are loading properly');
      console.log('✅ Caching issue resolved');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
      console.error('Headers:', JSON.stringify(error.response.headers, null, 2));
    }
  }
}

testWorkersCaching();
