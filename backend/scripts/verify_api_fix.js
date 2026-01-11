/**
 * Verify Pay Period API returns ALL periods for 2025 (checking for CLOSED status)
 */
const axios = require('axios');

async function check() {
    try {
        console.log('Authenticating...');
        const login = await axios.post('https://api.paydome.co/auth/login', {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!'
        });
        const token = login.data.access_token;
        console.log('Logged in.');

        console.log('Fetching pay periods with status=COMPLETED (Verification Target)...');
        const res = await axios.get('https://api.paydome.co/pay-periods?status=COMPLETED', {
            headers: { Authorization: 'Bearer ' + token }
        });

        console.log(`\nFound ${res.data.data.length} periods:`);
        res.data.data.forEach(p => console.log(` - ${p.name} (Status: ${p.status})`));

    } catch (e) {
        console.error('Error:', e.message);
        if (e.response) {
            console.error('Response data:', e.response.data);
        }
    }
}

check();
