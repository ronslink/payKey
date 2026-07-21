import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from './../src/app.module';
import { IntaSendService } from '../src/modules/payments/intasend.service';
import { createTestHelpers, TestHelpers } from './helpers/test-helpers';
import { cleanupTestData } from './test-utils';
import {
  RateType,
  TaxConfig,
  TaxType,
} from '../src/modules/tax-config/entities/tax-config.entity';
import { User } from '../src/modules/users/entities/user.entity';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../src/modules/payments/entities/transaction.entity';
import {
  PayrollRecord,
  PayrollStatus,
} from '../src/modules/payroll/entities/payroll-record.entity';
import {
  PayPeriod,
  PayPeriodStatus,
} from '../src/modules/payroll/entities/pay-period.entity';

const waitFor = async <T>(
  fn: () => Promise<T | null | undefined>,
  timeoutMs = 6000,
): Promise<T> => {
  const start = Date.now();
  let last: T | null | undefined;

  while (Date.now() - start < timeoutMs) {
    last = await fn();
    if (last) return last;
    await new Promise((resolve) => setTimeout(resolve, 150));
  }

  throw new Error(`Timed out waiting for condition. Last value: ${last}`);
};

describe('Wallet Top-up to Payroll Payout Production Flow E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let dataSource: DataSource;
  let originalNodeEnv: string | undefined;

  const intaSendMock = {
    createWallet: jest.fn().mockResolvedValue({
      wallet_id: 'sandbox-wallet-production-flow',
    }),
    createCheckoutUrl: jest.fn().mockResolvedValue({
      id: 'sandbox-topup-checkout',
      url: 'https://sandbox.intasend.com/checkout/topup-test/express/',
      signature: 'sandbox-topup-signature',
    }),
    sendMoney: jest.fn().mockResolvedValue({
      tracking_id: 'sandbox-b2c-tracking-production-flow',
      status: 'Processing',
    }),
    verifyWebhookSignature: jest.fn().mockReturnValue(true),
    getPayoutStatus: jest.fn().mockResolvedValue({ status: 'COMPLETE' }),
    getWalletBalance: jest.fn().mockResolvedValue({ available_balance: 0 }),
  };

  beforeAll(async () => {
    originalNodeEnv = process.env.NODE_ENV;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(IntaSendService)
      .useValue(intaSendMock)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    helpers = createTestHelpers(app);
    dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);
    await dataSource.getRepository(TaxConfig).save([
      {
        taxType: TaxType.SHIF,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-01-01'),
        configuration: { percentage: 2.75, minAmount: 300 },
        isActive: true,
      },
      {
        taxType: TaxType.HOUSING_LEVY,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-01-01'),
        configuration: { percentage: 1.5 },
        isActive: true,
      },
      {
        taxType: TaxType.NSSF_TIER1,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          tiers: [{ name: 'Tier 1', salaryFrom: 0, salaryTo: 7000, rate: 0.06 }],
        },
        isActive: true,
      },
      {
        taxType: TaxType.NSSF_TIER2,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          tiers: [
            { name: 'Tier 2', salaryFrom: 7001, salaryTo: 36000, rate: 0.06 },
          ],
        },
        isActive: true,
      },
      {
        taxType: TaxType.PAYE,
        rateType: RateType.GRADUATED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          brackets: [
            { from: 0, to: 24000, rate: 0.1 },
            { from: 24001, to: 32333, rate: 0.25 },
            { from: 32334, to: 500000, rate: 0.3 },
          ],
          personalRelief: 2400,
        },
        isActive: true,
      },
    ]);
  });

  afterAll(async () => {
    process.env.NODE_ENV = originalNodeEnv;
    if (dataSource) {
      await cleanupTestData(dataSource);
    }
    if (app) {
      await app.close();
    }
  });

  it('credits a confirmed IntaSend top-up, then pays payroll only after B2C webhook confirmation', async () => {
    const topupAmount = 10000;
    const user = await helpers.createTestUser({
      emailPrefix: 'prod.flow',
      businessName: 'Prod Flow Ltd',
    });

    await dataSource
      .getRepository(User)
      .update(user.userId, { tier: 'BASIC' as any });

    const topupRes = await request(app.getHttpServer())
      .post('/payments/unified/checkout/topup')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ amount: topupAmount })
      .expect(201);

    expect(topupRes.body.url).toContain('sandbox.intasend.com/checkout');
    expect(intaSendMock.createWallet).toHaveBeenCalled();
    expect(intaSendMock.createCheckoutUrl).toHaveBeenCalledWith(
      topupAmount,
      user.email,
      expect.any(String),
      expect.any(String),
      expect.any(String),
      'sandbox-wallet-production-flow',
    );

    const depositTx = await dataSource.getRepository(Transaction).findOneByOrFail({
      userId: user.userId,
      type: TransactionType.DEPOSIT,
    });

    await request(app.getHttpServer())
      .post('/webhooks/intasend')
      .set('X-IntaSend-Signature', 'test-signature')
      .send({
        invoice_id: 'sandbox-topup-checkout',
        api_ref: depositTx.id,
        state: 'COMPLETE',
        provider: 'CARD-PAYMENT',
        currency: 'KES',
        value: topupAmount,
      })
      .expect(201);

    const creditedUser = await dataSource.getRepository(User).findOneByOrFail({
      id: user.userId,
    });
    expect(Number(creditedUser.walletBalance)).toBe(topupAmount);

    await helpers.createTestWorker(user.token, {
      name: 'Production Flow Worker',
      phoneNumber: '+254712345678',
      salaryGross: 5000,
      paymentMethod: 'MPESA',
      mpesaNumber: '+254712345678',
    });

    const payPeriods = await helpers.generatePayPeriods(user.token, 2024);
    const payPeriodId = payPeriods[0].id;

    await request(app.getHttpServer())
      .post(`/pay-periods/${payPeriodId}/activate`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);

    const calcRes = await request(app.getHttpServer())
      .get('/payroll/calculate')
      .set('Authorization', `Bearer ${user.token}`)
      .expect(200);

    await request(app.getHttpServer())
      .post('/payroll/draft')
      .set('Authorization', `Bearer ${user.token}`)
      .send({
        payPeriodId,
        payrollItems: calcRes.body.payrollItems,
      })
      .expect(201);

    process.env.NODE_ENV = 'production';

    await request(app.getHttpServer())
      .post(`/payroll/finalize/${payPeriodId}`)
      .set('Authorization', `Bearer ${user.token}`)
      .expect(201);

    const salaryTx = await waitFor(async () =>
      dataSource.getRepository(Transaction).findOne({
        where: {
          userId: user.userId,
          type: TransactionType.SALARY_PAYOUT,
        },
      }),
    );

    expect(salaryTx.status).toBe(TransactionStatus.PENDING);
    expect(salaryTx.providerRef).toBe('sandbox-b2c-tracking-production-flow');
    expect(salaryTx.walletId).toBe('sandbox-wallet-production-flow');

    const processingRecord = await dataSource
      .getRepository(PayrollRecord)
      .findOneByOrFail({
        userId: user.userId,
        status: PayrollStatus.FINALIZED,
      });
    expect(processingRecord.paymentStatus).toBe('processing');

    const userAfterDeduction = await dataSource
      .getRepository(User)
      .findOneByOrFail({ id: user.userId });
    expect(Number(userAfterDeduction.walletBalance)).toBeLessThan(topupAmount);

    await request(app.getHttpServer())
      .post('/webhooks/intasend')
      .set('X-IntaSend-Signature', 'test-signature')
      .send({
        tracking_id: 'sandbox-b2c-tracking-production-flow',
        status: 'COMPLETE',
        provider: 'MPESA-B2C',
        currency: 'KES',
        value: salaryTx.amount,
        transactions: [
          {
            account: salaryTx.accountReference,
            status: 'COMPLETE',
            provider: 'MPESA-B2C',
          },
        ],
      })
      .expect(201);

    const paidRecord = await dataSource.getRepository(PayrollRecord).findOneByOrFail({
      id: processingRecord.id,
    });
    const completedSalaryTx = await dataSource
      .getRepository(Transaction)
      .findOneByOrFail({ id: salaryTx.id });

    expect(paidRecord.paymentStatus).toBe('paid');
    expect(completedSalaryTx.status).toBe(TransactionStatus.SUCCESS);

    const period = await dataSource.getRepository(PayPeriod).findOneByOrFail({
      id: payPeriodId,
    });
    expect(period.status).toBe(PayPeriodStatus.COMPLETED);
  });
});
