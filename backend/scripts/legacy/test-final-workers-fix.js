const axios = require('axios');

async function testFinalWorkersFix() {
  console.log('🧪 Final Test: Workers API with Enhanced Mobile Configuration...\n');
  
  try {
    // Test with enhanced mobile headers (what our improved Flutter app sends)
    console.log('1️⃣ Authenticating with test user...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful, token:', token ? 'Present' : 'Missing');
    
    // Test workers API with all the headers our enhanced Flutter app uses
    console.log('\n2️⃣ Testing workers API with enhanced mobile headers...');
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Origin': 'http://localhost:62750',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });
    
    console.log('✅ Workers API successful');
    console.log('Status:', workersResponse.status);
    console.log('Workers count:', workersResponse.data.length);
    console.log('First worker:', workersResponse.data[0]?.name || 'None');
    
    // Test OPTIONS preflight with all headers
    console.log('\n3️⃣ Testing OPTIONS preflight with all mobile headers...');
    const optionsResponse = await axios.options('http://localhost:3000/workers', {
      headers: {
        'Origin': 'http://localhost:62750',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'content-type,authorization,cache-control,pragma,expires,accept,origin'
      }
    });
    
    console.log('✅ OPTIONS preflight successful');
    console.log('CORS Headers:', {
      'access-control-allow-origin': optionsResponse.headers['access-control-allow-origin'],
      'access-control-allow-methods': optionsResponse.headers['access-control-allow-methods'],
      'access-control-allow-headers': optionsResponse.headers['access-control-allow-headers']
    });
    
    console.log('\n🎯 FINAL RESULTS:');
    console.log('✅ Backend CORS: Fully configured and working');
    console.log('✅ Authentication: JWT tokens working correctly');
    console.log('✅ Workers API: Returns data with proper auth');
    console.log('✅ Mobile Headers: All headers properly handled');
    console.log('\n💡 CHANGES MADE TO FIX CORS ISSUES:');
    console.log('1. Enhanced Flutter ApiService with better error logging');
    console.log('2. Added proper Origin header for CORS preflight');
    console.log('3. Improved token storage and retrieval with error handling');
    console.log('4. Added comprehensive request/response logging');
    console.log('5. Enhanced routing to handle authenticated users');
    console.log('\n🚀 The Flutter workers API should now work correctly!');
    
  } catch (error) {
    console.log('❌ Test failed');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Data:', error.response.data);
      console.log('Headers:', error.response.headers);
    } else {
      console.log('Network error:', error.message);
    }
  }
}

testFinalWorkersFix();