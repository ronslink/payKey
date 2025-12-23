/**
 * Simplified import script for Sam Olago data
 * This version uses the existing seed-demo-workers.js pattern
 */
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Load extracted data
// Load extracted data
// Try multiple paths to work both on host and inside docker
const possiblePaths = [
    path.join(__dirname, 'extracted_data.json'), // Same directory
    path.join(__dirname, '../extracted_data.json'), // Parent (if run elsewhere)
    path.join(__dirname, '../../extracted_data.json') // Original fallback
];

let extractedDataPath;
for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
        extractedDataPath = p;
        break;
    }
}

if (!extractedDataPath) {
    console.error('❌ Could not find extracted_data.json');
    process.exit(1);
}

const extractedData = JSON.parse(fs.readFileSync(extractedDataPath, 'utf-8'));

async function importSamOlagoData() {
    console.log('🚀 Starting Sam Olago data import...\n');

    try {
        // Step 1: Register Sam Olago
        console.log('👤 Step 1: Creating Sam Olago user account...');
        let token;

        try {
            const registerResponse = await axios.post('http://localhost:3000/auth/register', {
                email: 'kingpublish@gmail.com',
                password: 'Sam2026test!',
            });
            token = registerResponse.data.access_token;
            console.log('   ✅ User created successfully');
        } catch (error) {
            // User might already exist, try to login
            const loginResponse = await axios.post('http://localhost:3000/auth/login', {
                email: 'kingpublish@gmail.com',
                password: 'Sam2026test!',
            });
            token = loginResponse.data.access_token;
            console.log('   ✅ User already exists, logged in');
        }

        // Step 2: Create workers
        console.log('\n👷 Step 2: Creating workers...');
        const workerMap = new Map();

        for (const workerData of extractedData.workers) {
            try {
                const worker = await axios.post('http://localhost:3000/workers', {
                    name: workerData.name,
                    phoneNumber: '+254712492207', // Sam's M-Pesa number
                    idNumber: workerData.id_no,
                    kraPin: workerData.pin,
                    nssfNumber: workerData.nssf,
                    nhifNumber: workerData.nhif,
                    jobTitle: workerData.job_title,
                    salaryGross: parseFloat(workerData.basic_pay),
                    employmentType: 'FIXED',
                    paymentFrequency: 'MONTHLY',
                    paymentMethod: 'CASH',
                    startDate: '2024-01-01',
                    isActive: true,
                }, {
                    headers: { 'Authorization': `Bearer ${token}` }
                });

                console.log(`   ✅ Created worker: ${workerData.name}`);
                workerMap.set(workerData.name, worker.data);
            } catch (error) {
                if (error.response?.status === 409 || error.response?.data?.message?.includes('already exists')) {
                    console.log(`   ⏭️  Worker already exists: ${workerData.name}`);
                    // Fetch existing worker
                    const workersResponse = await axios.get('http://localhost:3000/workers', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    });
                    const existingWorker = workersResponse.data.find(w => w.kraPin === workerData.pin);
                    if (existingWorker) {
                        workerMap.set(workerData.name, existingWorker);
                    }
                } else {
                    console.error(`   ❌ Failed to create worker ${workerData.name}:`, error.response?.data?.message || error.message);
                }
            }
        }

        console.log(`\n✅ Import completed!`);
        console.log(`   📊 Total workers: ${workerMap.size}`);
        console.log(`\n⚠️  Note: Historical payroll records will need to be created manually or via the UI.`);
        console.log(`   The extracted data includes ${extractedData.payroll_history.length} months of payroll history.`);

    } catch (error) {
        console.error('\n❌ Error during import:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
    }
}

// Wait for server to be ready
setTimeout(importSamOlagoData, 2000);
