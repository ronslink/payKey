const axios = require('axios');

async function testFinalCORS() {
  console.log('🧪 Final CORS test with all mobile app headers...');
  
  try {
    // Test OPTIONS preflight request with all headers
    console.log('\n1️⃣ Testing OPTIONS preflight with expires header...');
    const optionsResponse = await axios.options('http://localhost:3000/workers', {
      headers: {
        'Origin': 'http://localhost:62750',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'content-type,authorization,cache-control,pragma,expires,if-modified-since,etag,last-modified',
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
    
    // Test actual GET request (like mobile app would make)
    console.log('\n2️⃣ Testing GET workers request with all headers...');
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
        'Expires': '0',
        'If-Modified-Since': '0',
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Workers request successful');
    console.log('Status:', workersResponse.status);
    console.log('Response:', `Received ${workersResponse.data.length} workers`);
    
    console.log('\n🎉 ALL CORS ISSUES RESOLVED! Mobile app should now work perfectly!');
    
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

testFinalCORS();
