import { INestApplication } from '@nestjs/common';
import { getQueueToken } from '@nestjs/bullmq';
import { Test } from '@nestjs/testing';
import { Queue } from 'bullmq';
import { DataSource } from 'typeorm';
import nock from 'nock';
import Stripe from 'stripe';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { registerRequestBodyParsers } from '../src/common/http/request-body';
import {
  Subscription,
  SubscriptionStatus,
  SubscriptionTier,
} from '../src/modules/subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
} from '../src/modules/subscriptions/entities/subscription-payment.entity';
import { User, UserTier } from '../src/modules/users/entities/user.entity';
import { createTestHelpers } from './helpers/test-helpers';

// Stripe 16's Node client waits for a TLS socket event that nock 14 does not
// emit on Node 24. Its supported Fetch client keeps the real SDK request/response
// handling and webhook verification while allowing the external HTTP fixture.
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

/** Real Nest routes, JWTs, PostgreSQL transactions and Redis; only Stripe HTTP is simulated. */
describe('Paid subscription launch journey', () => {
  const secret = 'whsec_paid_launch_e2e_only';
  const stripe = new Stripe('sk_test_paid_launch_e2e_only');
  const originalKey = process.env.STRIPE_SECRET_KEY;
  const originalSecret = process.env.STRIPE_WEBHOOK_SECRET;
  const now = Math.floor(Date.now() / 1000);
  const periodEnd = now + 30 * 86400;
  let app: INestApplication;
  let database: DataSource;
  let provider: nock.Scope;
  let checkoutRequest: Record<string, string> = {};
  const metadata: Record<string, string> = {};
  const session = {
    id: 'cs_test_paid_launch',
    object: 'checkout.session',
    mode: 'subscription',
    customer: 'cus_paid_launch',
    status: 'open',
    payment_status: 'unpaid',
    url: 'https://checkout.stripe.com/c/pay/cs_test_paid_launch',
    metadata,
    invoice: null as string | null,
    subscription: null as string | null,
  };
  const subscription = {
    id: 'sub_paid_launch',
    object: 'subscription',
    customer: session.customer,
    metadata,
    status: 'active',
    cancel_at_period_end: false,
    latest_invoice: 'in_paid_launch',
    current_period_start: now,
    current_period_end: periodEnd,
    ended_at: null as number | null,
    canceled_at: null as number | null,
  };
  const invoice = {
    id: 'in_paid_launch',
    object: 'invoice',
    number: 'PAID-LAUNCH-001',
    customer: session.customer,
    subscription: subscription.id,
    subscription_details: { metadata },
    paid: true,
    status: 'paid',
    payment_intent: 'pi_paid_launch',
    currency: 'usd',
    amount_paid: 999,
    amount_due: 999,
    created: now,
    due_date: null,
    status_transitions: { paid_at: now },
    period_start: now,
    period_end: periodEnd,
    lines: {
      object: 'list',
      data: [
        {
          type: 'subscription',
          proration: false,
          period: { start: now, end: periodEnd },
        },
      ],
      has_more: false,
    },
  };

  beforeAll(async () => {
    process.env.STRIPE_SECRET_KEY = 'sk_test_paid_launch_e2e_only';
    process.env.STRIPE_WEBHOOK_SECRET = secret;
    provider = nock('https://api.stripe.com')
      .persist()
      .get('/v1/customers')
      .query(true)
      .reply(200, { object: 'list', data: [], has_more: false })
      .post('/v1/customers')
      .reply(200, { id: session.customer, object: 'customer' })
      .get('/v1/checkout/sessions')
      .query(true)
      .reply(200, { object: 'list', data: [], has_more: false })
      .post('/v1/checkout/sessions')
      .reply((_uri, body) => {
        checkoutRequest =
          typeof body === 'string'
            ? Object.fromEntries(new URLSearchParams(body))
            : (body as Record<string, string>);
        for (const key of ['userId', 'planTier', 'billingPeriod', 'source']) {
          metadata[key] = checkoutRequest[`metadata[${key}]`];
        }
        return [200, session];
      })
      .get(`/v1/checkout/sessions/${session.id}`)
      .reply(() => [200, session])
      .get(`/v1/invoices/${invoice.id}`)
      .reply(() => [200, invoice])
      .get(`/v1/subscriptions/${subscription.id}`)
      .reply(() => [200, subscription])
      .delete(`/v1/subscriptions/${subscription.id}`)
      .reply(() => {
        subscription.status = 'canceled';
        subscription.ended_at = now;
        subscription.canceled_at = now;
        return [200, subscription];
      });
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication({ bodyParser: false });
    registerRequestBodyParsers(app);
    await app.init();
    database = app.get(DataSource);
  });

  afterAll(async () => {
    await app?.close();
    nock.cleanAll();
    if (originalKey === undefined) delete process.env.STRIPE_SECRET_KEY;
    else process.env.STRIPE_SECRET_KEY = originalKey;
    if (originalSecret === undefined) delete process.env.STRIPE_WEBHOOK_SECRET;
    else process.env.STRIPE_WEBHOOK_SECRET = originalSecret;
  });

  function callback(type: string, object: object, eventId: string) {
    // Real Stripe SDK signing and verification; preserve raw HTTP bytes.
    const payload = JSON.stringify(
      { id: eventId, object: 'event', type, data: { object } },
      null,
      2,
    );
    const signature = stripe.webhooks.generateTestHeaderString({
      payload,
      secret,
    });
    return request(app.getHttpServer())
      .post('/payments/subscriptions/webhook')
      .set('Content-Type', 'application/json')
      .set('stripe-signature', signature)
      .send(payload)
      .expect(201);
  }

  it('signs up, pays, activates once across competing callbacks, and cancels back to Free', async () => {
    expect(database.options.type).toBe('postgres');
    expect(String(database.options.database)).toMatch(/_test$/);
    const queue = app.get<Queue>(getQueueToken('subscriptions'));
    expect(await (await queue.client).ping()).toBe('PONG');

    const { token, userId } = await createTestHelpers(app).createTestUser({
      emailPrefix: 'paid.launch',
    });
    const auth = `Bearer ${token}`;
    const current = () =>
      request(app.getHttpServer())
        .get('/subscriptions/current')
        .set('Authorization', auth)
        .expect(200);
    const status = () =>
      request(app.getHttpServer())
        .get(`/payments/subscriptions/checkout-status/${session.id}`)
        .set('Authorization', auth)
        .expect(200);
    const receipts = database.getRepository(SubscriptionPayment);
    const subscriptions = database.getRepository(Subscription);
    const users = database.getRepository(User);
    expect((await current()).body.tier).toBe('FREE');

    const checkout = await request(app.getHttpServer())
      .post('/subscriptions/subscribe')
      .set('Authorization', auth)
      .send({
        planId: 'basic',
        paymentMethod: 'STRIPE',
        billingPeriod: 'monthly',
      })
      .expect(201);
    expect(checkout.body).toMatchObject({
      sessionId: session.id,
      checkoutUrl: session.url,
    });
    expect(checkoutRequest).toMatchObject({
      mode: 'subscription',
      client_reference_id: userId,
      'metadata[userId]': userId,
      'subscription_data[metadata][userId]': userId,
      'line_items[0][price_data][currency]': 'usd',
      'line_items[0][price_data][unit_amount]': '999',
      'line_items[0][price_data][recurring][interval]': 'month',
    });
    expect((await status()).body).toMatchObject({
      paymentStatus: 'pending',
      entitlementActive: false,
    });
    expect(await receipts.countBy({ userId })).toBe(0);
    expect((await users.findOneByOrFail({ id: userId })).tier).toBe(
      UserTier.FREE,
    );

    session.status = 'complete';
    session.payment_status = 'paid';
    session.invoice = invoice.id;
    session.subscription = subscription.id;
    await callback('checkout.session.completed', session, 'evt_paid_checkout');

    const active = (await current()).body;
    expect(active).toMatchObject({
      tier: 'BASIC',
      status: 'ACTIVE',
      stripeSubscriptionId: subscription.id,
      user: { id: userId, tier: 'BASIC' },
    });
    expect(active.user).not.toHaveProperty('passwordHash');
    expect((await status()).body).toEqual({
      paymentStatus: 'paid',
      entitlementActive: true,
      tier: 'BASIC',
      billingPeriod: 'monthly',
    });
    const persisted = await subscriptions.findOneByOrFail({
      id: active.id,
      userId,
    });
    expect(persisted.tier).toBe(SubscriptionTier.BASIC);
    expect(persisted.nextBillingDate?.getTime()).toBe(periodEnd * 1000);
    expect(await receipts.countBy({ userId })).toBe(1);
    const receipt = await receipts.findOneByOrFail({
      userId,
      transactionId: invoice.id,
    });
    expect(receipt).toMatchObject({
      subscriptionId: persisted.id,
      status: PaymentStatus.COMPLETED,
      amount: 9.99,
      currency: 'USD',
    });

    // Competing real PostgreSQL transactions must serialize and keep one invoice receipt.
    await Promise.all([
      callback('invoice.paid', invoice, 'evt_paid_invoice'),
      callback('checkout.session.completed', session, 'evt_paid_checkout'),
      callback('invoice.payment_succeeded', invoice, 'evt_paid_invoice_retry'),
    ]);
    expect(await receipts.countBy({ userId })).toBe(1);
    const afterRetries = await subscriptions.findOneByOrFail({
      id: persisted.id,
    });
    expect(afterRetries.startDate).toEqual(persisted.startDate);
    expect(afterRetries.nextBillingDate).toEqual(persisted.nextBillingDate);
    expect(afterRetries.endDate).toEqual(persisted.endDate);
    expect((await status()).body.entitlementActive).toBe(true);

    await request(app.getHttpServer())
      .put(`/payments/subscriptions/${persisted.id}/cancel`)
      .set('Authorization', auth)
      .expect(200);
    await callback(
      'customer.subscription.deleted',
      subscription,
      'evt_paid_cancelled',
    );
    expect((await current()).body).toMatchObject({
      id: null,
      tier: 'FREE',
      user: { tier: 'FREE' },
    });
    expect((await status()).body).toMatchObject({
      paymentStatus: 'paid',
      entitlementActive: false,
    });
    expect((await users.findOneByOrFail({ id: userId })).tier).toBe(
      UserTier.FREE,
    );
    expect(
      await subscriptions.countBy({
        userId,
        status: SubscriptionStatus.ACTIVE,
      }),
    ).toBe(0);
    expect(
      (await subscriptions.findOneByOrFail({ id: persisted.id })).status,
    ).toBe(SubscriptionStatus.CANCELLED);
    expect(await receipts.countBy({ userId })).toBe(1);
    expect(provider.isDone()).toBe(true);
  });
});
