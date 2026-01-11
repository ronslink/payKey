const axios = require('axios');

const API_URL = process.env.API_URL || 'http://localhost:3000';

const workersToRestore = [
    {
        name: "KEFA, Nicholas Luvaga",
        phoneNumber: "+254700000000", // Placeholder as per import script
        idNumber: "22124698",
        kraPin: "A008064326K",
        nssfNumber: "246694939",
        nhifNumber: "7573188",
        jobTitle: "Driver - KCA 191B",
        salaryGross: 16700.00,
        employmentType: 'FIXED',
        paymentFrequency: 'MONTHLY',
        paymentMethod: 'CASH',
        startDate: '2024-01-01'
    },
    {
        name: "MUSULWA, Janet Ngoyisi",
        phoneNumber: "+254700000000", // Placeholder as per import script
        idNumber: "9790160",
        kraPin: "A011473719L",
        nssfNumber: "573605823",
        nhifNumber: "7493843",
        jobTitle: "House Help",
        salaryGross: 17800.00,
        employmentType: 'FIXED',
        paymentFrequency: 'MONTHLY',
        paymentMethod: 'CASH',
        startDate: '2024-01-01'
    }
];

async function restoreWorkers() {
    console.log('🚀 Restoring workers via API...\n');

    let token;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
        });
        token = loginResponse.data.access_token;
        console.log('✅ Authenticated as Sam Olago');
    } catch (error) {
        console.error('❌ Authentication failed:', error.message);
        return;
    }

    const authHeaders = { Authorization: 'Bearer ' + token };

    for (const worker of workersToRestore) {
        try {
            await axios.post(`${API_URL}/workers`, worker, { headers: authHeaders });
            console.log('✅ Restored: ' + worker.name);
        } catch (error) {
            console.error('❌ Failed to restore ' + worker.name + ': ' + (error.response?.data?.message || error.message));
        }
    }

    console.log('\n✨ Worker restoration completed!');
}

restoreWorkers();
