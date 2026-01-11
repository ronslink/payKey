const axios = require('axios');

async function registerSam() {
    console.log('🚀 Registering Sam Olago locally...');
    try {
        const res = await axios.post('http://localhost:3000/auth/register', {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
            firstName: 'Sam',
            lastName: 'Olago',
            businessName: 'Sam Olago Enterprises'
        });
        console.log('✅ Registered successfully:', res.data);
    } catch (error) {
        if (error.response?.status === 409) {
            console.log('ℹ️  User already exists.');
        } else {
            console.error('❌ Registration failed:', error.response?.data?.message || error.message);
        }
    }
}

registerSam();
