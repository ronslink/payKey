const axios = require('axios');

async function checkWorkers() {
  try {
    console.log('🔍 Checking demo user workers...');
    
    // Login first
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    // Get workers
    const workersResponse = await axios.get('http://localhost:3000/workers', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    console.log(`📊 Found ${workersResponse.data.length} workers for demo user`);
    
    if (workersResponse.data.length > 0) {
      console.log('👥 Workers list:');
      workersResponse.data.forEach((worker, index) => {
        console.log(`${index + 1}. ${worker.name} - ${worker.employmentType} - ${worker.jobTitle || 'N/A'}`);
      });
      console.log('✅ Demo employees already exist!');
    } else {
      console.log('❌ No workers found - need to seed demo employees');
    }
    
  } catch (error) {
    if (error.response) {
      console.log('❌ API Error:', error.response.status, error.response.data);
    } else {
      console.error('❌ Error:', error.message);
    }
  }
}

checkWorkers();
