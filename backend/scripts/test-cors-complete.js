const axios = require('axios');

async function testCompleteCORS() {
  console.log('🧪 Testing CORS with cache-control header (like mobile app)...');
  
  try {
    // Test OPTIONS preflight request with cache-control header
    console.log('\n1️⃣ Testing OPTIONS preflight request with cache-control...');
    const optionsResponse = await axios.options('http://localhost:3000/workers', {
      headers: {
        'Origin': 'http://localhost:62750',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'content-type,authorization,cache-control,pragma',
        'Access-Control-Allow-Origin': '*'
      }
    });
    
    console.log('✅ OPTIONS request successful');
    console.log('Status:', optionsResponse.status);
    console.log('Headers:', {
      'Access-Control-Allow-Origin': optionsResponse.headers['access-control-allow-origin'],
      'Access-Control-Allow-Methods': optionsResponse.headers['access-control-allow-methods'],
      'Access-Control-Allow-Headers': optionsResponse.headers['access-control-allow-headers']
    });
    
    // Test actual GET request with cache-control header (like mobile app)
    console.log('\n2️⃣ Testing GET workers request with cache-control...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Origin': 'http://localhost:62750',
        'Authorization': `Bearer ${token}`,
        'Cache-Control': 'no-cache',
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Workers request successful');
    console.log('Status:', workersResponse.status);
    console.log('Response:', `Received ${workersResponse.data.length} workers`);
    
  } catch (error) {
    console.log('❌ CORS test failed');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
      console.log('Data:', error.response.data);
    } else {
      console.log('Network error:', error.message);
    }
  }
}

testCompleteCORS();
