// Test Excel Import endpoint
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const API_URL = 'http://localhost:3000';

// You need to replace this with a valid JWT token
const JWT_TOKEN = 'YOUR_JWT_TOKEN_HERE';

async function testExcelImport() {
    console.log('Testing Excel Import endpoint...\n');

    try {
        // First, download the template
        console.log('1. Downloading template...');
        const templateResponse = await axios.get(`${API_URL}/excel-import/employees/template`, {
            headers: {
                'Authorization': `Bearer ${JWT_TOKEN}`,
            },
            responseType: 'arraybuffer'
        });

        console.log('   Template downloaded:', templateResponse.status);
        const templatePath = path.join(__dirname, 'test_template.xlsx');
        fs.writeFileSync(templatePath, templateResponse.data);
        console.log('   Saved to:', templatePath);

        // Now try to upload it back
        console.log('\n2. Uploading template...');
        const form = new FormData();
        form.append('file', fs.createReadStream(templatePath), {
            filename: 'test_template.xlsx',
            contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        });

        const importResponse = await axios.post(`${API_URL}/excel-import/employees`, form, {
            headers: {
                'Authorization': `Bearer ${JWT_TOKEN}`,
                ...form.getHeaders()
            },
        });

        console.log('   Import response:', importResponse.status);
        console.log('   Data:', JSON.stringify(importResponse.data, null, 2));

    } catch (error) {
        console.error('\n❌ Error:');
        if (error.response) {
            console.error('   Status:', error.response.status);
            console.error('   Message:', JSON.stringify(error.response.data, null, 2));
        } else {
            console.error('   ', error.message);
        }
    }
}

testExcelImport();
