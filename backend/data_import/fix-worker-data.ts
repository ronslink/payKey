// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function fixWorkerData() {
    console.log('🔧 Fixing worker data...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        // Fix leave balance to 21 days
        await dataSource.query(`
            UPDATE workers 
            SET "leaveBalance" = 21
            WHERE "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
        `);
        console.log('✅ Leave balance set to 21 days');

        // Set random date of birth (adults between 25-55 years old)
        // KEFA gets 1985-03-15, MUSULWA gets 1980-07-22
        await dataSource.query(`
            UPDATE workers 
            SET "dateOfBirth" = '1985-03-15'
            WHERE name LIKE '%KEFA%' 
            AND "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
        `);

        await dataSource.query(`
            UPDATE workers 
            SET "dateOfBirth" = '1980-07-22'
            WHERE name LIKE '%MUSULWA%'
            AND "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
        `);
        console.log('✅ Date of birth set for workers');

        // Verify
        const workers = await dataSource.query(`
            SELECT name, "leaveBalance", "dateOfBirth" 
            FROM workers 
            WHERE "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
        `);

        console.log('\n📋 Updated Workers:');
        workers.forEach(w => console.log(`   - ${w.name}: DOB=${w.dateOfBirth}, Leave=${w.leaveBalance} days`));

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

fixWorkerData();
