// Native fetch used (Node 18+)

const BASE_URL = 'http://localhost:3000';
// Use seeded user
const USER_EMAIL = 'testuser@paykey.com';
const USER_PASS = 'testuser123';

async function main() {
    try {
        console.log('🚀 Starting Off-Cycle Overlap Test...');

        // 1. Login
        console.log('\n🔐 Logging in...');
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: USER_EMAIL, password: USER_PASS }),
        });

        if (!loginRes.ok) throw new Error(`Login failed: ${loginRes.status}`);
        const { access_token: token } = await loginRes.json();
        console.log('✅ Login successful');

        // 2. Create Standard Period (e.g., Dec 2030) - Future to avoid conflicts
        const standardStart = new Date('2030-12-01').toISOString();
        const standardEnd = new Date('2030-12-31').toISOString();

        console.log('\n📅 Creating Standard Period (Dec 2030)...');
        const stdRes = await fetch(`${BASE_URL}/pay-periods`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: 'Standard Dec 2030',
                startDate: standardStart,
                endDate: standardEnd,
                frequency: 'MONTHLY',
                isOffCycle: false
            }),
        });

        if (!stdRes.ok) {
            // If it fails with "overlap", it might already exist from previous run.
            console.log('⚠️ Standard creation failed (likely exists). Proceeding...');
        } else {
            console.log('✅ Standard Period Created');
        }

        // 3. Create Off-Cycle Period (Dec 15-20) - Should SUCCEED
        console.log('\n📅 Creating Off-Cycle Period (Dec 15-20, Overlapping)...');
        const offRes = await fetch(`${BASE_URL}/pay-periods`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: 'Termination Dec 2030',
                startDate: new Date('2030-12-15').toISOString(),
                endDate: new Date('2030-12-20').toISOString(),
                frequency: 'MONTHLY',
                isOffCycle: true // CRITICAL
            }),
        });

        if (offRes.ok) {
            console.log('✅ Off-Cycle Period Created Successfully (Overlap Allowed!)');
        } else {
            const err = await offRes.json();
            throw new Error(`Off-Cycle creation failed: ${JSON.stringify(err)}`);
        }

        // 4. Create Conflicting Standard Period (Dec 10-25) - Should FAIL
        console.log('\n📅 Creating Conflicting Standard Period (Should FAIL)...');
        const conflictRes = await fetch(`${BASE_URL}/pay-periods`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: 'Conflict Dec 2030',
                startDate: new Date('2030-12-10').toISOString(),
                endDate: new Date('2030-12-25').toISOString(),
                frequency: 'MONTHLY',
                isOffCycle: false
            }),
        });

        if (conflictRes.status === 400) {
            console.log('✅ Conflicting Standard Period Properly Blocked');
        } else {
            console.error('❌ Failed: Conflicting period was allowed or unexpected error', conflictRes.status);
        }

    } catch (error) {
        console.error('❌ Test Failed:', error.message);
    }
}

// Check for native fetch
if (!globalThis.fetch) {
    console.error('Native fetch not found. Run with node 18+ or install node-fetch');
    process.exit(1);
}

main();
