
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { UsersService } from '../src/modules/users/users.service';
import { UserTier } from '../src/modules/users/entities/user.entity';

async function setPlatinum() {
    const app = await NestFactory.createApplicationContext(AppModule);
    try {
        const usersService = app.get(UsersService);
        const email = 'testuser@paykey.com';

        console.log(`Setting ${email} to PLATINUM...`);

        const user = await usersService.findOneByEmail(email);
        if (!user) {
            console.log('❌ User not found');
            return;
        }

        // Direct update to ensure it sticks
        await usersService.update(user.id, { tier: UserTier.PLATINUM });

        const updated = await usersService.findOneByEmail(email);
        console.log(`✅ Updated ${email}. Tier is now: ${updated.tier}`);

    } catch (err) {
        console.error('❌ Error:', err);
    } finally {
        await app.close();
    }
}

setPlatinum();
