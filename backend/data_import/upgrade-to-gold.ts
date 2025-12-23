import { DataSource } from 'typeorm';
import * as bcrypt from 'bcryptjs';

async function checkAndUpgradeUser() {
    const dataSource = new DataSource({
        type: 'postgres',
        host: 'localhost',
        port: 5432,
        username: 'postgres',
        password: 'admin',
        database: 'paykey',
        synchronize: false,
    });

    await dataSource.initialize();
    console.log('✅ Connected to database');

    // Find user
    let userResult = await dataSource.query(
        `SELECT id, email, "firstName", "lastName" FROM users WHERE email = $1`,
        ['lex12@yahoo.com']
    );

    if (userResult.length === 0) {
        console.log('⚠️ User lex12@yahoo.com not found. Creating user...');

        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash('password123', salt);

        await dataSource.query(
            `INSERT INTO users (email, "passwordHash", "firstName", "lastName", "isOnboardingCompleted") 
              VALUES ($1, $2, $3, $4, $5)`,
            ['lex12@yahoo.com', hash, 'Lex', 'Tester', true]
        );

        console.log('✅ Created user lex12@yahoo.com');

        // Re-fetch user
        userResult = await dataSource.query(
            `SELECT id, email, "firstName", "lastName" FROM users WHERE email = $1`,
            ['lex12@yahoo.com']
        );
    }

    const user = userResult[0];
    console.log(`\n📧 User: ${user.email} (${user.firstName} ${user.lastName})`);
    console.log(`   ID: ${user.id}`);

    // Check subscription
    const subResult = await dataSource.query(
        `SELECT s.* 
         FROM subscriptions s 
         WHERE s."userId" = $1 AND s.status = 'ACTIVE'
         ORDER BY s."createdAt" DESC LIMIT 1`,
        [user.id]
    );

    if (subResult.length > 0) {
        const sub = subResult[0];
        console.log(`\n💳 Current Subscription:`);
        console.log(`   Tier: ${sub.tier}`);
        console.log(`   Status: ${sub.status}`);
        console.log(`   Ends: ${sub.endDate}`);

        if (sub.tier === 'GOLD' || sub.tier === 'PLATINUM') {
            console.log('\n✅ User already has GOLD/PLATINUM tier subscription.');
        } else {
            console.log('\n⚠️ User has active subscription but not GOLD/PLATINUM.');
        }
    } else {
        console.log('\n⚠️ No active subscription found');
    }

    // Force upgrade to GOLD
    console.log('\n🔄 Upgrading user to GOLD tier...');

    // Deactivate existing subscriptions
    await dataSource.query(
        `UPDATE subscriptions SET status = 'CANCELLED' WHERE "userId" = $1`,
        [user.id]
    );

    // Create new GOLD subscription
    const now = new Date();
    const endDate = new Date(now);
    endDate.setFullYear(endDate.getFullYear() + 1);

    await dataSource.query(
        `INSERT INTO subscriptions ("userId", "tier", "status", "startDate", "endDate", "currency", "amount")
         VALUES ($1, 'GOLD', 'ACTIVE', $2, $3, 'KES', 3900)`,
        [user.id, now.toISOString(), endDate.toISOString()]
    );

    // Update USER tier as well (denormalized)
    await dataSource.query(
        `UPDATE users SET tier = 'GOLD' WHERE id = $1`,
        [user.id]
    );

    console.log('✅ User upgraded to GOLD tier!');
    console.log(`   Valid until: ${endDate.toISOString().split('T')[0]}`);

    await dataSource.destroy();
}

checkAndUpgradeUser().catch(console.error);
