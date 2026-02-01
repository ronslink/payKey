const axios = require('axios');

const API_URL = 'http://localhost:3000';
const EMAIL = 'testuser@paykey.com';
const PASSWORD = 'testuser123';

async function verifyBankUpdate() {
    console.log('🔍 Verifying Bank Update...');

    try {
        // 1. Login
        console.log('1. Logging in...');
        const loginRes = await axios.post(`${API_URL}/auth/login`, {
            email: EMAIL,
            password: PASSWORD,
        });
        const token = loginRes.data.access_token;
        console.log('✅ Login successful');

        // 2. Update Profile with Bank Info
        const bankData = {
            bankName: 'KCB Bank Kenya Limited',
            bankCode: '01',
            bankAccount: '1234567890',
        };

        console.log('2. Updating Profile with Bank Info...', bankData);
        await axios.patch(
            `${API_URL}/users/profile`,
            bankData,
            { headers: { Authorization: `Bearer ${token}` } }
        );
        console.log('✅ Update successful');

        // 3. Fetch Profile
        console.log('3. Fetching Profile...');
        const profileRes = await axios.get(
            `${API_URL}/users/profile`,
            { headers: { Authorization: `Bearer ${token}` } }
        );

        const user = profileRes.data;
        console.log('📊 Profile Data:', {
            bankName: user.bankName,
            bankCode: user.bankCode,
            bankAccount: user.bankAccount
        });

        // 4. Verify
        if (user.bankName === bankData.bankName &&
            user.bankCode === bankData.bankCode &&
            user.bankAccount === bankData.bankAccount) {
            console.log('✅ SUCCESS: Bank info saved and retrieved correctly!');
        } else {
            console.error('❌ FAILURE: Bank info mismatch!');
            console.error('Expected:', bankData);
            console.error('Received:', {
                bankName: user.bankName,
                bankCode: user.bankCode,
                bankAccount: user.bankAccount
            });
            process.exit(1);
        }

    } catch (error) {
        console.error('❌ Error:', error.response?.data || error.message);
        process.exit(1);
    }
}

verifyBankUpdate();
