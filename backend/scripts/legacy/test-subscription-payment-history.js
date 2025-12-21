const axios = require('axios');

async function testSubscriptionPaymentHistory() {
  try {
    console.log('🔐 Logging in to get authentication token...');
    
    // First login to get token
    const loginResponse = await axios.post('http://localhost:3000/auth/login', {
      email: 'testuser@paykey.com',
      password: 'testuser123'
    });
    
    const token = loginResponse.data.access_token;
    console.log('✅ Login successful');
    
    console.log('\n💳 Testing subscription payment history...');
    try {
      const paymentsResponse = await axios.get('http://localhost:3000/subscriptions/payment-history', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Payment history endpoint working');
      console.log(`📊 Response structure:`);
      console.log(`- Data length: ${paymentsResponse.data.data.length}`);
      console.log(`- Total payments: ${paymentsResponse.data.pagination.total}`);
      console.log(`- Current page: ${paymentsResponse.data.pagination.page}`);
      console.log(`- Summary total paid: ${paymentsResponse.data.summary.totalPaid} ${paymentsResponse.data.summary.currency}`);
      
      console.log('\n📋 Sample payment records:');
      paymentsResponse.data.data.slice(0, 3).forEach((payment, index) => {
        console.log(`${index + 1}. ${payment.invoiceNumber} - ${payment.amount} ${payment.currency} - ${payment.status}`);
        console.log(`   Period: ${new Date(payment.periodStart).toLocaleDateString()} to ${new Date(payment.periodEnd).toLocaleDateString()}`);
        console.log(`   Method: ${payment.paymentMethod}`);
        if (payment.paidDate) {
          console.log(`   Paid: ${new Date(payment.paidDate).toLocaleDateString()}`);
        }
        console.log('');
      });
      
      // Test with filters
      console.log('🔍 Testing payment history with status filter...');
      const filteredResponse = await axios.get('http://localhost:3000/subscriptions/payment-history?status=COMPLETED', {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log(`✅ Filtered by COMPLETED status: ${filteredResponse.data.data.length} payments`);
      
    } catch (error) {
      console.log('❌ Payment history endpoint failed:');
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

testSubscriptionPaymentHistory();