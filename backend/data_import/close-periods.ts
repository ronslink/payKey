// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function closePeriods() {
    console.log('🔒 Closing all historical pay periods...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    try {
        const result = await ds.query(`
            UPDATE pay_periods 
            SET status = 'CLOSED' 
            WHERE "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
            AND status != 'CLOSED'
            RETURNING name, status
        `);

        console.log(`✅ Closed ${result.length} pay periods`);
        result.forEach(p => console.log(`   - ${p.name}: ${p.status}`));

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

closePeriods();
