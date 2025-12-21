const axios = require('axios');

async function testLogin() {
  try {
    console.log('🔍 Testing login endpoint...');
    console.log('📍 URL: http://localhost:3000/auth/login');
    console.log('📧 Email: testuser@paykey.com');
    console.log('🔑 Password: testuser123\n');

    const response = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Login successful!');
    console.log('📦 Response status:', response.status);
    console.log('🎫 Access token:', response.data.access_token?.substring(0, 20) + '...');
    console.log('👤 User:', response.data.user);
  } catch (error) {
    console.error('❌ Login failed!');
    console.error('Status:', error.response?.status);
    console.error('Error message:', error.response?.data?.message || error.message);
    console.error('Full error:', error.response?.data);
  }
}

testLogin();
