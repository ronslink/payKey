// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function check2026() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const ds = app.get(DataSource);

    const periods = await ds.query(`
        SELECT name FROM pay_periods 
        WHERE name LIKE '%2026%' 
        ORDER BY "startDate"
    `);

    console.log('2026 periods:', periods.map(p => p.name));
    await app.close();
}

check2026();
