import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { IntaSendService } from '../modules/payments/intasend.service';
import { Logger } from '@nestjs/common';
import { User } from '../modules/users/entities/user.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const logger = new Logger('BackfillWallets');

    try {
        const userRepository = app.get<Repository<User>>(getRepositoryToken(User));
        const intaSendService = app.get(IntaSendService);

        logger.log('🚀 Starting Production Wallet Backfill Script...');

        // 1. Find users needing backfill
        logger.log('🔍 Finding users with completed onboarding but NO wallet...');
        const users = await userRepository.find({
            where: {
                isOnboardingCompleted: true,
                intasendWalletId: IsNull(),
            },
        });

        logger.log(`Found ${users.length} users to process.`);

        if (users.length === 0) {
            logger.log('✅ No users need backfilling. Exiting.');
            return;
        }

        let successCount = 0;
        let failCount = 0;

        // 2. Process each user
        for (const [index, user] of users.entries()) {
            const userName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'Unknown Name';
            logger.log(
                `[${index + 1}/${users.length}] Processing user: ${user.email} (${userName}) - ID: ${user.id}`,
            );

            try {
                // Generate a label (e.g., WALLET-12345678)
                const walletLabel = `WALLET-${user.id.substring(0, 8).toUpperCase()}`;

                // Create Wallet in IntaSend
                logger.log(`   creating wallet with label: ${walletLabel}...`);
                const wallet = await intaSendService.createWallet(
                    'KES',
                    walletLabel,
                    true,
                );

                if (wallet && wallet.wallet_id) {
                    // Update User Record
                    user.intasendWalletId = wallet.wallet_id;
                    await userRepository.save(user);
                    logger.log(`   ✅ Wallet created and saved: ${wallet.wallet_id}`);
                    successCount++;
                } else {
                    logger.error(
                        `   ❌ Wallet creation response invalid for user ${user.id}: ${JSON.stringify(wallet)}`,
                    );
                    failCount++;
                }
            } catch (error: any) {
                logger.error(
                    `   ❌ Failed to process user ${user.id}: ${error.message}`,
                    error.stack,
                );
                failCount++;
            }

            // Rate Limiting: Sleep 500ms between requests to be nice to IntaSend API
            await new Promise((resolve) => setTimeout(resolve, 500));
        }

        logger.log('🎉 Backfill completed.');
        logger.log(`Summary: ${successCount} Success, ${failCount} Failed.`);
    } catch (error) {
        logger.error('🔥 Script failed with fatal error', error);
        process.exit(1);
    } finally {
        await app.close();
    }
}

bootstrap();
