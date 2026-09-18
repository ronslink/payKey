import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import nock from 'nock';
import Stripe from 'stripe';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { registerRequestBodyParsers } from '../src/common/http/request-body';
import { ExchangeRateService } from '../src/modules/payments/exchange-rate.service';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../src/modules/payments/entities/transaction.entity';
import { User } from '../src/modules/users/entities/user.entity';
import { createTestHelpers, TestUserResult } from './helpers/test-helpers';

// Keep the real Stripe SDK/signature verification. Fetch supports nock on Node 24.
jest.mock('stripe', () => {
  const ActualStripe =
    jest.requireActual<typeof import('stripe')>('stripe').default;
  return {
    __esModule: true,
    default: class FixtureStripe extends ActualStripe {
      constructor(key: string, config?: Stripe.StripeConfig) {
        super(key, {
          ...config,
          httpClient: ActualStripe.createFetchHttpClient(),
          timeout: 5000,
          maxNetworkRetries: 0,
        });
      }
    },
  };
});

describe('Stripe wallet funding and settlement', () => {
  const secret = 'whsec_wallet_settlement_e2e_only';
  const signer = new Stripe('sk_test_wallet_settlement_e2e_only');
  const originalKey = process.env.STRIPE_SECRET_KEY;
  const originalPublicKey = process.env.STRIPE_PUBLISHABLE_KEY;
  const originalWalletFunding = process.env.STRIPE_WALLET_FUNDING_ENABLED;
  const publicKey = 'pk_test_walletsettlemente2eonly';
  const originalSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const rates = { getLatestRate: jest.fn<Promise<number>, [string, string]>() };
  let app: INestApplication;
  let database: DataSource;
  let owner: TestUserResult;
  let other: TestUserResult;
  let currentIntent: Stripe.PaymentIntent;
  let eventSequence = 0;

  beforeAll(async () => {
    process.env.STRIPE_SECRET_KEY = 'sk_test_wallet_settlement_e2e_only';
    process.env.STRIPE_PUBLISHABLE_KEY = publicKey;
    process.env.STRIPE_WEBHOOK_SECRET = secret;
    rates.getLatestRate.mockResolvedValue(150);
    nock('https://api.stripe.com')
      .persist()
      .get(/\/v1\/payment_intents\/pi_wallet_/)
      .reply(() => [200, currentIntent]);
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(ExchangeRateService)
      .useValue(rates)
      .compile();
    app = module.createNestApplication({ bodyParser: false });
    registerRequestBodyParsers(app);
    await app.init();
    database = app.get(DataSource);
    expect(database.options.type).toBe('postgres');
    expect(String(database.options.database)).toMatch(/_test$/);
    const helpers = createTestHelpers(app);
    owner = await helpers.createTestUser({
      emailPrefix: 'stripe.wallet.owner',
    });
    other = await helpers.createTestUser({
      emailPrefix: 'stripe.wallet.other',
    });
  });

  afterAll(async () => {
    await app?.close();
    nock.cleanAll();
    if (originalKey === undefined) delete process.env.STRIPE_SECRET_KEY;
    else process.env.STRIPE_SECRET_KEY = originalKey;
    if (originalPublicKey === undefined)
      delete process.env.STRIPE_PUBLISHABLE_KEY;
    else process.env.STRIPE_PUBLISHABLE_KEY = originalPublicKey;
    if (originalSecret === undefined) delete process.env.STRIPE_WEBHOOK_SECRET;
    else process.env.STRIPE_WEBHOOK_SECRET = originalSecret;
    if (originalWalletFunding === undefined)
      delete process.env.STRIPE_WALLET_FUNDING_ENABLED;
    else process.env.STRIPE_WALLET_FUNDING_ENABLED = originalWalletFunding;
  });

  beforeEach(async () => {
    process.env.STRIPE_WALLET_FUNDING_ENABLED = 'true';
    // Keep the real request limiter. Each distinct scenario gets a fresh second.
    await new Promise((resolve) => setTimeout(resolve, 1100));
  });

  function callback(intent: Stripe.PaymentIntent) {
    const payload = JSON.stringify({
      id: `evt_wallet_${++eventSequence}`,
      object: 'event',
      type: 'payment_intent.succeeded',
      data: { object: intent },
    });
    return request(app.getHttpServer())
      .post('/payments/subscriptions/webhook')
      .set('Content-Type', 'application/json')
      .set(
        'stripe-signature',
        signer.webhooks.generateTestHeaderString({ payload, secret }),
      )
      .send(payload);
  }

  function createFunding(body: object) {
    return request(app.getHttpServer())
      .post('/payments/unified/stripe/create-intent')
      .set('Authorization', `Bearer ${owner.token}`)
      .send({ paymentMethodTypes: ['card'], ...body });
  }

  async function balance(userId: string) {
    const user = await database
      .getRepository(User)
      .findOneByOrFail({ id: userId });
    return Number(user.walletBalance);
  }

  async function walletPayment(suffix: string) {
    const payment = await database.getRepository(Transaction).save({
      userId: owner.userId,
      amount: 10,
      currency: 'EUR',
      type: TransactionType.DEPOSIT,
      status: TransactionStatus.PENDING,
      provider: 'STRIPE',
      providerRef: `pi_wallet_${suffix}`,
    });
    const intent = {
      id: payment.providerRef,
      object: 'payment_intent',
      status: 'succeeded',
      currency: 'eur',
      amount: 1000,
      amount_received: 1000,
      metadata: {
        type: 'WALLET_TOPUP',
        userId: owner.userId,
        transactionId: payment.id,
      },
    } as Stripe.PaymentIntent;
    return { payment, intent };
  }

  it('blocks KES and EUR card top-ups without a Stripe intent or pending transaction when funding is disabled or unset', async () => {
    const transactions = database.getRepository(Transaction);
    const countBefore = await transactions.countBy({ userId: owner.userId });
    const balanceBefore = await balance(owner.userId);
    const interceptor = nock('https://api.stripe.com').post(
      '/v1/payment_intents',
    );
    const provider = interceptor.reply(200, {
      id: 'pi_wallet_must_not_be_created',
      client_secret: 'pi_wallet_must_not_be_created_secret_fixture',
    });
    try {
      for (const enabled of [undefined, 'false']) {
        if (enabled === undefined)
          delete process.env.STRIPE_WALLET_FUNDING_ENABLED;
        else process.env.STRIPE_WALLET_FUNDING_ENABLED = enabled;
        for (const currency of ['KES', 'EUR']) {
          const response = await createFunding({
            amount: 1000,
            currency,
          }).expect(400);
          expect(response.body.message).toBe(
            'Card wallet top-ups are currently unavailable. Please use M-Pesa.',
          );
        }
      }
      expect(provider.isDone()).toBe(false);
      expect(await transactions.countBy({ userId: owner.userId })).toBe(
        countBefore,
      );
      expect(await balance(owner.userId)).toBe(balanceBefore);
    } finally {
      nock.removeInterceptor(interceptor);
    }
  });

  it('requires explicit currency, card method and EUR conversion before creating an exact-cent intent', async () => {
    const transactions = database.getRepository(Transaction);
    const countBefore = await transactions.countBy({ userId: owner.userId });
    const create = createFunding;
    for (const body of [
      { amount: 10 },
      { amount: 10, currency: 'JPY' },
      { amount: 10, currency: 'USD' },
      { amount: 10, currency: 'EUR', paymentMethodTypes: undefined },
      { amount: 10, currency: 'EUR', paymentMethodTypes: ['sepa_debit'] },
      { amount: 10, currency: 'EUR', paymentMethodTypes: [] },
      {
        amount: 10,
        currency: 'EUR',
        paymentMethodTypes: ['card', 'sepa_debit'],
      },
      { amount: 10.001, currency: 'EUR' },
    ]) {
      await create(body).expect(400);
    }
    for (const key of ['', 'pk_live_walletsettlemente2eonly']) {
      process.env.STRIPE_PUBLISHABLE_KEY = key;
      await create({ amount: 12.34, currency: 'EUR' }).expect(400);
    }
    process.env.STRIPE_PUBLISHABLE_KEY = publicKey;
    await new Promise((resolve) => setTimeout(resolve, 1100));
    rates.getLatestRate.mockRejectedValue(new Error('Rate unavailable'));
    await create({ amount: 12.34, currency: 'EUR' }).expect(400);
    for (const rate of [0, -1, Number.NaN, Number.POSITIVE_INFINITY]) {
      rates.getLatestRate.mockResolvedValue(rate);
      await create({ amount: 12.34, currency: 'EUR' }).expect(400);
    }
    expect(await transactions.countBy({ userId: owner.userId })).toBe(
      countBefore,
    );
    let sent: Record<string, string> = {};
    const provider = nock('https://api.stripe.com')
      .post('/v1/payment_intents')
      .reply((_uri, body) => {
        sent =
          typeof body === 'string'
            ? Object.fromEntries(new URLSearchParams(body))
            : (body as Record<string, string>);
        return [
          200,
          {
            id: 'pi_wallet_created',
            client_secret: 'pi_wallet_created_secret_fixture',
          },
        ];
      });
    rates.getLatestRate.mockResolvedValue(150);
    const result = await create({ amount: 12.34, currency: 'EUR' }).expect(201);
    expect(result.body.publishableKey).toBe(publicKey);
    expect(
      Object.keys(result.body).sort((left, right) => left.localeCompare(right)),
    ).toEqual(['clientSecret', 'publishableKey', 'success', 'transactionId']);
    expect(provider.isDone()).toBe(true);
    expect(sent).toMatchObject({
      amount: '1234',
      currency: 'eur',
      'payment_method_types[0]': 'card',
      confirm: 'false',
      'metadata[userId]': owner.userId,
    });
    const stored = await transactions.findOneByOrFail({
      id: result.body.transactionId as string,
    });
    expect(stored).toMatchObject({
      currency: 'EUR',
      providerRef: 'pi_wallet_created',
      status: TransactionStatus.PENDING,
    });
    expect(Math.round(Number(stored.amount) * 100)).toBe(1234);
    expect(await balance(owner.userId)).toBe(0);
  });

  it('lets Stripe enforce the KES minimum before writing and credits KES cards once without FX', async () => {
    const transactions = database.getRepository(Transaction);
    const countBefore = await transactions.countBy({ userId: owner.userId });
    const balanceBefore = await balance(owner.userId);
    rates.getLatestRate
      .mockClear()
      .mockRejectedValue(new Error('No FX available'));
    const minimumRejection = nock('https://api.stripe.com')
      .post('/v1/payment_intents')
      .reply(400, {
        error: {
          type: 'invalid_request_error',
          code: 'amount_too_small',
          message: 'Amount is below the account minimum.',
        },
      });
    await createFunding({ amount: 1, currency: 'KES' }).expect(400);
    expect(minimumRejection.isDone()).toBe(true);
    expect(await transactions.countBy({ userId: owner.userId })).toBe(
      countBefore,
    );
    expect(await balance(owner.userId)).toBe(balanceBefore);

    let sent: Record<string, string> = {};
    const provider = nock('https://api.stripe.com')
      .post('/v1/payment_intents')
      .reply((_uri, body) => {
        sent =
          typeof body === 'string'
            ? Object.fromEntries(new URLSearchParams(body))
            : (body as Record<string, string>);
        return [
          200,
          {
            id: 'pi_wallet_kes',
            client_secret: 'pi_wallet_kes_secret_fixture',
          },
        ];
      });
    const result = await createFunding({
      amount: 1000,
      currency: 'KES',
    }).expect(201);
    expect(provider.isDone()).toBe(true);
    expect(sent).toMatchObject({
      amount: '100000',
      currency: 'kes',
      'payment_method_types[0]': 'card',
      confirm: 'false',
    });
    const stored = await transactions.findOneByOrFail({
      id: result.body.transactionId as string,
    });
    expect(stored).toMatchObject({
      currency: 'KES',
      providerRef: 'pi_wallet_kes',
      status: TransactionStatus.PENDING,
    });
    expect(Number(stored.amount)).toBe(1000);
    currentIntent = {
      id: 'pi_wallet_kes',
      object: 'payment_intent',
      status: 'succeeded',
      currency: 'kes',
      amount: 100000,
      amount_received: 100000,
      metadata: {
        type: 'WALLET_TOPUP',
        transactionId: stored.id,
        userId: owner.userId,
      },
    } as Stripe.PaymentIntent;
    await Promise.all([
      callback(currentIntent).expect(201),
      callback(currentIntent).expect(201),
      callback(currentIntent).expect(201),
    ]);
    expect(await balance(owner.userId)).toBe(balanceBefore + 1000);
    expect(await balance(other.userId)).toBe(0);
    expect(
      (await transactions.findOneByOrFail({ id: stored.id })).metadata
        .fxApplied,
    ).toEqual({
      sourceAmount: 1000,
      sourceCurrency: 'KES',
      targetCurrency: 'KES',
      rate: 1,
      creditedAmount: 1000,
    });
    expect(rates.getLatestRate).not.toHaveBeenCalled();
  });

  it('settles an existing payment with funding disabled, keeps invalid FX retryable and credits concurrent callbacks once', async () => {
    process.env.STRIPE_WALLET_FUNDING_ENABLED = 'false';
    const { payment, intent } = await walletPayment('retry');
    currentIntent = intent;
    const transactions = database.getRepository(Transaction);
    const balanceBefore = await balance(owner.userId);
    rates.getLatestRate.mockRejectedValue(new Error('Rate unavailable'));
    await callback(intent).expect(401);
    for (const rate of [0, -1, Number.NaN, Number.POSITIVE_INFINITY]) {
      rates.getLatestRate.mockResolvedValue(rate);
      await callback(intent).expect(401);
      expect(
        (await transactions.findOneByOrFail({ id: payment.id })).status,
      ).toBe(TransactionStatus.PENDING);
      expect(await balance(owner.userId)).toBe(balanceBefore);
    }
    rates.getLatestRate.mockResolvedValue(150);
    await Promise.all([
      callback(intent).expect(201),
      callback(intent).expect(201),
      callback(intent).expect(201),
    ]);
    expect(await balance(owner.userId)).toBe(balanceBefore + 1500);
    expect(await balance(other.userId)).toBe(0);
    const settled = await transactions.findOneByOrFail({ id: payment.id });
    expect(settled.status).toBe(TransactionStatus.SUCCESS);
    expect(settled.metadata.fxApplied).toEqual({
      sourceAmount: 10,
      sourceCurrency: 'EUR',
      targetCurrency: 'KES',
      rate: 150,
      creditedAmount: 1500,
    });
  });

  it('rejects a different, unpaid or mismatched provider payment without funding either account', async () => {
    const { payment, intent } = await walletPayment('mismatch');
    const transactions = database.getRepository(Transaction);
    const before = await balance(owner.userId);
    const changes: Partial<Stripe.PaymentIntent>[] = [
      { id: 'pi_wallet_wrong' },
      { status: 'processing' },
      { currency: 'usd' },
      { amount: 999 },
      { amount_received: 999 },
      { metadata: { ...intent.metadata, userId: other.userId } },
      {
        metadata: { ...intent.metadata, transactionId: 'another-transaction' },
      },
      { metadata: { ...intent.metadata, type: 'OTHER_PAYMENT' } },
    ];
    for (const change of changes) {
      currentIntent = { ...intent, ...change };
      await callback(intent).expect(401);
      expect(
        (await transactions.findOneByOrFail({ id: payment.id })).status,
      ).toBe(TransactionStatus.PENDING);
      expect(await balance(owner.userId)).toBe(before);
      expect(await balance(other.userId)).toBe(0);
    }
    currentIntent = intent;
    await new Promise((resolve) => setTimeout(resolve, 1100));
    await transactions.update(payment.id, { provider: 'INTASEND' });
    await callback(intent).expect(401);
    await transactions.update(payment.id, {
      provider: 'STRIPE',
      type: TransactionType.SALARY_PAYOUT,
    });
    await callback(intent).expect(401);
    await transactions.update(payment.id, {
      type: TransactionType.DEPOSIT,
      providerRef: 'pi_wallet_another',
    });
    await callback(intent).expect(401);
    expect(
      (await transactions.findOneByOrFail({ id: payment.id })).status,
    ).toBe(TransactionStatus.PENDING);
    expect(await balance(owner.userId)).toBe(before);
    expect(await balance(other.userId)).toBe(0);
  });
});
