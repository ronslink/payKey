const axios = require('axios');

async function testWorkers() {
  try {
    // First login to get a fresh token
    console.log('Logging in...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'SecurePass123!'
    });
    
    const token = loginResponse.data.access_token;
    console.log('Login successful, token received');
    
    // Now test the workers endpoint
    console.log('\nTesting workers endpoint...');
    const response = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Workers endpoint working!');
    console.log('Status Code:', response.status);
    console.log('Cache Headers:', {
      'cache-control': response.headers['cache-control'],
      'pragma': response.headers['pragma'],
      'expires': response.headers['expires']
    });
    console.log('Response Data Length:', Array.isArray(response.data) ? response.data.length : 'Not an array');
    
    if (Array.isArray(response.data) && response.data.length > 0) {
      console.log('Sample Worker:', response.data[0]);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
    }
  }
}

testWorkers();
