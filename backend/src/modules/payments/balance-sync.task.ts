import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, IsNull } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { IntaSendService } from './intasend.service';

@Injectable()
export class BalanceSyncTask {
  private readonly logger = new Logger(BalanceSyncTask.name);

  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    private readonly intaSendService: IntaSendService,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async syncBalances() {
    this.logger.log('Starting scheduled wallet balance synchronization...');

    const users = await this.usersRepository.find({
      where: { intasendWalletId: Not(IsNull()) },
      select: ['id', 'email', 'walletBalance', 'intasendWalletId'],
    });

    this.logger.log(`Found ${users.length} users with IntaSend wallets.`);

    for (const user of users) {
      try {
        const walletInfo = await this.intaSendService.getWalletBalance(
          user.intasendWalletId,
        );

        // IntaSend returns { available_balance: number, ... }
        // Ensure we match the response structure from intasend.service.ts
        const realBalance = Number(walletInfo.available_balance);
        const localBalance = Number(user.walletBalance);

        if (isNaN(realBalance)) {
          this.logger.warn(`Invalid balance returned for user ${user.email}`);
          continue;
        }

        const diff = Math.abs(realBalance - localBalance);

        if (diff > 10) {
          // Tolerate small differences, log significant drift
          this.logger.warn(
            `Balance Drift Detected for ${user.email}: Local=${localBalance}, Real=${realBalance}, Diff=${diff}`,
          );

          // Update Local Balance
          await this.usersRepository.update(user.id, {
            walletBalance: realBalance,
          });

          this.logger.log(`Synced balance for ${user.email}`);
        }
      } catch (error) {
        this.logger.error(
          `Failed to sync balance for user ${user.email}`,
          error,
        );
      }
    }

    this.logger.log('Completed wallet balance synchronization.');
  }
}
