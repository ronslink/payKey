// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function fixSubscription() {
    console.log('🔧 Fixing Sam subscription to PLATINUM...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        // Get Sam's user ID
        const users = await dataSource.query(`
            SELECT id FROM users WHERE email = 'kingpublish@gmail.com'
        `);

        if (users.length === 0) {
            console.log('❌ User not found');
            return;
        }

        const samUserId = users[0].id;
        console.log('User ID:', samUserId);

        // Update all Sam's subscriptions to PLATINUM
        const result = await dataSource.query(`
            UPDATE subscriptions 
            SET tier = 'PLATINUM', 
                "nextBillingDate" = '2025-12-31',
                amount = 49.99
            WHERE "userId" = $1
            RETURNING tier, status
        `, [samUserId]);

        console.log('Updated subscriptions:', result);

        // Verify
        const subs = await dataSource.query(`SELECT tier, status FROM subscriptions WHERE "userId" = $1`, [samUserId]);
        console.log('✅ Sam Subscription now:', subs[0]);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

fixSubscription();
