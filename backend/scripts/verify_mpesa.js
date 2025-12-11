const https = require('https');
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '../.env');

try {
    if (!fs.existsSync(envPath)) {
        console.error('.env file not found!');
        process.exit(1);
    }

    const envContent = fs.readFileSync(envPath, 'utf8');
    const env = {};
    envContent.split('\n').forEach(line => {
        const trimmed = line.trim();
        if (trimmed && !trimmed.startsWith('#')) {
            const firstEqual = trimmed.indexOf('=');
            if (firstEqual > -1) {
                const key = trimmed.substring(0, firstEqual).trim();
                const value = trimmed.substring(firstEqual + 1); // Don't trim value yet to check for spaces
                env[key] = value;
            }
        }
    });

    const consumerKey = (env['MPESA_CONSUMER_KEY'] || '').trim();
    const consumerSecret = (env['MPESA_CONSUMER_SECRET'] || '').trim();
    const callbackUrl = env['MPESA_CALLBACK_URL'] || '';

    console.log('--- Configuration Check ---');

    // Check Callback URL for spaces
    if (callbackUrl !== callbackUrl.trim()) {
        console.error('❌ WARNING: MPESA_CALLBACK_URL has leading/trailing whitespace!');
        console.log(`   Value: "${callbackUrl}"`);
    } else {
        console.log('✅ MPESA_CALLBACK_URL format looks ok.');
    }

    if (!consumerKey || !consumerSecret) {
        console.error('❌ Missing MPESA_CONSUMER_KEY or MPESA_CONSUMER_SECRET in .env');
        process.exit(1);
    }

    console.log(`Debug Info:`);
    console.log(`Key: ${consumerKey.substring(0, 5)}... (Length: ${consumerKey.length})`);
    console.log(`Secret: ${consumerSecret.substring(0, 5)}... (Length: ${consumerSecret.length})`);

    console.log('\n--- API Authentication Check ---');
    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');

    const options = {
        hostname: 'sandbox.safaricom.co.ke',
        path: '/oauth/v1/generate?grant_type=client_credentials',
        method: 'GET',
        headers: {
            'Authorization': `Basic ${auth}`,
            'User-Agent': 'PayKey-Test-Script/1.0',
            'Accept': 'application/json'
        }
    };

    const req = https.request(options, (res) => {
        console.log(`STATUS: ${res.statusCode}`);

        let data = '';
        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            try {
                const json = JSON.parse(data);
                if (res.statusCode === 200 && json.access_token) {
                    console.log('✅ Authentication SUCCESS! Access Token received.');
                    console.log(`   Expires in: ${json.expires_in} seconds`);
                } else {
                    console.error('❌ Authentication FAILED.');
                    console.error('   Response:', data);
                }
            } catch (e) {
                console.error('   Non-JSON Response:', data);
            }
        });
    });

    req.on('error', (e) => {
        console.error(`Please check your internet connection. Request failed: ${e.message}`);
    });

    req.end();

} catch (err) {
    console.error('Script Error:', err);
}
