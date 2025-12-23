// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function updatePhone() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);
    await ds.query(`UPDATE users SET "phoneNumber" = '+254712492207' WHERE email = 'kingpublish@gmail.com'`);
    console.log('✅ Phone updated to +254712492207');
    await app.close();
}

updatePhone();
