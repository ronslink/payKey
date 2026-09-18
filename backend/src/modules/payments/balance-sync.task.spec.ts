import { Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { BalanceSyncTask } from './balance-sync.task';
import { IntaSendService } from './intasend.service';

describe('BalanceSyncTask ledger protection', () => {
  afterEach(() => jest.restoreAllMocks());

  it('preserves a wallet credit absent from IntaSend and reports the discrepancy', async () => {
    // The ledger includes KES 10,000 received through another provider, while
    // IntaSend reports only the KES 5,000 held in its own working wallet.
    const ledger = {
      id: 'employer-with-stripe-credit',
      walletBalance: 15000,
      intasendWalletId: 'intasend-working-wallet',
    };
    const repository = {
      find: jest.fn().mockResolvedValue([{ ...ledger }]),
      update: jest.fn((_id: string, changes: Partial<User>) => {
        Object.assign(ledger, changes);
        return Promise.resolve({ affected: 1 });
      }),
    };
    const provider = {
      getWalletBalance: jest
        .fn()
        .mockResolvedValue({ available_balance: 5000 }),
    };
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    const task = new BalanceSyncTask(
      repository as unknown as Repository<User>,
      provider as unknown as IntaSendService,
    );

    await task.syncBalances();

    expect(provider.getWalletBalance).toHaveBeenCalledWith(
      ledger.intasendWalletId,
    );
    expect(ledger.walletBalance).toBe(15000);
    expect(repository.update).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining(ledger.id));
  });
});
