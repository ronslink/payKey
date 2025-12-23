// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function fixLeaveBalance() {
    console.log('🌴 Fixing leave balance...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        const result = await dataSource.query(`
            UPDATE workers 
            SET "leaveBalance" = 21 
            WHERE "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
            RETURNING name, "leaveBalance"
        `);

        console.log('✅ Updated leave balance:');
        result.forEach(w => console.log(`   - ${w.name}: ${w.leaveBalance} days`));

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

fixLeaveBalance();
