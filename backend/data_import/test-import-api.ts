import axios from 'axios';
import FormData from 'form-data';
import * as fs from 'fs';
import * as path from 'path';

async function testImport() {
    const baseUrl = 'http://localhost:3000';

    console.log('📧 Step 1: Logging in as lex12@yahoo.com...');

    try {
        // Login
        const loginRes = await axios.post(`${baseUrl}/auth/login`, {
            email: 'lex12@yahoo.com',
            password: 'password123'
        });

        const token = loginRes.data.access_token;
        const user = loginRes.data.user;
        console.log(`✅ Logged in as: ${user.firstName} ${user.lastName}`);

        // Check subscription
        console.log('\n💳 Step 2: Checking subscription...');
        const subRes = await axios.get(`${baseUrl}/subscriptions/current`, {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('   Subscription Data:', JSON.stringify(subRes.data, null, 2));

        // Check tier on root or plan
        const tier = subRes.data?.tier || subRes.data?.plan?.tier;
        console.log(`   Detected Tier: ${tier}`);

        if (tier !== 'GOLD' && tier !== 'PLATINUM') {
            console.log('\n⚠️ User does not have GOLD/PLATINUM tier.');
            console.log('   The import will be rejected by the TierGuard.');
            console.log('   Attempting import anyway to see the error...\n');
        }

        // Import Excel file
        console.log('\n📤 Step 3: Uploading Excel file...');
        const excelPath = path.join(__dirname, '..', 'test_workers_import.xlsx');

        if (!fs.existsSync(excelPath)) {
            console.log(`❌ Excel file not found at: ${excelPath}`);
            return;
        }

        const formData = new FormData();
        formData.append('file', fs.createReadStream(excelPath));

        const importRes = await axios.post(`${baseUrl}/excel-import/employees`, formData, {
            headers: {
                Authorization: `Bearer ${token}`,
                ...formData.getHeaders()
            }
        });

        console.log('\n✅ Import Results:');
        console.log(`   Success: ${importRes.data.success}`);
        console.log(`   Total Rows: ${importRes.data.totalRows}`);
        console.log(`   Imported: ${importRes.data.importedCount}`);
        console.log(`   Errors: ${importRes.data.errorCount}`);

        if (importRes.data.importedEmployees?.length) {
            console.log('\n📋 Imported Workers:');
            importRes.data.importedEmployees.forEach((emp: any, i: number) => {
                console.log(`   ${i + 1}. ${emp.name} (ID: ${emp.id})`);
            });
        }

        if (importRes.data.errors?.length) {
            console.log('\n❌ Errors:');
            importRes.data.errors.forEach((err: any) => {
                console.log(`   Row ${err.row}: ${err.field} - ${err.message}`);
            });
        }

    } catch (error: any) {
        if (error.response) {
            console.log(`\n❌ Error: ${error.response.status} - ${error.response.data?.message || JSON.stringify(error.response.data)}`);
        } else {
            console.log(`\n❌ Error: ${error.message}`);
        }
    }
}

testImport();
