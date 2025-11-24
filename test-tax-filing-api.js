// Using built-in fetch API (Node.js 18+)

const BASE_URL = 'http://localhost:3000';
let authToken = '';

// Helper function to make requests
async function request(method, endpoint, body = null) {
    const options = {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...(authToken && { 'Authorization': `Bearer ${authToken}` })
        }
    };

    if (body) {
        options.body = JSON.stringify(body);
    }

    const response = await fetch(`${BASE_URL}${endpoint}`, options);
    const data = await response.json();

    if (!response.ok) {
        throw new Error(`${response.status}: ${JSON.stringify(data)}`);
    }

    return data;
}

async function testTaxFilingAPI() {
    console.log('🧪 Tax Filing API Test Suite\n');
    console.log('='.repeat(50));

    try {
        // Step 1: Register/Login
        console.log('\n📝 Step 1: Authentication');
        console.log('-'.repeat(50));

        try {
            await request('POST', '/auth/register', {
                email: 'taxtest@paykey.com',
                password: 'TaxTest123!',
                name: 'Tax Test User'
            });
            console.log(`   Year: ${taxTable.year}`);
            console.log(`   Personal Relief: KES ${taxTable.personalRelief}`);
            console.log(`   Housing Levy Rate: ${(taxTable.housingLevyRate * 100).toFixed(2)}%`);
            console.log(`   PAYE Bands: ${taxTable.payeBands.length} bands`);

            // Step 3: Get Tax Submissions
            console.log('\n📋 Step 3: Get Tax Submissions');
            console.log('-'.repeat(50));
            const submissions = await request('GET', '/taxes/submissions');
            console.log(`✅ Retrieved ${submissions.length} tax submission(s)`);

            if (submissions.length === 0) {
                console.log('\n⚠️  No tax submissions found');
                console.log('   To create a tax submission:');
                console.log('   1. Add a worker via POST /workers');
                console.log('   2. Create a pay period via POST /payroll/pay-periods');
                console.log('   3. Process payroll via POST /payments/payroll/process');
            } else {
                // Display first submission
                const sub = submissions[0];
                console.log('\n📄 First Submission Details:');
                console.log(`   ID: ${sub.id}`);
                console.log(`   Status: ${sub.status}`);
                console.log(`   Pay Period ID: ${sub.payPeriodId}`);
                console.log(`   Total PAYE: KES ${parseFloat(sub.totalPaye).toFixed(2)}`);
                console.log(`   Total NSSF: KES ${parseFloat(sub.totalNssf).toFixed(2)}`);
                console.log(`   Total NHIF: KES ${parseFloat(sub.totalNhif).toFixed(2)}`);
                console.log(`   Total Housing Levy: KES ${parseFloat(sub.totalHousingLevy).toFixed(2)}`);

                const totalTax = parseFloat(sub.totalPaye) + parseFloat(sub.totalNssf) +
                    parseFloat(sub.totalNhif) + parseFloat(sub.totalHousingLevy);
                console.log(`   TOTAL TAX: KES ${totalTax.toFixed(2)}`);

                // Step 4: Mark as Filed (if pending)
                if (sub.status === 'PENDING') {
                    console.log('\n✍️  Step 4: Mark Submission as Filed');
                    console.log('-'.repeat(50));
                    const filed = await request('PATCH', `/taxes/submissions/${sub.id}/file`);
                    console.log('✅ Submission marked as FILED');
                    console.log(`   Filing Date: ${filed.filingDate}`);
                    console.log(`   New Status: ${filed.status}`);
                } else {
                    console.log('\n✅ Submission already filed');
                    if (sub.filingDate) {
                        console.log(`   Filing Date: ${sub.filingDate}`);
                    }
                }
            }

            console.log('\n' + '='.repeat(50));
            console.log('✅ All Tax Filing API tests completed successfully!');
            console.log('='.repeat(50));

        } catch (error) {
            console.error('\n❌ Test failed:', error.message);
            process.exit(1);
        }
    }

// Run tests
testTaxFilingAPI();
