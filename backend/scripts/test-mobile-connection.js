const axios = require('axios');

async function testConnection() {
  const urls = [
    'http://localhost:3000/auth/login',
    'http://10.0.2.2:3000/auth/login',
    'http://127.0.0.1:3000/auth/login',
    'http://0.0.0.0:3000/auth/login',
  ];

  for (const url of urls) {
    try {
      console.log(`\n🔍 Testing: ${url}`);
      const response = await axios.post(url, {
        email: 'testuser@paykey.com',
        password: 'testuser123'
      }, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 5000
      });
      console.log(`✅ SUCCESS - Status: ${response.status}`);
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        console.log(`❌ FAILED - Connection refused`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`❌ FAILED - Timeout`);
      } else {
        console.log(`❌ FAILED - ${error.message}`);
      }
    }
  }
  
  console.log('\n📝 Note: For Android Emulator, use http://10.0.2.2:3000');
  console.log('📝 Note: For iOS Simulator, use http://localhost:3000');
  console.log('📝 Note: For physical device, use http://<YOUR_LOCAL_IP>:3000');
}

testConnection();
