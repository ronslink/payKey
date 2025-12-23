// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function updateProfile() {
    console.log('📝 Updating Sam Olago profile...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        const result = await dataSource.query(`
            UPDATE users SET 
                "nssfNumber" = 'NSSF123456',
                "shifNumber" = 'SHIF789012',
                address = 'P.O. Box 67578 Nairobi 00200 Kenya',
                city = 'Nairobi',
                "phoneNumber" = '+254700000000',
                "residentStatus" = 'RESIDENT'
            WHERE email = 'kingpublish@gmail.com'
            RETURNING email, "firstName", "lastName", "nssfNumber", city
        `);

        console.log('✅ Profile updated:');
        console.log(result[0]);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

updateProfile();
