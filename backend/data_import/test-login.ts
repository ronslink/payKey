// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { AuthService } from '../src/modules/auth/auth.service';

async function testLogin() {
    console.log('🔑 Testing login...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const authService = app.get(AuthService);

    try {
        const result = await authService.validateUser('kingpublish@gmail.com', 'Sam2026test!');

        if (result) {
            console.log('✅ Login successful!');
            console.log('   User:', result.email);
            console.log('   Tier:', result.tier);
        } else {
            console.log('❌ Login failed - invalid credentials');
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await app.close();
    }
}

testLogin();
