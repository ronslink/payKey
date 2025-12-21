const axios = require('axios');

console.log('🧪 Testing PayKey Login Fix...');

async function testLogin() {
  try {
    console.log('\n1️⃣ Testing login endpoint...');
    
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser'
    });

    console.log('✅ Login successful!');
    console.log('Status:', loginResponse.status);
    console.log('Response data:', JSON.stringify(loginResponse.data, null, 2));

    if (loginResponse.data.access_token) {
      console.log('\n2️⃣ Testing JWT token validation...');
      const token = loginResponse.data.access_token;
      
      // Test a protected endpoint
      const protectedResponse = await axios.get('http://localhost:3000/users/profile', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      console.log('✅ Protected endpoint access successful!');
      console.log('Profile data:', JSON.stringify(protectedResponse.data, null, 2));
      
    } else {
      console.log('⚠️ No access token in response');
    }

  } catch (error) {
    console.log('❌ Login failed:', error.response?.data || error.message);
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Headers:', error.response.headers);
      console.log('Full error data:', JSON.stringify(error.response.data, null, 2));
    }
    console.log('Full error:', error);
  }
}

// Test authentication
testLogin();
