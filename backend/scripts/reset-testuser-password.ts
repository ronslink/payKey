import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import * as bcrypt from 'bcrypt';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Repository } from 'typeorm';

async function resetPassword() {
    const email = 'testuser@paykey.com';
    const newPassword = 'testuser123';

    console.log(`🔐 Resetting password for ${email} to ${newPassword}...\n`);

    // Force production environment if needed, or rely on .env
    const app = await NestFactory.createApplicationContext(AppModule);

    try {
        const userRepository = app.get<Repository<User>>(getRepositoryToken(User));

        // Hash the new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        const result = await userRepository.update(
            { email: email },
            { passwordHash: hashedPassword }
        );

        if (result.affected && result.affected > 0) {
            console.log('✅ Password reset successfully!');
        } else {
            console.log('⚠️  User not found: ' + email);
        }
    } catch (error) {
        console.error('❌ Error resetting password:', error.message);
        if (error.stack) console.error(error.stack);
    } finally {
        await app.close();
    }
}

resetPassword();
