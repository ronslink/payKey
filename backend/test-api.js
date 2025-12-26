const axios = require('axios');

async function testEndpoints() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await axios.post('http://localhost:3000/auth/login', {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!'
        });
        const token = loginRes.data.access_token;
        const userId = loginRes.data.user.id;
        console.log('Login successful. Token obtained.');

        const headers = { Authorization: `Bearer ${token}` };

        // 1.5 Check Swagger JSON
        console.log('\nChecking Swagger JSON...');
        try {
            const swaggerRes = await axios.get('http://localhost:3000/api-json');
            const paths = Object.keys(swaggerRes.data.paths);
            const hasProperties = paths.some(p => p.startsWith('/properties'));
            console.log('Swagger has /properties:', hasProperties);
            if (hasProperties) {
                console.log('Properties routes found:', paths.filter(p => p.startsWith('/properties')));
            }
        } catch (err) {
            console.error('Swagger Error:', err.message);
        }

        // 2. Test Properties
        console.log('\nTesting /properties...');
        try {
            const propsRes = await axios.get('http://localhost:3000/properties', { headers });
            console.log('Properties Status:', propsRes.status);
            console.log('Properties Data:', propsRes.data);
        } catch (err) {
            console.error('Properties Error:', err.response?.status, err.response?.data);
        }

        // 3. Get a worker ID to test leave balance
        console.log('\nFetching workers...');
        const workersRes = await axios.get('http://localhost:3000/workers', { headers });
        const workers = workersRes.data;
        if (workers.length > 0) {
            const workerId = workers[0].id;
            console.log(`Testing leave balance for worker ${workerId}...`);

            try {
                const balanceRes = await axios.get(`http://localhost:3000/workers/${workerId}/leave-balance`, { headers });
                console.log('Leave Balance Status:', balanceRes.status);
                console.log('Leave Balance Data:', balanceRes.data);
            } catch (err) {
                console.error('Leave Balance Error:', err.response?.status, err.response?.data);
            }
        } else {
            console.log('No workers found to test leave balance.');
        }

    } catch (err) {
        console.error('Login Failed:', err.response?.status, err.response?.data);
    }
}

testEndpoints();
