const jwt = require('jsonwebtoken');

const secret = 'supersecretkey';

console.log('🧪 Testing JWT authentication...');

// Test token (from the earlier login)
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiJiMGY0NWQxZi0xMGEyLTRiYzgtYWRhMy00ODI4OWVkZDk4MjAiLCJ0aWVyIjoiRlJFRSIsInJvbGUiOiJVU0VSIiwiaWF0IjoxNzM0MTAxNzQ2LCJleHAiOjE3MzQxMDUzNDZ9.kINDzCHizhuInI';

try {
  const decoded = jwt.verify(token, secret);
  console.log('✅ JWT Token is valid!');
  console.log('Decoded payload:', decoded);
} catch (error) {
  console.log('❌ JWT Token validation failed!');
  console.log('Error:', error.message);
}