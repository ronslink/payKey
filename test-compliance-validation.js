const BASE_URL = 'http://localhost:3000';
let authToken = '';

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

    return { status: response.status, data };
}

async function testCompliance() {
    console.log('🧪 Compliance Validation Test Suite\n');

    // 1. Auth
    console.log('1. Authenticating with Demo User...');
    const email = 'testuser@paykey.com';
    const password = 'SecurePass123!';

    // Try login directly
    console.log('Logging in...');
    const loginRes = await request('POST', '/auth/login', {
        email,
        password
    });

    if (loginRes.status === 201 || loginRes.status === 200) {
        authToken = loginRes.data.access_token;
        console.log('✅ Logged in');
    } else {
        console.error('❌ Login failed:', loginRes.data);
        // If login fails, maybe register? But user said use demo user.
        // Let's try register just in case it doesn't exist yet.
        console.log('Attempting registration...');
        const authRes = await request('POST', '/auth/register', {
            email,
            password,
            name: 'Demo User'
        });
        if (authRes.status === 201) {
            authToken = authRes.data.access_token;
            console.log('✅ Registered and logged in');
        } else {
            console.error('❌ Registration failed:', authRes.data);
            return;
        }
    }

    // 1.5 Fetch Countries to get valid ID
    console.log('Fetching countries...');
    const countryRes = await request('GET', '/countries');
    let validCountryId = 'KE'; // Default fallback if fetch fails (though likely UUID)
    if (countryRes.status === 200 && countryRes.data.length > 0) {
        validCountryId = countryRes.data[0].id;
        console.log('✅ Fetched valid Country ID:', validCountryId);
    } else {
        console.warn('⚠️ Could not fetch countries, using fallback:', validCountryId);
    }

    // 2. Test Invalid KRA PIN
    console.log('\n2. Testing Invalid KRA PIN (A123)...');
    const invalidKra = await request('PATCH', '/users/compliance', {
        kraPin: 'A123', // Invalid
        nssfNumber: '123',
        nhifNumber: '123',
        idType: 'NATIONAL_ID',
        idNumber: '12345678',
        address: 'Nairobi',
        city: 'Nairobi',
        countryId: validCountryId
    });
    if (invalidKra.status === 400 && JSON.stringify(invalidKra.data).includes('KRA PIN')) {
        console.log('✅ Invalid KRA PIN rejected');
    } else {
        console.error('❌ Failed: ', invalidKra.data);
    }

    // 3. Test Invalid National ID (Too short)
    console.log('\n3. Testing Invalid National ID (123)...');
    const invalidId = await request('PATCH', '/users/compliance', {
        kraPin: 'A123456789Z',
        nssfNumber: '123',
        nhifNumber: '123',
        idType: 'NATIONAL_ID',
        idNumber: '123', // Too short
        address: 'Nairobi',
        city: 'Nairobi',
        countryId: validCountryId
    });
    if (invalidId.status === 400 && JSON.stringify(invalidId.data).includes('National ID')) {
        console.log('✅ Invalid National ID rejected');
    } else {
        console.error('❌ Failed: ', invalidId.data);
    }

    // 4. Test Valid National ID
    console.log('\n4. Testing Valid National ID...');
    const validNational = await request('PATCH', '/users/compliance', {
        kraPin: 'A123456789Z',
        nssfNumber: '12345',
        nhifNumber: '12345',
        idType: 'NATIONAL_ID',
        idNumber: '12345678',
        address: 'Nairobi',
        city: 'Nairobi',
        countryId: validCountryId
    });
    if (validNational.status === 200) {
        console.log('✅ Valid National ID accepted');
    } else {
        console.error('❌ Failed: ', validNational.data);
    }

    // 5. Test Alien ID without Nationality
    console.log('\n5. Testing Alien ID without Nationality...');
    const invalidAlien = await request('PATCH', '/users/compliance', {
        kraPin: 'A123456789Z',
        nssfNumber: '12345',
        nhifNumber: '12345',
        idType: 'ALIEN_ID',
        idNumber: 'ALIEN123',
        address: 'Nairobi',
        city: 'Nairobi',
        countryId: validCountryId
        // Missing nationalityId
    });
    if (invalidAlien.status === 400 && JSON.stringify(invalidAlien.data).includes('Nationality is required')) {
        console.log('✅ Missing Nationality rejected for Alien ID');
    } else {
        console.error('❌ Failed: ', invalidAlien.data);
    }

    // 6. Test Valid Alien ID with Nationality
    console.log('\n6. Testing Valid Alien ID with Nationality...');
    const validAlien = await request('PATCH', '/users/compliance', {
        kraPin: 'A123456789Z',
        nssfNumber: '12345',
        nhifNumber: '12345',
        idType: 'ALIEN_ID',
        idNumber: 'ALIEN123',
        nationalityId: validCountryId, // Use valid ID
        address: 'Nairobi',
        city: 'Nairobi',
        countryId: validCountryId
    });
    if (validAlien.status === 200) {
        console.log('✅ Valid Alien ID accepted');
    } else {
        console.log('ℹ️  Response: ', validAlien.status, validAlien.data);
    }
}

testCompliance();
