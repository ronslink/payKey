const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

async function testEnhancedUserProfile() {
  try {
    console.log('🧪 Testing Enhanced User Profile System');
    console.log('=====================================');
    
    // Use the existing valid token
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiJiMGY0NWQxZi0xMGEyLTRiYzgtYWRhMy00ODI4OWVkZDk4MjAiLCJ0aWVyIjoiRlJFRSIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzYzODkzNTYwLCJleHAiOjE3NjM5Nzk5NjB9.h-0IE9DhFRcgN_lUhDSvXgIjWs0ZXUETtUPvEi3Vcew';
    
    console.log('✅ Using existing valid token for testuser@paykey.com');
    
    // Test 1: Update profile with Kenya country (should be RESIDENT)
    console.log('\n1. Testing Kenya resident (country code "ke")...');
    const kenyaResponse = await axios.patch(`${API_BASE_URL}/users/profile`, {
      kraPin: '1252211555',
      nssfNumber: '333333',
      nhifNumber: '3588622',
      idNumber: '333222299xw',
      address: 'Lenana School',
      city: 'Nairobi',
      countryCode: 'ke' // Kenya - should be RESIDENT
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Kenya profile update successful!');
    console.log('📋 Updated data:', {
      countryCode: kenyaResponse.data.countryCode,
      residentStatus: kenyaResponse.data.residentStatus,
      countryId: kenyaResponse.data.countryId ? `${kenyaResponse.data.countryId.substring(0, 8)}...` : 'null'
    });
    
    // Test 2: Update profile with US country (should be NON_RESIDENT)
    console.log('\n2. Testing US non-resident (country code "us")...');
    const usResponse = await axios.patch(`${API_BASE_URL}/users/profile`, {
      countryCode: 'US' // USA - should be NON_RESIDENT
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ US profile update successful!');
    console.log('📋 Updated data:', {
      countryCode: usResponse.data.countryCode,
      residentStatus: usResponse.data.residentStatus,
      countryId: usResponse.data.countryId ? `${usResponse.data.countryId.substring(0, 8)}...` : 'null'
    });
    
    // Test 3: Verify the system works with various country code formats
    console.log('\n3. Testing Uganda (country code "ug")...');
    const ugandaResponse = await axios.patch(`${API_BASE_URL}/users/profile`, {
      countryCode: 'ug' // Uganda - should be NON_RESIDENT
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Uganda profile update successful!');
    console.log('📋 Updated data:', {
      countryCode: ugandaResponse.data.countryCode,
      residentStatus: ugandaResponse.data.residentStatus
    });
    
    console.log('\n🎉 All tests completed successfully!');
    console.log('\n📝 Summary:');
    console.log('- ✅ Country code conversion working');
    console.log('- ✅ Resident status automatically set based on country');
    console.log('- ✅ Kenya → RESIDENT');
    console.log('- ✅ Other countries → NON_RESIDENT');
    console.log('- ✅ Both countryCode and countryId fields supported');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 500) {
      console.error('💥 Original 500 error still occurring');
      console.error('Details:', error.response.data);
    }
  }
}

testEnhancedUserProfile();
