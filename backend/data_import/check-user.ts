// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function checkUser() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        const users = await dataSource.query(`
            SELECT email, "passwordHash" IS NOT NULL as has_password, 
                   LENGTH("passwordHash") as hash_length
            FROM users 
            WHERE email = 'kingpublish@gmail.com'
        `);

        console.log('User check:', users);

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await app.close();
    }
}

checkUser();
