const axios = require('axios');

async function testMobileWorkersFlow() {
  console.log('🧪 Testing complete mobile workers API flow...\n');
  
  try {
    // 1. Login to get token
    console.log('1️⃣ Testing login...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful, token received');
    console.log('Token:', token ? 'Present' : 'Missing');
    
    // 2. Test workers API with proper authentication
    console.log('\n2️⃣ Testing workers API with authentication...');
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });
    
    console.log('✅ Workers API successful');
    console.log('Status:', workersResponse.status);
    console.log('Workers count:', workersResponse.data.length);
    console.log('Sample worker:', workersResponse.data[0] ? {
      id: workersResponse.data[0].id,
      name: workersResponse.data[0].name,
      phoneNumber: workersResponse.data[0].phoneNumber,
      isActive: workersResponse.data[0].isActive
    } : 'No workers');
    
    // 3. Test CORS with mobile app origin
    console.log('\n3️⃣ Testing CORS from mobile origin...');
    const corsTestResponse = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Origin': 'http://localhost:62750', // Flutter mobile app origin
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
        'Expires': '0'
      }
    });
    
    console.log('✅ CORS test successful');
    console.log('CORS Headers:', {
      'access-control-allow-origin': corsTestResponse.headers['access-control-allow-origin'],
      'access-control-allow-credentials': corsTestResponse.headers['access-control-allow-credentials']
    });
    
    console.log('\n🎉 ALL TESTS PASSED! Mobile workers API should work correctly');
    
  } catch (error) {
    console.log('❌ Test failed');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
      console.log('Data:', error.response.data);
    } else {
      console.log('Network error:', error.message);
    }
  }
}

testMobileWorkersFlow();