const axios = require('axios');

async function testEnhancedPlansEndpoint() {
  try {
    // Login first
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');

    // Test enhanced plans endpoint
    const plansResponse = await axios.get('http://localhost:3000/subscriptions/plans', {
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('\n🎯 Testing enhanced /subscriptions/plans endpoint...');
    console.log('✅ Enhanced plans endpoint working');

    // Check current subscription section
    const currentSubscription = plansResponse.data.currentSubscription;
    if (currentSubscription) {
      console.log('\n📋 Current Subscription Section:');
      console.log(`- Status: ${currentSubscription.status}`);
      console.log(`- Amount: ${currentSubscription.amount} ${currentSubscription.currency}`);
      console.log(`- Plan Name: ${currentSubscription.planName}`);
      console.log(`- Next Billing: ${currentSubscription.nextBillingDate ? new Date(currentSubscription.nextBillingDate).toLocaleDateString() : 'N/A'}`);
    } else {
      console.log('\n📋 Current Subscription Section: No active subscription');
    }

    // Check plans array
    console.log('\n💰 Available Plans:');
    plansResponse.data.plans.forEach((plan, index) => {
      const isCurrentBadge = plan.isCurrent ? ' (CURRENT)' : '';
      console.log(`${index + 1}. ${plan.name} - $${plan.price_usd}${isCurrentBadge}`);
    });

    // Verify current plan is at the top
    if (currentSubscription) {
      const currentPlanInArray = plansResponse.data.plans[0];
      if (currentPlanInArray.isCurrent) {
        console.log('\n✅ Current plan correctly positioned at top');
      } else {
        console.log('\n❌ Current plan not at top position');
      }
    }

  } catch (error) {
    console.log('❌ Enhanced plans endpoint failed:');
    console.log(`   Status: ${error.response?.status}`);
    console.log(`   Error: ${error.message}`);
    if (error.response?.data) {
      console.log(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }
  }
}

testEnhancedPlansEndpoint();