const axios = require('axios');

async function testWorkersEndpoint() {
  try {
    const response = await axios.get('http://localhost:3000/workers', {
      headers: {
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3R1c2VyQHBheWtleS5jb20iLCJzdWIiOiI1YjRjZTM3OC00ODFhLTQzOGYtOTgwNC0zMzU3OTY3ZWVhMjkiLCJuYW1lIjoidGVzdCB1c2VyIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJyb2xlcyI6W10sImlhdCI6MTczNTQ4OTkwNiwiZXhwIjoxNzM1NDkzNTA2fQ.OyD7e2H5T9z8lLw0K8wWnJfJqKxJ2pH1l8u4vA5Zfk'
      }
    });
    
    console.log('Status Code:', response.status);
    console.log('Headers:', response.headers);
    console.log('Response Data:', response.data);
  } catch (error) {
    if (error.response) {
      console.log('Error Status:', error.response.status);
      console.log('Error Headers:', error.response.headers);
      console.log('Error Data:', error.response.data);
    } else {
      console.log('Error:', error.message);
    }
  }
}

testWorkersEndpoint();