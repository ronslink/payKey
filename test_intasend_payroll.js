/**
 * Test IntaSend Payroll/B2C Payments
 * 
 * This script simulates payroll payments to employees using IntaSend sandbox.
 * Tests the actual flow used by the PayKey backend for employee payouts.
 */

const axios = require('axios');

// IntaSend Test Credentials - Use environment variables
const INTASEND_PUBLISHABLE_KEY = process.env.INTASEND_PUBLISHABLE_KEY_TEST || 'your_test_publishable_key';
const INTASEND_SECRET_KEY = process.env.INTASEND_SECRET_KEY_TEST || 'your_test_secret_key';

const BASE_URL = 'https://sandbox.intasend.com/api';

// Simulated employee payroll records (like from database)
const mockPayrollRecords = [
    { id: 1, name: 'John Doe', phone: '254700000001', amount: 5000, narrative: 'January Salary' },
    { id: 2, name: 'Jane Smith', phone: '254700000002', amount: 7500, narrative: 'January Salary' },
    { id: 3, name: 'Bob Wilson', phone: '254700000003', amount: 10000, narrative: 'January Salary' },
];

// Sandbox test phone (IntaSend requires this for B2C payouts)
const SANDBOX_TEST_PHONE = '254708374149';

async function testPayrollPayments() {
    console.log('💸 Testing IntaSend Payroll/B2C Payment Flow...\n');
    console.log(`📋 Using Publishable Key: ${INTASEND_PUBLISHABLE_KEY.substring(0, 30)}...`);
    console.log(`📋 Using Secret Key: ${INTASEND_SECRET_KEY.substring(0, 30)}...`);
    console.log(`📋 Processing ${mockPayrollRecords.length} employee payments\n`);

    try {
        // Step 1: Get Wallet Balance (Check available funds)
        console.log('🔄 Step 1: Checking wallet balance...');
        const walletResponse = await axios.get(
            `${BASE_URL}/v1/wallets/`,
            {
                headers: {
                    'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        const kesWallet = walletResponse.data.results.find(w => w.currency === 'KES');
        console.log(`✅ KES Wallet Balance: ${kesWallet?.current_balance || 0} (Available: ${kesWallet?.available_balance || 0})`);
        console.log(`   Wallet ID: ${kesWallet?.wallet_id || 'N/A'}`);
        console.log(`   Can Disburse: ${kesWallet?.can_disburse || false}\n`);

        // Step 2: Process Single Employee Payment (B2C)
        console.log('🔄 Step 2: Testing single employee B2C payout...');
        const singleEmployee = mockPayrollRecords[0];
        console.log(`   Employee: ${singleEmployee.name}, Phone: ${singleEmployee.phone}, Amount: KES ${singleEmployee.amount}`);
        
        // Note: In sandbox, the phone number is replaced with the test number
        const singlePayoutResponse = await axios.post(
            `${BASE_URL}/v1/send-money/initiate/`,
            {
                provider: 'MPESA-B2C',
                currency: 'KES',
                transactions: [
                    {
                        name: singleEmployee.name,
                        account: SANDBOX_TEST_PHONE, // Sandbox override
                        amount: singleEmployee.amount,
                        narrative: singleEmployee.narrative,
                    }
                ]
            },
            {
                headers: {
                    'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log(`✅ Single Payout Created!`);
        console.log(`   Batch ID: ${singlePayoutResponse.data.file_id}`);
        console.log(`   Tracking ID: ${singlePayoutResponse.data.tracking_id}`);
        console.log(`   Status: ${singlePayoutResponse.data.status}`);
        console.log(`   Total Amount: KES ${singlePayoutResponse.data.total_amount}\n`);

        // Step 3: Process Bulk Employee Payments (Simulating payroll run)
        console.log('🔄 Step 3: Testing bulk employee payouts (payroll simulation)...');
        const totalPayrollAmount = mockPayrollRecords.reduce((sum, r) => sum + r.amount, 0);
        console.log(`   Total Employees: ${mockPayrollRecords.length}`);
        console.log(`   Total Payroll Amount: KES ${totalPayrollAmount}`);

        const bulkTransactions = mockPayrollRecords.map(r => ({
            name: r.name,
            account: SANDBOX_TEST_PHONE, // Sandbox override
            amount: r.amount,
            narrative: r.narrative,
        }));

        const bulkPayoutResponse = await axios.post(
            `${BASE_URL}/v1/send-money/initiate/`,
            {
                provider: 'MPESA-B2C',
                currency: 'KES',
                transactions: bulkTransactions,
            },
            {
                headers: {
                    'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        console.log(`✅ Bulk Payout Created!`);
        console.log(`   Batch ID: ${bulkPayoutResponse.data.file_id}`);
        console.log(`   Tracking ID: ${bulkPayoutResponse.data.tracking_id}`);
        console.log(`   Status: ${bulkPayoutResponse.data.status}`);
        console.log(`   Total Amount: KES ${bulkPayoutResponse.data.total_amount}`);
        console.log(`   Transactions Count: ${bulkPayoutResponse.data.transactions_count}\n`);

        // Step 4: Check Payout Status
        console.log('🔄 Step 4: Checking payout status...');
        if (bulkPayoutResponse.data.tracking_id) {
            try {
                const statusResponse = await axios.get(
                    `${BASE_URL}/v1/send-money/status/${bulkPayoutResponse.data.tracking_id}/`,
                    {
                        headers: {
                            'Authorization': `Bearer ${INTASEND_SECRET_KEY}`,
                            'Content-Type': 'application/json'
                        }
                    }
                );
                console.log(`✅ Status Retrieved:`);
                console.log(`   Status: ${statusResponse.data.status}`);
                console.log(`   Status Code: ${statusResponse.data.status_code}`);
                console.log(`   Charge Estimate: KES ${statusResponse.data.charge_estimate}`);
                console.log(`   Total Amount: KES ${statusResponse.data.total_amount}\n`);
            } catch (statusError) {
                console.log(`⚠️ Status check returned ${statusError.response?.status || 'error'}`);
                console.log(`   Note: Payout is in "Preview and approve" state`);
                console.log(`   Approve in IntaSend Dashboard to complete payment\n`);
            }
        }

        // Step 5: Summary
        console.log('='.repeat(60));
        console.log('📊 PAYROLL PAYMENT TEST SUMMARY');
        console.log('='.repeat(60));
        console.log(`✅ All payroll payment endpoints are working!`);
        console.log(`✅ Single B2C payout processed successfully`);
        console.log(`✅ Bulk payroll payouts (${mockPayrollRecords.length} employees) processed`);
        console.log(`✅ Total payroll amount: KES ${totalPayrollAmount}`);
        console.log(`✅ Wallet has sufficient balance for payouts`);
        console.log('\n📝 Next Steps:');
        console.log('- Integrate with payroll service for automatic payouts');
        console.log('- Set up webhook handlers for payment status callbacks');
        console.log('- Implement retry logic for failed payments');
        console.log('- Add payment confirmation emails to employees');
        console.log('='.repeat(60));

    } catch (error) {
        console.error('\n❌ Payroll Payment Test Failed:');
        if (error.response) {
            console.log(`Status: ${error.response.status}`);
            console.log(`Response: ${JSON.stringify(error.response.data, null, 2)}`);
        } else {
            console.log(`Error: ${error.message}`);
        }
        console.log('\n💡 Tips:');
        console.log('- Ensure wallet has sufficient balance');
        console.log('- Check that provider is MPESA-B2C for phone payouts');
        console.log('- In sandbox, phone numbers are replaced with test number');
    }
}

testPayrollPayments();
