// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

async function completeOnboarding() {
    console.log('🎯 Completing onboarding for Sam Olago...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        // Get Kenya country ID
        const countries = await dataSource.query(`SELECT id FROM countries WHERE code = 'KE' LIMIT 1`);
        const kenyaId = countries.length > 0 ? countries[0].id : null;

        // Update Sam's user record with required onboarding fields
        const result = await dataSource.query(`
            UPDATE users 
            SET 
                "firstName" = 'Samuel',
                "lastName" = 'Olago',
                "businessName" = 'Samuel Olago Household',
                "idType" = 'NATIONAL_ID',
                "idNumber" = '12345678',
                "nationalityId" = $1,
                "countryId" = $1,
                "kraPin" = 'A001234567X',
                "isOnboardingCompleted" = true,
                tier = 'PLATINUM'
            WHERE email = 'kingpublish@gmail.com'
            RETURNING email, "firstName", "lastName", "isOnboardingCompleted", tier
        `, [kenyaId]);

        console.log('✅ Onboarding completed:');
        console.log(result[0]);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

completeOnboarding();
