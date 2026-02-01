const axios = require('axios');

const API_URL = 'http://localhost:3000';

async function updateWorkerSalaries() {
    try {
        console.log('🔍 Updating worker salaries for Test User...');

        // Login first
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'testuser123'
        });

        const token = loginResponse.data.access_token;
        console.log('✅ Login successful');

        // Get all workers
        const workersResponse = await axios.get(`${API_URL}/workers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const workers = workersResponse.data;
        console.log(`📊 Found ${workers.length} workers to update`);

        // Update each worker's salary (reduce by 3/4, meaning divide by 4)
        for (const worker of workers) {
            try {
                const updatedData = {
                    ...worker,
                    salaryGross: Math.round(worker.salaryGross / 4),
                };

                // If hourly worker, also update hourly rate
                if (worker.employmentType === 'HOURLY' && worker.hourlyRate) {
                    updatedData.hourlyRate = Math.round(worker.hourlyRate / 4);
                }

                const updateResponse = await axios.patch(
                    `${API_URL}/workers/${worker.id}`,
                    updatedData,
                    {
                        headers: { 'Authorization': `Bearer ${token}` }
                    }
                );

                if (updateResponse.status === 200) {
                    console.log(`✅ Updated ${worker.name}: KES ${worker.salaryGross} → KES ${updatedData.salaryGross}`);
                }
            } catch (error) {
                console.log(`❌ Failed to update ${worker.name}:`, error.message);
                if (error.response) {
                    console.log('   Status:', error.response.status);
                    console.log('   Data:', JSON.stringify(error.response.data, null, 2));
                }
            }
        }

        console.log('🎉 Salary updates complete!');

    } catch (error) {
        console.error('❌ Error during salary update:', error.message);
        if (error.response) {
            console.error('   Status:', error.response.status);
            console.error('   Data:', JSON.stringify(error.response.data, null, 2));
        }
    }
}

updateWorkerSalaries();
