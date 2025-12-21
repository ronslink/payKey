const axios = require('axios');

async function testNewEndpoints() {
  const baseUrl = 'http://localhost:3000';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiJiMGY0NWQxZi0xMGEyLTRiYzgtYWRhMy00ODI4OWVkZDk4MjAiLCJ0aWVyIjoiRlJFRSIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzYzODkzNTYwLCJleHAiOjE3NjM5Nzk5NjB9.h-0IE9DhFRcgN_lUhDSvXgIjWs0ZXUETtUPvEi3Vcew';

  try {
    console.log('🧪 Testing /subscriptions/current endpoint...');
    const subscriptionResponse = await axios.get(`${baseUrl}/subscriptions/current`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    console.log('✅ Subscription endpoint working!');
    console.log('Status Code:', subscriptionResponse.status);
    console.log('Response:', subscriptionResponse.data);

    console.log('\n🧪 Testing /transactions endpoint...');
    const transactionsResponse = await axios.get(`${baseUrl}/transactions`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    console.log('✅ Transactions endpoint working!');
    console.log('Status Code:', transactionsResponse.status);
    console.log('Response:', transactionsResponse.data);

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    console.error('Status:', error.response?.status);
  }
}

testNewEndpoints();
