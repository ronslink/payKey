const axios = require('axios');

// Test script to verify the Stripe subscription fix
async function testStripeSubscription() {
  console.log('🧪 Testing Stripe subscription endpoint after fix...\n');

  try {
    // First, get authentication token
    console.log('1. Getting authentication token...');
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'test@example.com',
      password: 'password123'
    });

    const token = loginResponse.data.accessToken;
    console.log('✅ Authentication successful\n');

    // Test different plan tiers
    const planTiers = ['BASIC', 'GOLD', 'PLATINUM'];
    
    for (const planTier of planTiers) {
      console.log(`2. Testing subscription for ${planTier} plan...`);
      
      try {
        const response = await axios.post(
          'http://localhost:3000/payments/unified/subscribe',
          {
            planId: planTier,
            paymentMethod: 'stripe'
          },
          {
            headers: {
              'Authorization': `Bearer ${token}`,
              'Content-Type': 'application/json'
            }
          }
        );

        console.log(`✅ ${planTier} plan: SUCCESS`);
        console.log(`   Checkout URL: ${response.data.checkoutUrl?.substring(0, 50)}...`);
        console.log('');
        
      } catch (error) {
        console.log(`❌ ${planTier} plan: FAILED`);
        console.log(`   Status: ${error.response?.status}`);
        console.log(`   Error: ${error.response?.data?.message || error.message}`);
        console.log('');
      }
    }

    // Test case sensitivity
    console.log('3. Testing case sensitivity...');
    try {
      const response = await axios.post(
        'http://localhost:3000/payments/unified/subscribe',
        {
          planId: 'basic', // lowercase
          paymentMethod: 'stripe'
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ Case insensitive: SUCCESS (basic -> BASIC)');
    } catch (error) {
      console.log('❌ Case insensitive: FAILED');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.message || error.message}`);
    }

    console.log('\n🎯 Test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response?.data) {
      console.error('Response data:', error.response.data);
    }
  }
}

// Run the test
testStripeSubscription();