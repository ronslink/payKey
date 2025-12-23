const axios = require('axios');

const configs = [
    // NHIF - Standard banded rates (Jan - Sep 2024)
    {
        taxType: 'NHIF',
        rateType: 'BANDED',
        effectiveFrom: '2024-01-01',
        effectiveTo: '2024-09-30',
        configuration: {
            bands: [
                { from: 0, to: 5999, amount: 150 },
                { from: 6000, to: 7999, amount: 300 },
                { from: 8000, to: 11999, amount: 400 },
                { from: 12000, to: 14999, amount: 500 },
                { from: 15000, to: 19999, amount: 600 },
                { from: 20000, to: 24999, amount: 750 },
                { from: 25000, to: 29999, amount: 850 },
                { from: 30000, to: 34999, amount: 900 },
                { from: 35000, to: 39999, amount: 950 },
                { from: 40000, to: 44999, amount: 1000 },
                { from: 45000, to: 49999, amount: 1100 },
                { from: 50000, to: 59999, amount: 1200 },
                { from: 60000, to: 69999, amount: 1300 },
                { from: 70000, to: 79999, amount: 1400 },
                { from: 80000, to: 89999, amount: 1500 },
                { from: 90000, to: 99999, amount: 1600 },
                { from: 100000, to: null, amount: 1700 }, // 100,000 and above
            ],
        },
        paymentDeadline: '9th of following month',
        notes: 'Standard NHIF rates (Pre-SHIF)',
        isActive: true,
    },

    // NSSF Tier 1 (2024 Rates - Prior to Feb 2025 change)
    {
        taxType: 'NSSF_TIER1',
        rateType: 'TIERED',
        effectiveFrom: '2024-02-01', // Effective from Feb 2024
        effectiveTo: '2025-01-31',
        configuration: {
            tiers: [
                {
                    name: 'Tier 1',
                    salaryFrom: 0, // Should be min wage technically
                    salaryTo: 7000,
                    rate: 6, // 6%
                },
            ],
        },
        paymentDeadline: '15th of following month',
        notes: 'NSSF Tier 1 (2024 Rates)',
        isActive: true,
    },

    // NSSF Tier 2 (2024 Rates)
    {
        taxType: 'NSSF_TIER2',
        rateType: 'TIERED',
        effectiveFrom: '2024-02-01',
        effectiveTo: '2025-01-31',
        configuration: {
            tiers: [
                {
                    name: 'Tier 2',
                    salaryFrom: 7001,
                    salaryTo: 36000,
                    rate: 6, // 6%
                },
            ],
        },
        paymentDeadline: '15th of following month',
        notes: 'NSSF Tier 2 (2024 Rates)',
        isActive: true,
    },
];

async function seedConfigs() {
    console.log('🚀 Seeding 2024 Tax Configurations via API...\n');

    // First, get an auth token (using Sam Olago's credentials or generic)
    let token;
    try {
        const loginResponse = await axios.post('http://localhost:3000/auth/login', {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
        });
        token = loginResponse.data.access_token;
        console.log('✅ Authenticated successfully');
    } catch (error) {
        console.error('❌ Authentication failed:', error.message);
        if (error.response?.status === 401) {
            console.log('Attempting to register user first...');
            try {
                const registerResponse = await axios.post('http://localhost:3000/auth/register', {
                    email: 'kingpublish@gmail.com',
                    password: 'Sam2026test!',
                    name: 'Sam Olago',
                });
                token = registerResponse.data.access_token;
                console.log('✅ User created and authenticated');
            } catch (regError) {
                console.error('❌ Registration failed:', regError.message);
                return; // Stop if we can't get a token
            }
        } else {
            return;
        }
    }

    // Also trigger the standard seeding (now that we disabled the check)
    try {
        console.log('🔄 Triggering standard config seeding...');
        await axios.post('http://localhost:3000/tax-config/seed', {}, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('✅ Standard configs seeded');
    } catch (error) {
        console.error('❌ Failed to seed standard configs:', error.response?.data?.message || error.message);
    }

    for (const config of configs) {
        try {
            await axios.post('http://localhost:3000/tax-config', config, {
                headers: { Authorization: `Bearer ${token}` }
            });
            console.log(`✅ Seeded: ${config.taxType}`);
        } catch (error) {
            console.error(`❌ Failed to seed ${config.taxType}:`, error.response?.data?.message || error.message);
        }
    }

    console.log('\n✨ Seeding completed!');
}

seedConfigs();
