const axios = require('axios');

async function testTransactions() {
  const JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiI1MWZkYWJhYS00ODliLTRjNTYtOWEzNS04YzYzZDM4MmQzNDEiLCJ0aWVyIjoiRlJFRSIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzY0MDI4Mzc4LCJleHAiOjE3NjQxMTQ3Nzh9.rof_1LFrJFX_tErtPBVFel3-6p5TzscHbNXMUKXPNW0";

  try {
    console.log('🧪 Testing Transactions Endpoint...');
    
    const response = await axios.get('http://localhost:3000/transactions', {
      headers: {
        'Authorization': `Bearer ${JWT_TOKEN}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Transactions endpoint working!');
    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ Transactions endpoint error:');
    console.error('Status:', error.response?.status);
    console.error('Message:', error.response?.data || error.message);
  }
}

testTransactions();