import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { IntaSendService } from './intasend.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';

export interface WalletCreationJobData {
    userId: string;
    label: string;
}

@Processor('wallets')
export class WalletProcessor extends WorkerHost {
    private readonly logger = new Logger(WalletProcessor.name);

    constructor(
        private readonly intaSendService: IntaSendService,
        @InjectRepository(User)
        private readonly usersRepository: Repository<User>,
    ) {
        super();
    }

    async process(job: Job<WalletCreationJobData>): Promise<any> {
        this.logger.log(
            `Processing wallet creation job ${job.id} for user ${job.data.userId}`,
        );

        try {
            // Check if user already has a wallet (idempotency)
            const user = await this.usersRepository.findOne({
                where: { id: job.data.userId },
                select: ['id', 'intasendWalletId'],
            });

            if (!user) {
                this.logger.warn(`User ${job.data.userId} not found, skipping job`);
                return { status: 'skipped', reason: 'user_not_found' };
            }

            if (user.intasendWalletId) {
                this.logger.log(
                    `User ${job.data.userId} already has wallet ${user.intasendWalletId}, skipping`,
                );
                return { status: 'skipped', reason: 'wallet_exists' };
            }

            // Create wallet via IntaSend
            const walletResponse = await this.intaSendService.createWallet(
                job.data.label,
            );

            const walletId = (walletResponse as { wallet_id?: string })?.wallet_id;
            if (!walletId) {
                throw new Error('IntaSend did not return a wallet_id');
            }

            // Save wallet ID to user
            await this.usersRepository.update(job.data.userId, {
                intasendWalletId: walletId,
            });

            this.logger.log(`Wallet ${walletId} created for user ${job.data.userId}`);

            return {
                status: 'success',
                walletId: walletId,
            };
        } catch (error) {
            const errorMessage =
                error instanceof Error ? error.message : 'Unknown error';
            this.logger.error(
                `Wallet creation job ${job.id} failed: ${errorMessage}`,
            );
            throw error; // Let BullMQ handle retries
        }
    }
}
