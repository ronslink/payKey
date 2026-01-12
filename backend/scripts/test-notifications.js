/**
 * Test script to verify notification sending (SMS, Email, Push)
 * 
 * Usage:
 *   node scripts/test-notifications.js
 * 
 * Prerequisites:
 *   - Set environment variables in .env
 *   - Backend should be running (or this script starts fresh connection)
 */

require('dotenv').config();

const sendGridApiKey = process.env.SENDGRID_API_KEY;
const sendGridFromEmail = process.env.SENDGRID_FROM_EMAIL || 'noreply@paydome.co';
const atApiKey = process.env.AFRICANSTALKING_API_KEY;
const atUsername = process.env.AFRICANSTALKING_USERNAME || 'sandbox';

const TEST_PHONE = '+254708374149'; // Africa's Talking sandbox test phone
const TEST_EMAIL = 'test@example.com'; // Change to your email for real testing

async function testSendGrid() {
    console.log('\n📧 Testing SendGrid Email...');

    if (!sendGridApiKey || sendGridApiKey.includes('your-')) {
        console.log('   ⚠️  SENDGRID_API_KEY not configured, skipping...');
        return false;
    }

    try {
        const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${sendGridApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                personalizations: [{ to: [{ email: TEST_EMAIL }] }],
                from: { email: sendGridFromEmail },
                subject: 'PayDome Test Notification',
                content: [{ type: 'text/plain', value: 'This is a test email from PayDome notification system.' }],
            }),
        });

        if (response.status === 202) {
            console.log('   ✅ SendGrid: Email sent successfully!');
            return true;
        } else {
            const error = await response.text();
            console.log(`   ❌ SendGrid Error (${response.status}): ${error}`);
            return false;
        }
    } catch (error) {
        console.log(`   ❌ SendGrid Error: ${error.message}`);
        return false;
    }
}

async function testAfricasTalking() {
    console.log('\n📱 Testing Africa\'s Talking SMS...');

    if (!atApiKey || atApiKey.includes('your-')) {
        console.log('   ⚠️  AFRICANSTALKING_API_KEY not configured, skipping...');
        return false;
    }

    const isSandbox = atUsername.toLowerCase() === 'sandbox';
    const apiUrl = isSandbox
        ? 'https://api.sandbox.africastalking.com/version1/messaging'
        : 'https://api.africastalking.com/version1/messaging';

    console.log(`   Using ${isSandbox ? 'SANDBOX' : 'PRODUCTION'} endpoint`);
    console.log(`   API Key prefix: ${atApiKey.substring(0, 10)}...`);
    console.log(`   Username: ${atUsername}`);

    try {
        const params = new URLSearchParams({
            username: atUsername,
            to: TEST_PHONE,
            message: 'PayDome Test: This is a test SMS from the notification system.',
        });

        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'apiKey': atApiKey,
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
            body: params.toString(),
        });

        const responseText = await response.text();

        // Check if response is JSON
        let data;
        try {
            data = JSON.parse(responseText);
        } catch (e) {
            console.log(`   ❌ Africa's Talking Error (${response.status}): ${responseText}`);
            return false;
        }

        if (data.SMSMessageData?.Recipients?.[0]?.status === 'Success') {
            console.log(`   ✅ Africa's Talking: SMS sent!`);
            console.log(`   📝 Message ID: ${data.SMSMessageData.Recipients[0].messageId}`);
            return true;
        } else {
            console.log(`   ❌ Africa's Talking Error: ${JSON.stringify(data)}`);
            return false;
        }
    } catch (error) {
        console.log(`   ❌ Africa's Talking Error: ${error.message}`);
        return false;
    }
}

async function testFirebaseAdmin() {
    console.log('\n🔔 Testing Firebase Admin SDK...');

    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';

    try {
        const fs = require('fs');
        const path = require('path');

        const absolutePath = path.resolve(serviceAccountPath);

        if (!fs.existsSync(absolutePath)) {
            console.log(`   ⚠️  Firebase service account not found at ${absolutePath}`);
            return false;
        }

        const admin = require('firebase-admin');
        const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));

        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        }

        console.log('   ✅ Firebase Admin SDK initialized successfully!');
        console.log(`   📝 Project: ${serviceAccount.project_id}`);

        // Note: We can't send a test push without a valid device token
        console.log('   ℹ️  To test push notifications, run the mobile app and use the /notifications/test endpoint');

        return true;
    } catch (error) {
        console.log(`   ❌ Firebase Error: ${error.message}`);
        return false;
    }
}

async function main() {
    console.log('='.repeat(60));
    console.log('PayDome Notification System Test');
    console.log('='.repeat(60));

    console.log('\n📋 Configuration:');
    console.log(`   EMAIL_PROVIDER: ${process.env.EMAIL_PROVIDER || 'MOCK'}`);
    console.log(`   SMS_PROVIDER: ${process.env.SMS_PROVIDER || 'MOCK'}`);
    console.log(`   SENDGRID_FROM: ${sendGridFromEmail}`);
    console.log(`   AT_USERNAME: ${atUsername}`);

    const results = {
        email: await testSendGrid(),
        sms: await testAfricasTalking(),
        push: await testFirebaseAdmin(),
    };

    console.log('\n' + '='.repeat(60));
    console.log('Summary:');
    console.log('='.repeat(60));
    console.log(`   📧 Email (SendGrid): ${results.email ? '✅ Working' : '❌ Not configured'}`);
    console.log(`   📱 SMS (Africa's Talking): ${results.sms ? '✅ Working' : '❌ Not configured'}`);
    console.log(`   🔔 Push (Firebase): ${results.push ? '✅ Initialized' : '❌ Not configured'}`);
    console.log('\n');
}

main().catch(console.error);
