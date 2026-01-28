/**
 * Migration Script: Create IntaSend Wallets for Existing Users
 *
 * This script finds all users without an `intasend_wallet_id` and
 * queues wallet creation jobs via BullMQ.
 *
 * Usage: npx ts-node src/scripts/migrate-user-wallets.ts
 */

import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User, UserRole } from '../modules/users/entities/user.entity';
import { Repository, IsNull } from 'typeorm';
import { Queue } from 'bullmq';
import { getQueueToken } from '@nestjs/bullmq';

async function bootstrap() {
    console.log('🚀 Starting User Wallet Migration...');

    const app = await NestFactory.createApplicationContext(AppModule);

    const usersRepository = app.get<Repository<User>>(getRepositoryToken(User));
    const walletsQueue = app.get<Queue>(getQueueToken('wallets'));

    // Find all employer users (role = 'employer') without a wallet
    const usersWithoutWallets = await usersRepository.find({
        where: {
            role: UserRole.EMPLOYER,
            intasendWalletId: IsNull(),
        },
        select: ['id', 'firstName', 'lastName', 'businessName', 'email'],
    });

    console.log(
        `📋 Found ${usersWithoutWallets.length} employer(s) without wallets`,
    );

    if (usersWithoutWallets.length === 0) {
        console.log('✅ All employers already have wallets. Nothing to do.');
        await app.close();
        return;
    }

    // Queue wallet creation jobs for each user
    let queued = 0;
    for (const user of usersWithoutWallets) {
        const label =
            user.businessName ||
            `${user.firstName || ''} ${user.lastName || ''}`.trim() ||
            user.email ||
            user.id;

        await walletsQueue.add(
            'create-wallet',
            {
                userId: user.id,
                label: label,
            },
            {
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 5000,
                },
                removeOnComplete: true,
            },
        );

        queued++;
        console.log(`  📤 Queued wallet job for: ${label} (${user.id})`);
    }

    console.log(`\n✅ Queued ${queued} wallet creation job(s)`);
    console.log('💡 Jobs will be processed asynchronously by the WalletProcessor');

    await app.close();
}

bootstrap().catch((err) => {
    console.error('❌ Migration failed:', err);
    process.exit(1);
});
