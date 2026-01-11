const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function seedDemoWorkers() {
    try {
        console.log('🔍 Starting demo workers check and seeding for Test User...');

        // Login first
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'testuser@paykey.com',
            password: 'TestUser2026!'
        });

        const token = loginResponse.data.access_token;
        console.log('✅ Login successful');

        // Check existing workers
        const workersResponse = await axios.get(`${API_URL}/workers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        const existingWorkers = workersResponse.data;
        console.log(`📊 Found ${existingWorkers.length} existing workers`);

        if (existingWorkers.length < 3) {
            console.log('🌟 Seeding demo employees...');

            // Add demo employees
            // Helper for random string/number
            const rnd = (len) => Math.floor(Math.random() * Math.pow(10, len)).toString().padStart(len, '0');

            // Add demo employees with randomized unique fields to avoid collisions
            const demoWorkers = [
                {
                    name: 'Jane Wanjiku',
                    phoneNumber: '+2547' + rnd(8),
                    idNumber: rnd(8),
                    kraPin: 'A' + rnd(9) + 'A',
                    salaryGross: 85000,
                    jobTitle: 'Software Engineer',
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'BANK',
                    bankName: 'KCB Bank',
                    bankAccount: rnd(10),
                    startDate: '2024-01-01',
                    email: 'jane.wanjiku.' + rnd(4) + '@example.com',
                    nssfNumber: rnd(11),
                    nhifNumber: rnd(8),
                    isActive: true
                },
                {
                    name: 'Peter Mwangi',
                    phoneNumber: '+2547' + rnd(8),
                    idNumber: rnd(8),
                    kraPin: 'B' + rnd(9) + 'B',
                    salaryGross: 95000,
                    jobTitle: 'Marketing Manager',
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'MPESA',
                    mpesaNumber: '+2547' + rnd(8),
                    startDate: '2024-02-01',
                    email: 'peter.mwangi.' + rnd(4) + '@example.com',
                    nssfNumber: rnd(11),
                    nhifNumber: rnd(8),
                    isActive: true
                },
                {
                    name: 'Grace Akinyi',
                    phoneNumber: '+2547' + rnd(8),
                    idNumber: rnd(8),
                    kraPin: 'C' + rnd(9) + 'C',
                    salaryGross: 75000,
                    jobTitle: 'HR Specialist',
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'BANK',
                    bankName: 'Equity Bank',
                    bankAccount: rnd(10),
                    startDate: '2024-01-15',
                    email: 'grace.akinyi.' + rnd(4) + '@example.com',
                    nssfNumber: rnd(11),
                    nhifNumber: rnd(8),
                    isActive: true
                },
                {
                    name: 'David Kiprotich',
                    phoneNumber: '+2547' + rnd(8),
                    idNumber: rnd(8),
                    kraPin: 'D' + rnd(9) + 'D',
                    salaryGross: 65000,
                    jobTitle: 'Sales Representative',
                    employmentType: 'HOURLY',
                    hourlyRate: 400,
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'MPESA',
                    mpesaNumber: '+2547' + rnd(8),
                    startDate: '2024-03-01',
                    email: 'david.kiprotich.' + rnd(4) + '@example.com',
                    nssfNumber: rnd(11),
                    nhifNumber: rnd(8),
                    isActive: true
                },
                {
                    name: 'Mary Chebet',
                    phoneNumber: '+2547' + rnd(8),
                    idNumber: rnd(8),
                    kraPin: 'E' + rnd(9) + 'E',
                    salaryGross: 80000,
                    jobTitle: 'Accountant',
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'BANK',
                    bankName: 'Co-operative Bank',
                    bankAccount: rnd(10),
                    startDate: '2024-01-10',
                    email: 'mary.chebet.' + rnd(4) + '@example.com',
                    nssfNumber: rnd(11),
                    nhifNumber: rnd(8),
                    isActive: true
                }
            ];

            for (const worker of demoWorkers) {
                try {
                    const createResponse = await axios.post(`${API_URL}/workers`, worker, {
                        headers: { 'Authorization': `Bearer ${token}` }
                    });

                    if (createResponse.status === 201) {
                        console.log(`✅ Added worker: ${worker.name}`);
                    }
                } catch (error) {
                    console.log(`❌ Failed to add worker ${worker.name}:`, error.message);
                    if (error.response) {
                        console.log('   Status:', error.response.status);
                        console.log('   Data:', JSON.stringify(error.response.data, null, 2));
                    }
                }
            }

            // Verify final count
            const finalResponse = await axios.get(`${API_URL}/workers`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });

            console.log(`🎉 Demo workers setup complete! Total workers: ${finalResponse.data.length}`);

        } else {
            console.log('✅ Demo employees already exist:');
            existingWorkers.forEach((worker, index) => {
                console.log(`${index + 1}. ${worker.name} - ${worker.employmentType}`);
            });
        }

    } catch (error) {
        console.error('❌ Error during demo workers setup:', error.message);
    }
}

seedDemoWorkers();
