// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function setRenewalDate() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    await ds.query(`
        UPDATE subscriptions 
        SET "nextBillingDate" = '2026-01-23' 
        WHERE "userId" = (SELECT id FROM users WHERE email = 'kingpublish@gmail.com')
    `);

    console.log('✅ Subscription next billing date set to January 23, 2026');
    await app.close();
}

setRenewalDate();
