// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';

async function resetPassword() {
    console.log('🔑 Resetting Sam Olago password...\n');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);

    try {
        const newPassword = 'Sam2026test!';
        const salt = await bcrypt.genSalt();
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        const result = await dataSource.query(`
            UPDATE users 
            SET "passwordHash" = $1
            WHERE email = 'kingpublish@gmail.com'
            RETURNING email
        `, [hashedPassword]);

        console.log('✅ Password reset for:', result[0]?.email);
        console.log('   New password:', newPassword);

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

resetPassword();
