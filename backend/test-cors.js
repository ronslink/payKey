const axios = require('axios');

async function testCORS() {
  console.log('🧪 Testing CORS with mobile app simulation...');
  
  try {
    // Test OPTIONS preflight request (like mobile app does)
    console.log('\n1️⃣ Testing OPTIONS preflight request...');
    const optionsResponse = await axios.options('http://localhost:3000/auth/login', {
      headers: {
        'Origin': 'http://localhost:62750',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'content-type,authorization',
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
    
    // Test actual login request with CORS headers
    console.log('\n2️⃣ Testing POST login request with CORS...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    }, {
      headers: {
        'Origin': 'http://localhost:62750',
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Login request successful');
    console.log('Status:', loginResponse.status);
    console.log('Response:', loginResponse.data ? 'Login successful with token' : 'Login failed');
    
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

testCORS();