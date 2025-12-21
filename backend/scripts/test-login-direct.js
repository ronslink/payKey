const axios = require('axios');

async function testLogin() {
  try {
    console.log('🔍 Testing login with testuser123...');
    
    const response = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    console.log('✅ Login successful!');
    console.log('Status:', response.status);
    console.log('Response:', response.data);
    
  } catch (error) {
    if (error.response) {
      console.log('❌ Login failed');
      console.log('Status:', error.response.status);
      console.log('Response:', error.response.data);
    } else {
      console.log('❌ Network error:', error.message);
    }
  }
}

testLogin();
