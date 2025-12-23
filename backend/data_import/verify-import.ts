// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function verifyImport() {
    console.log('📊 Verifying Sam Olago Data Import...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        // 1. Check Sam User
        const users = await dataSource.query(`
            SELECT id, email, tier FROM users WHERE email = 'kingpublish@gmail.com'
        `);
        console.log('👤 User:', users.length > 0 ? users[0] : 'NOT FOUND');

        const samUserId = users.length > 0 ? users[0].id : null;

        if (!samUserId) {
            console.log('\n❌ Sam user not found - import may have failed');
            return;
        }

        // 2. Check Sam's Subscription
        const samSub = await dataSource.query(`SELECT tier, status FROM subscriptions WHERE "userId" = $1`, [samUserId]);
        console.log('💎 Sam Subscription:', samSub.length > 0 ? samSub[0] : 'NONE');

        // 3. Check Sam's Property
        const samProp = await dataSource.query(`SELECT name, address, what3words FROM properties WHERE "userId" = $1`, [samUserId]);
        console.log('🏢 Sam Property:', samProp.length > 0 ? samProp[0] : 'NONE');

        // 4. Check Sam's Workers
        const samWorkers = await dataSource.query(`SELECT name, "salaryGross", "kraPin" FROM workers WHERE "userId" = $1`, [samUserId]);
        console.log('\n👷 Sam Workers (' + samWorkers.length + '):');
        samWorkers.forEach(w => console.log(`   - ${w.name} (PIN: ${w.kraPin}): KES ${w.salaryGross}`));

        // Check for expected workers
        const hasKefa = samWorkers.some(w => w.name && w.name.includes('KEFA'));
        const hasMusulwa = samWorkers.some(w => w.name && w.name.includes('MUSULWA'));
        console.log('\n📋 Expected Workers Check:');
        console.log(`   KEFA, Nicholas Luvaga: ${hasKefa ? '✅ Found' : '❌ Missing'}`);
        console.log(`   MUSULWA, Janet Ngoyisi: ${hasMusulwa ? '✅ Found' : '❌ Missing'}`);

        // 5. Check Sam's Pay Periods
        const samPeriods = await dataSource.query(`SELECT COUNT(*) as count FROM pay_periods WHERE "userId" = $1`, [samUserId]);
        console.log('\n📅 Sam Pay Periods:', samPeriods[0].count, '(expected: 18)');

        // 6. Check Sam's Payroll Records
        const samRecords = await dataSource.query(`SELECT COUNT(*) as count FROM payroll_records WHERE "userId" = $1`, [samUserId]);
        console.log('📄 Sam Payroll Records:', samRecords[0].count, '(expected: 36)');

        console.log('\n✅ Verification Complete!');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

verifyImport();
