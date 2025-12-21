const axios = require('axios');

async function testEnhancedCurrentSubscription() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('\n🎯 Testing enhanced /subscriptions/current endpoint...');
    try {
      const currentResponse = await axios.get('http://localhost:3000/subscriptions/current', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Enhanced current subscription endpoint working');
      console.log('\n📋 Response Structure:');
      console.log(`- Subscription ID: ${currentResponse.data.id}`);
      console.log(`- Tier: ${currentResponse.data.tier}`);
      console.log(`- Status: ${currentResponse.data.status}`);
      console.log(`- Amount: ${currentResponse.data.amount} ${currentResponse.data.currency}`);
      console.log(`- Plan Name: ${currentResponse.data.planName}`);
      
      console.log('\n💳 Payment History Section:');
      console.log(`- Recent payments count: ${currentResponse.data.paymentHistory?.length || 0}`);
      if (currentResponse.data.paymentHistory && currentResponse.data.paymentHistory.length > 0) {
        console.log('- Recent payment samples:');
        currentResponse.data.paymentHistory.slice(0, 3).forEach((payment, index) => {
          console.log(`  ${index + 1}. ${payment.invoiceNumber} - ${payment.amount} ${payment.currency} - ${payment.status}`);
        });
      }
      
      console.log('\n📊 Payment Summary:');
      const summary = currentResponse.data.paymentSummary;
      console.log(`- Total paid: ${summary.totalPaid} ${summary.currency}`);
      console.log(`- Payment count: ${summary.paymentCount}`);
      console.log(`- Last payment date: ${summary.lastPayment ? new Date(summary.lastPayment.paidDate).toLocaleDateString() : 'None'}`);
      
      console.log('\n🔍 Verification - comparing with dedicated payment history endpoint...');
      
      // Test the separate payment history endpoint for comparison
      const paymentHistoryResponse = await axios.get('http://localhost:3000/subscriptions/subscription-payment-history?limit=5', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Payment history endpoint working');
      console.log(`- Total historical payments: ${paymentHistoryResponse.data.pagination.total}`);
      console.log(`- Payments in current response: ${currentResponse.data.paymentHistory?.length || 0}`);
      
      // Compare payment data integrity
      const embeddedPayments = currentResponse.data.paymentHistory || [];
      const historicalPayments = paymentHistoryResponse.data.data || [];
      
      if (embeddedPayments.length > 0 && historicalPayments.length > 0) {
        const firstEmbedded = embeddedPayments[0];
        const firstHistorical = historicalPayments[0];
        
        console.log('\n🔎 Data Integrity Check:');
        console.log(`- First embedded payment ID: ${firstEmbedded.id}`);
        console.log(`- First historical payment ID: ${firstHistorical.id}`);
        console.log(`- Amount match: ${firstEmbedded.amount === firstHistorical.amount ? '✅' : '❌'}`);
        console.log(`- Status match: ${firstEmbedded.status === firstHistorical.status ? '✅' : '❌'}`);
        console.log(`- Invoice match: ${firstEmbedded.invoiceNumber === firstHistorical.invoiceNumber ? '✅' : '❌'}`);
      }
      
    } catch (error) {
      console.log('❌ Enhanced current subscription endpoint failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.message}`);
      if (error.response?.data) {
        console.log(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Login failed:', error.message);
  }
}

testEnhancedCurrentSubscription();
