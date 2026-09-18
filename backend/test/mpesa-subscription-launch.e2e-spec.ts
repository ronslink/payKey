import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Job } from 'bullmq';
import { DataSource } from 'typeorm';
import nock from 'nock';
import request from 'supertest';
import Stripe from 'stripe';
import { AppModule } from '../src/app.module';
import { registerRequestBodyParsers } from '../src/common/http/request-body';
import { IntaSendService } from '../src/modules/payments/intasend.service';
import { Transaction } from '../src/modules/payments/entities/transaction.entity';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../src/modules/subscriptions/entities/subscription.entity';
import { SubscriptionPayment } from '../src/modules/subscriptions/entities/subscription-payment.entity';
import { SubscriptionProcessor } from '../src/modules/subscriptions/subscription.processor';
import { User } from '../src/modules/users/entities/user.entity';
import { createTestHelpers, TestUserResult } from './helpers/test-helpers';

// Retain the real Stripe SDK while keeping all provider HTTP behind fixtures.
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

describe('M-Pesa subscription purchase and customer-approved renewal', () => {
  let app: INestApplication;
  let database: DataSource;
  let owner: TestUserResult;
  let other: TestUserResult;
  let sequence = 0;
  let stripeLookups = 0;
  let rejectInitiation = false;
  let loseInitiationResponse = false;
  const challenge = 'mpesa-subscriptions-test-only';
  const invoices = new Map<
    string,
    {
      invoice_id: string;
      api_ref: string;
      state: string;
      currency: string;
      value: number;
    }
  >();
  const previousEnvironment = new Map<string, string | undefined>();
  const pause = () => new Promise((resolve) => setTimeout(resolve, 1100));

  beforeAll(async () => {
    for (const [key, value] of Object.entries({
      INTASEND_SIMULATE: 'false',
      INTASEND_DISABLE_SIG_CHECK: 'false',
      INTASEND_CHALLENGE: challenge,
      STRIPE_SECRET_KEY: 'sk_test_mpesa_subscription_fixture',
    })) {
      previousEnvironment.set(key, process.env[key]);
      process.env[key] = value;
    }
    nock('https://api.stripe.com')
      .persist()
      .get('/v1/customers')
      .query(true)
      .reply(() => {
        stripeLookups += 1;
        return [200, { object: 'list', data: [], has_more: false }];
      });
    nock('https://sandbox.intasend.com')
      .persist()
      .post('/api/v1/payment/mpesa-stk-push/')
      .reply((_uri, body: Record<string, unknown>) => {
        if (rejectInitiation)
          return [400, { detail: 'Fixture provider unavailable' }];
        const invoice = {
          invoice_id: `mpesa-sub-${++sequence}`,
          api_ref: String(body.api_ref),
          value: Number(body.amount),
          currency: String(body.currency),
          state: 'PENDING',
        };
        invoices.set(invoice.invoice_id, invoice);
        if (loseInitiationResponse)
          return [504, { detail: 'Fixture response lost after acceptance' }];
        return [200, { invoice }];
      });
    nock('https://sandbox.intasend.com')
      .persist()
      .post('/api/v1/payment/status/')
      .reply((_uri, body: Record<string, unknown>) => {
        const invoice = invoices.get(String(body.invoice_id));
        return invoice ? [200, { invoice }] : [404, {}];
      });
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication({ bodyParser: false });
    registerRequestBodyParsers(app);
    await app.init();
    // Account creation is incidental; payment initiation, signature/challenge
    // checking and invoice retrieval retain the real service and HTTP adapter.
    jest
      .spyOn(app.get(IntaSendService), 'createWallet')
      .mockResolvedValue({ wallet_id: 'test-wallet' });
    database = app.get(DataSource);
    expect(database.options.type).toBe('postgres');
    expect(String(database.options.database)).toMatch(/_test$/);
    const helpers = createTestHelpers(app);
    owner = await helpers.createTestUser({ emailPrefix: 'mpesa.owner' });
    other = await helpers.createTestUser({ emailPrefix: 'mpesa.other' });
  });

  afterAll(async () => {
    await app?.close();
    nock.cleanAll();
    for (const [key, value] of previousEnvironment) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });
  beforeEach(pause);

  function post(user: TestUserResult, path: string, body: object) {
    return request(app.getHttpServer())
      .post(`/subscriptions/${path}`)
      .set('Authorization', `Bearer ${user.token}`)
      .send(body);
  }
  function get(user: TestUserResult, path: string) {
    return request(app.getHttpServer())
      .get(`/subscriptions/${path}`)
      .set('Authorization', `Bearer ${user.token}`);
  }
  function subscribe(
    user: TestUserResult,
    amount = 1300,
    billingPeriod = 'monthly',
  ) {
    return post(user, 'mpesa-subscribe', {
      planId: 'BASIC',
      billingPeriod,
      phoneNumber: '0712345678',
      expectedAmount: amount,
    });
  }
  function callback(
    invoiceId: string,
    reference?: string,
    callbackChallenge = challenge,
  ) {
    return request(app.getHttpServer())
      .post('/webhooks/intasend')
      .send({
        invoice_id: invoiceId,
        api_ref: reference || invoices.get(invoiceId)?.api_ref,
        state: 'COMPLETE',
        value: 0.01,
        currency: 'USD',
        challenge: callbackChallenge,
      });
  }
  async function receipt(paymentId: string) {
    return database
      .getRepository(SubscriptionPayment)
      .findOneByOrFail({ id: paymentId });
  }
  async function subscription(paymentId: string) {
    return database
      .getRepository(Subscription)
      .findOneByOrFail({ id: (await receipt(paymentId)).subscriptionId });
  }

  it('quotes exact KES, isolates two same-tier customers and grants the paid month/year only after matching provider verification', async () => {
    const quote = await post(owner, 'mpesa-quote', {
      planId: 'BASIC',
      billingPeriod: 'monthly',
    }).expect(201);
    expect(quote.body).toMatchObject({
      amount: 1300,
      currency: 'KES',
      renewalMode: 'manual',
    });
    await post(owner, 'mpesa-subscribe', {
      planId: 'BASIC',
      phoneNumber: '0712345678',
    }).expect(400);
    await subscribe(owner, 1299).expect(400);
    expect(sequence).toBe(0);
    const first = await subscribe(owner).expect(201);
    const second = await subscribe(other, 13000, 'yearly').expect(201);
    const a = await receipt(first.body.paymentId);
    const b = await receipt(second.body.paymentId);
    expect(a.metadata.reference).not.toBe(b.metadata.reference);
    expect(b.billingPeriod).toBe('yearly');
    expect(b.periodEnd.getTime() - b.periodStart.getTime()).toBeGreaterThan(
      364 * 86400000,
    );
    expect((await subscribe(owner).expect(201)).body.paymentId).toBe(a.id);
    expect(sequence).toBe(2);
    const lookupsBefore = stripeLookups;
    const competing = await post(owner, 'subscribe', {
      planId: 'BASIC',
      paymentMethod: 'STRIPE',
      billingPeriod: 'monthly',
    }).expect(400);
    expect(competing.body.message).toContain(
      'subscription payment is still pending',
    );
    const bankInitiation = jest.spyOn(
      app.get(IntaSendService),
      'createCheckoutUrl',
    );
    try {
      await post(owner, 'subscribe', {
        planId: 'BASIC',
        paymentMethod: 'BANK',
        billingPeriod: 'monthly',
      }).expect(400);
      expect(bankInitiation).not.toHaveBeenCalled();
    } finally {
      bankInitiation.mockRestore();
    }
    await database
      .getRepository(User)
      .update(owner.userId, { walletBalance: 10000 });
    await post(owner, 'subscribe', {
      planId: 'BASIC',
      paymentMethod: 'WALLET',
      billingPeriod: 'monthly',
    }).expect(400);
    expect(
      Number(
        (
          await database
            .getRepository(User)
            .findOneByOrFail({ id: owner.userId })
        ).walletBalance,
      ),
    ).toBe(10000);
    expect(stripeLookups).toBe(lookupsBefore);
    expect(
      await database.getRepository(SubscriptionPayment).countBy({
        userId: owner.userId,
      }),
    ).toBe(1);
    await get(other, `mpesa-payment-status/${a.id}`).expect(404);
    expect(
      (await get(owner, 'current').expect(200)).body.pendingPayment,
    ).toMatchObject({ id: a.id, planId: 'BASIC', paymentMethod: 'mpesa' });
    await pause();
    const invoice = invoices.get(a.transactionId)!;
    invoice.state = 'COMPLETE';
    await callback(a.transactionId, b.metadata.reference).expect(400);
    await callback(a.transactionId, undefined, 'wrong-challenge').expect(400);
    for (const mismatch of [
      { value: 1 },
      { currency: 'USD' },
      { api_ref: b.metadata.reference },
    ]) {
      Object.assign(
        invoice,
        { value: 1300, currency: 'KES', api_ref: a.metadata.reference },
        mismatch,
      );
      await callback(a.transactionId, a.metadata.reference).expect(400);
      expect((await receipt(a.id)).status).toBe('PENDING');
      expect(
        (
          await database
            .getRepository(User)
            .findOneByOrFail({ id: owner.userId })
        ).tier,
      ).toBe('FREE');
    }
    Object.assign(invoice, {
      value: 1300,
      currency: 'KES',
      api_ref: a.metadata.reference,
    });
    await callback(a.transactionId).expect(201);
    const activated = await subscription(a.id);
    await callback(a.transactionId).expect(201);
    expect((await subscription(a.id)).endDate).toEqual(activated.endDate);
    expect((await subscription(b.id)).tier).toBe('FREE');
    await pause();
    expect(
      (await get(owner, `mpesa-payment-status/${a.id}`).expect(200)).body,
    ).toMatchObject({ status: 'COMPLETED', entitlementActive: true });
    invoices.get(b.transactionId)!.state = 'COMPLETE';
    await callback(b.transactionId).expect(201);
    expect(await subscription(b.id)).toMatchObject({
      tier: 'BASIC',
      billingPeriod: 'yearly',
      currency: 'KES',
      autoRenewal: false,
      endDate: b.periodEnd,
    });
  });

  it('preserves paid access on initiation/callback failures, then extends once and ignores a stale queued expiry job', async () => {
    const current = await database
      .getRepository(Subscription)
      .findOneByOrFail({ userId: owner.userId });
    rejectInitiation = true;
    await subscribe(owner).expect(400);
    rejectInitiation = false;
    expect(
      await database
        .getRepository(Subscription)
        .findOneByOrFail({ id: current.id }),
    ).toMatchObject({
      tier: current.tier,
      status: current.status,
      endDate: current.endDate,
    });
    const failed = await subscribe(owner).expect(201);
    const failedReceipt = await receipt(failed.body.paymentId);
    invoices.get(failedReceipt.transactionId)!.state = 'FAILED';
    await callback(failedReceipt.transactionId).expect(201);
    expect((await receipt(failedReceipt.id)).status).toBe('FAILED');
    expect(await subscription(failedReceipt.id)).toMatchObject({
      tier: current.tier,
      status: current.status,
      endDate: current.endDate,
    });
    const renewal = await subscribe(owner).expect(201);
    const renewalReceipt = await receipt(renewal.body.paymentId);
    expect(renewalReceipt.periodStart).toEqual(current.endDate);
    expect(renewalReceipt.metadata.reference).not.toBe(
      failedReceipt.metadata.reference,
    );
    invoices.get(renewalReceipt.transactionId)!.state = 'COMPLETE';
    const subscriptions = database.getRepository(Subscription);
    const findSubscription = subscriptions.findOne.bind(subscriptions);
    const preferenceRead = jest
      .spyOn(subscriptions, 'findOne')
      .mockImplementationOnce(async (options) => {
        const snapshot = await findSubscription(options);
        // A provider callback arrives after the preference endpoint's initial
        // read but before it acquires the account billing lock.
        await callback(renewalReceipt.transactionId).expect(201);
        return snapshot;
      });
    try {
      await post(owner, 'auto-renew', { enable: false }).expect(201);
    } finally {
      preferenceRead.mockRestore();
    }
    await callback(renewalReceipt.transactionId).expect(201);
    expect(await subscription(renewalReceipt.id)).toMatchObject({
      status: SubscriptionStatus.ACTIVE,
      endDate: renewalReceipt.periodEnd,
      nextBillingDate: renewalReceipt.periodEnd,
    });
    expect(
      await app.get(SubscriptionProcessor).process({
        name: 'renew-subscription',
        data: { subscriptionId: current.id },
      } as Job<{ subscriptionId: string }>),
    ).toMatchObject({ status: 'not_due' });
    expect(
      (await database.getRepository(User).findOneByOrFail({ id: owner.userId }))
        .tier,
    ).toBe('BASIC');
    await pause();
    expect((await get(owner, 'current').expect(200)).body).toMatchObject({
      provider: 'INTASEND',
      paymentMethod: 'mpesa',
      renewalMode: 'manual',
      autoRenew: false,
      autoRenewalAvailable: false,
    });
    await post(owner, 'auto-renew', { enable: true }).expect(400);
    await post(owner, 'mpesa-quote', {
      planId: 'GOLD',
      billingPeriod: 'monthly',
    }).expect(400);
  });

  it('narrows legacy shared references by invoice and never overwrites an active Stripe contract', async () => {
    const a = (await subscribe(owner).expect(201)).body.paymentId;
    const b = (await subscribe(other, 13000, 'yearly').expect(201)).body
      .paymentId;
    const receiptA = await receipt(a);
    const receiptB = await receipt(b);
    for (const payment of [receiptA, receiptB]) {
      await database
        .getRepository(Transaction)
        .update(
          { providerRef: payment.transactionId },
          { accountReference: 'PayKey-BASIC' },
        );
      invoices.get(payment.transactionId)!.api_ref = 'PayKey-BASIC';
      invoices.get(payment.transactionId)!.state = 'COMPLETE';
    }
    const before = await subscription(a);
    // Historical receipts can reference a different row from the current Stripe contract.
    const stripeContract = await database.getRepository(Subscription).save({
      userId: owner.userId,
      tier: SubscriptionTier.GOLD,
      status: SubscriptionStatus.ACTIVE,
      stripeSubscriptionId: 'sub_active_fixture',
      endDate: before.endDate,
    });
    await database
      .getRepository(User)
      .update(owner.userId, { tier: 'GOLD' as User['tier'] });
    await callback(receiptB.transactionId).expect(201);
    expect((await receipt(a)).status).toBe('PENDING');
    await callback(receiptA.transactionId).expect(201);
    expect(await subscription(a)).toMatchObject({
      stripeSubscriptionId: null,
      endDate: before.endDate,
      tier: before.tier,
    });
    expect((await receipt(a)).metadata.entitlementApplied).toBe(false);
    expect(
      (
        await database
          .getRepository(Subscription)
          .findOneByOrFail({ id: stripeContract.id })
      ).tier,
    ).toBe('GOLD');
    expect(
      (await database.getRepository(User).findOneByOrFail({ id: owner.userId }))
        .tier,
    ).toBe('GOLD');
    expect(
      (await get(owner, `mpesa-payment-status/${a}`).expect(200)).body,
    ).toMatchObject({ status: 'COMPLETED', entitlementActive: false });
    // An old manual-plan job must not downgrade a newer Stripe entitlement,
    // even when that contract is stored on a different subscription row.
    const expiredDate = new Date(Date.now() - 86400000);
    await database.getRepository(Subscription).update(before.id, {
      nextBillingDate: expiredDate,
      endDate: expiredDate,
    });
    expect(
      await app.get(SubscriptionProcessor).process({
        name: 'renew-subscription',
        data: { subscriptionId: before.id },
      } as Job<{ subscriptionId: string }>),
    ).toMatchObject({ status: 'provider_managed' });
    expect(
      (await database.getRepository(User).findOneByOrFail({ id: owner.userId }))
        .tier,
    ).toBe('GOLD');
    expect((await subscription(a)).status).toBe(SubscriptionStatus.ACTIVE);
    await post(owner, 'mpesa-quote', { planId: 'BASIC' }).expect(400);
    await subscribe(owner).expect(400);
  });

  it('keeps accepted-but-unknown initiation durable and reuses it until the verified callback arrives', async () => {
    const before = sequence;
    loseInitiationResponse = true;
    const response = await subscribe(other, 13000, 'yearly').expect(201);
    loseInitiationResponse = false;
    const pending = await receipt(response.body.paymentId);
    expect(pending.status).toBe('PENDING');
    expect(pending.transactionId).toBeNull();
    expect(
      await database
        .getRepository(Transaction)
        .findOneByOrFail({ accountReference: pending.metadata.reference }),
    ).toMatchObject({ status: 'PENDING', providerRef: null });
    expect(
      (await subscribe(other, 13000, 'yearly').expect(201)).body.paymentId,
    ).toBe(pending.id);
    expect(sequence).toBe(before + 1);
    const invoiceId = `mpesa-sub-${sequence}`;
    invoices.get(invoiceId)!.state = 'COMPLETE';
    await callback(invoiceId).expect(201);
    expect(await receipt(pending.id)).toMatchObject({
      status: 'COMPLETED',
      transactionId: invoiceId,
    });
    expect(
      (await get(other, `mpesa-payment-status/${pending.id}`).expect(200)).body,
    ).toMatchObject({ status: 'COMPLETED', entitlementActive: true });
  });
});
