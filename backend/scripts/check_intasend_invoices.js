const https = require('https');

// Read keys from environment
const PUBLISHABLE_KEY = process.env.INTASEND_PUBLISHABLE_KEY;
const SECRET_KEY = process.env.INTASEND_SECRET_KEY;

// The invoices we want to check
const invoices = ['KNQPGQ4', 'KZ5MM24'];

const isProduction = process.env.NODE_ENV === 'production';
const HOSTNAME = isProduction ? 'payment.intasend.com' : 'sandbox.intasend.com';

console.log(`Using Host: ${HOSTNAME}`);
console.log(`Secret Key Available: ${SECRET_KEY ? 'Yes' : 'No'}`);

async function checkInvoice(invoiceId) {
    // Try endpoint: /api/v1/checkout/requests/{invoice_id}/
    // This is often used to check status of an invoice/request

    // Another potential: /api/v1/payment/status/{invoice_id}/ 
    // (This is what some plugins use)

    const paths = [
        `/api/v1/checkout/requests/${invoiceId}/`,
        `/api/v1/payment/status/${invoiceId}/`
    ];

    const results = {};

    for (const path of paths) {
        console.log(`Checking ${path}...`);
        try {
            const data = await makeRequest(path);
            results[path] = { status: 'OK', data: data };
        } catch (e) {
            results[path] = { status: 'ERROR', error: e.message };
        }
    }
    return results;
}

function makeRequest(path) {
    const options = {
        hostname: HOSTNAME,
        path: path,
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${SECRET_KEY}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, res => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(new Error(`Failed to parse JSON: ${data}`));
                    }
                } else {
                    reject(new Error(`Status ${res.statusCode}: ${data}`));
                }
            });
        });
        req.on('error', e => reject(e));
        req.end();
    });
}

async function run() {
    console.log('Checking IntaSend Status...');
    for (const inv of invoices) {
        console.log(`\n-----------------------------------`);
        console.log(`Invoice ${inv}:`);
        const res = await checkInvoice(inv);
        console.log(JSON.stringify(res, null, 2));
    }
}

if (!SECRET_KEY) {
    console.error('Error: INTASEND_SECRET_KEY not found in environment');
    process.exit(1);
}

run();
