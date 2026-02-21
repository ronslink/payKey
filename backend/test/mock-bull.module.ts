import { Module, Global } from '@nestjs/common';
import { getQueueToken } from '@nestjs/bullmq';

@Global()
@Module({
  providers: [
    {
      provide: getQueueToken('subscriptions'),
      useValue: {
        add: jest.fn(),
        process: jest.fn(),
        on: jest.fn(),
      },
    },
    {
      provide: getQueueToken('payroll-processing'),
      useValue: {
        add: jest.fn(),
        process: jest.fn(),
        on: jest.fn(),
      },
    },
    {
      provide: getQueueToken('wallets'),
      useValue: {
        add: jest.fn(),
        process: jest.fn(),
        on: jest.fn(),
      },
    },
  ],
  exports: [
    getQueueToken('subscriptions'),
    getQueueToken('payroll-processing'),
    getQueueToken('wallets'),
  ],
})
export class MockBullModule {}
