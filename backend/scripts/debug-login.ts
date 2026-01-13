
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import * as bcrypt from 'bcrypt';

async function debugLogin() {
    const app = await NestFactory.createApplicationContext(AppModule);
    try {
        const usersService = app.get(UsersService);
        const email = 'testuser@paykey.com';
        const password = 'testuser123';

        console.log(`🔍 Debugging login for ${email}`);

        const user = await usersService.findOneByEmail(email);

        if (!user) {
            console.log('❌ User not found');
            return;
        }

        console.log('✅ User found:', {
            id: user.id,
            email: user.email,
            passwordHash: user.passwordHash ? user.passwordHash.substring(0, 20) + '...' : 'MISSING',
        });

        try {
            const isMatch = await bcrypt.compare(password, user.passwordHash);
            console.log(`🔐 Password match result: ${isMatch}`);

            if (isMatch) {
                console.log('✅ Credentials are VALID');
            } else {
                console.log('❌ Credentials are INVALID');
                // Try another common password just in case
                const isMatchOld = await bcrypt.compare('password123', user.passwordHash);
                console.log(`🔐 Checking 'password123': ${isMatchOld}`);
            }
        } catch (err) {
            console.error('❌ Error during bcrypt comparison:', err);
        }

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await app.close();
    }
}

debugLogin();
