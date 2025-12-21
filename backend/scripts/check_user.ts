
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { DataSource, Like } from 'typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Subscription } from '../src/modules/subscriptions/entities/subscription.entity';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    const dataSource = app.get(DataSource);

    console.log('--- Checking User lex12 ---');
    // Search for any email containing lex12
    const users = await dataSource.getRepository(User).find({
        where: { email: Like('%lex12%') }
    });

    if (users.length > 0) {
        for (const user of users) {
            console.log('User found:', {
                id: user.id,
                email: user.email,
                tier: user.tier,
                createdAt: user.createdAt
            });

            const sub = await dataSource.getRepository(Subscription).findOne({ where: { userId: user.id } });
            console.log('Subscription found:', sub);
        }
    } else {
        console.log('User lex12 not found. Listing first 5 users...');
        const allUsers = await dataSource.getRepository(User).find({ take: 5 });
        allUsers.forEach(u => console.log(`${u.email} - Tier: ${u.tier}`));
    }

    await app.close();
}

bootstrap();
