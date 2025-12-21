const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

async function testProfileUpdate() {
  try {
    console.log('Testing user profile update fix...');
    
    // Use the existing valid token
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiJiMGY0NWQxZi0xMGEyLTRiYzgtYWRhMy00ODI4OWVkZDk4MjAiLCJ0aWVyIjoiRlJFRSIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzYzODkzNTYwLCJleHAiOjE3NjM5Nzk5NjB9.h-0IE9DhFRcgN_lUhDSvXgIjWs0ZXUETtUPvEi3Vcew';
    console.log('✅ Using existing valid token for testuser@paykey.com');
    
    // Step 2: Update profile with country code (should convert to UUID)
    console.log('2. Updating profile with country code "ke"...');
    const profileResponse = await axios.patch(`${API_BASE_URL}/users/profile`, {
      kraPin: '1252211555',
      nssfNumber: '333333',
      nhifNumber: '3588622',
      idNumber: '333222299xw',
      address: 'Lenana Scholl',
      city: 'Nairobi , Nairobi',
      countryId: 'ke' // This should be converted from country code to UUID
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Profile update successful!');
    console.log('Updated user profile:', profileResponse.data);
    
    // Step 3: Verify the countryId was properly converted
    if (profileResponse.data.countryId && profileResponse.data.countryId !== 'ke') {
      console.log('✅ Country code "ke" was successfully converted to UUID:', profileResponse.data.countryId);
    } else {
      console.log('❌ Country code conversion may have failed');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 500) {
      console.error('The original error is still occurring - the fix may not be working properly');
      console.error('Original error details:', error.response.data);
    }
  }
}

testProfileUpdate();