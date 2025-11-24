const baseUrl = 'http://localhost:3000';

async function testTaxFilingAPI() {
    console.log('=== Tax Filing API Test ===\n');

    // Test 1: Register/Login
    console.log('1. Registering user...');
    try {
        await fetch(`${baseUrl}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: 'testuser@paykey.com',
                password: 'Test123!',
                name: 'Test User'
            })
        });
        // Test 2: Get current tax table
        console.log('3. Getting current tax table...');
        const taxTableRes = await fetch(`${baseUrl}/taxes/current`, { headers });
        const taxTable = await taxTableRes.json();
        console.log(`✓ Tax table: Year ${taxTable.year}, Personal Relief: KES ${taxTable.personalRelief}\n`);

        // Test 3: Get tax submissions
        console.log('4. Getting tax submissions...');
        const submissionsRes = await fetch(`${baseUrl}/taxes/submissions`, { headers });
        const submissions = await submissionsRes.json();
        console.log(`✓ Found ${submissions.length} submission(s)\n`);

        if (submissions.length > 0) {
            const sub = submissions[0];
            console.log('First submission:');
            console.log(`  ID: ${sub.id}`);
            console.log(`  Status: ${sub.status}`);
            console.log(`  Total PAYE: KES ${sub.totalPaye}`);
            console.log(`  Total NSSF: KES ${sub.totalNssf}`);
            console.log(`  Total NHIF: KES ${sub.totalNhif}`);
            console.log(`  Total Housing Levy: KES ${sub.totalHousingLevy}\n`);

            if (sub.status === 'PENDING') {
                console.log('5. Marking submission as filed...');
                const filedRes = await fetch(`${baseUrl}/taxes/submissions/${sub.id}/file`, {
                    method: 'PATCH',
                    headers
                });
                const filed = await filedRes.json();
                console.log(`✓ Marked as FILED at ${filed.filingDate}\n`);
            }
        } else {
            console.log('No submissions yet. To create one:');
            console.log('  1. Add a worker');
            console.log('  2. Create a pay period');
            console.log('  3. Process payroll\n');
        }

        console.log('=== All Tests Complete ===');
    }

testTaxFilingAPI().catch(console.error);
