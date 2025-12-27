// @ts-nocheck
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import { DataSource } from 'typeorm';

async function upgradeUser() {
    console.log('🚀 Upgrading test user to GOLD tier...');

    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const usersService = app.get(UsersService);

    try {
        const email = 'testuser@paykey.com';
        const user = await usersService.findOneByEmail(email);

        if (!user) {
            console.error('❌ User not found:', email);
            process.exit(1);
        }

        console.log(`Found user: ${user.firstName} ${user.lastName} (${user.email}) - Current Tier: ${user.tier}`);

        await dataSource.query(`
            UPDATE users 
            SET tier = 'GOLD' 
            WHERE email = $1
        `, [email]);

        console.log('✅ User upgraded to GOLD tier successfully.');

    } catch (error) {
        console.error('❌ Error upgrading user:', error);
    } finally {
        await app.close();
        process.exit(0);
    }
}

upgradeUser();
