import { ConfigService } from '@nestjs/config';
import { GUARDS_METADATA } from '@nestjs/common/constants';
import { StripeSubscriptionBilling } from './stripe-subscription-billing';
import { StripeService } from './stripe.service';
import { SubscriptionPaymentsController } from './subscription-payments.controller';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  Subscription,
  SubscriptionStatus,
} from '../subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';

describe('paid Stripe subscription lifecycle', () => {
  function setup() {
    const now = Math.floor(Date.now() / 1000);
    const metadata = {
      userId: 'user-a',
      planTier: 'BASIC',
      billingPeriod: 'monthly',
      source: 'PayKey',
    };
    const session: any = {
      id: 'cs_test_one',
      mode: 'subscription',
      metadata,
      invoice: 'in_one',
      subscription: 'sub_one',
      payment_status: 'paid',
      status: 'complete',
    };
    const provider: any = {
      id: 'sub_one',
      metadata,
      status: 'active',
      cancel_at_period_end: false,
      latest_invoice: 'in_one',
      current_period_start: now,
      current_period_end: now + 2592000,
    };
    const invoice: any = {
      id: 'in_one',
      subscription: provider.id,
      paid: true,
      status: 'paid',
      payment_intent: 'pi_one',
      currency: 'usd',
      amount_paid: 999,
      amount_due: 999,
      number: 'PAY-001',
      created: now,
      due_date: null,
      status_transitions: { paid_at: now },
      period_start: now,
      period_end: now + 2592000,
      lines: {
        data: [
          {
            type: 'subscription',
            proration: false,
            period: { start: now, end: now + 2592000 },
          },
        ],
      },
    };
    const storedSubscriptions: any[] = [];
    const storedPayments: any[] = [];
    const users = { 'user-a': { tier: 'FREE' } };
    const matches = (record: any, where: any): boolean =>
      Array.isArray(where)
        ? where.some((part) => matches(record, part))
        : Object.entries(where).every(([key, value]) => record[key] === value);
    const manager: any = {
      query: jest.fn().mockResolvedValue([]),
      findOne: jest.fn(
        (entity, query) =>
          (entity === Subscription ? storedSubscriptions : storedPayments).find(
            (record) => matches(record, query.where),
          ) || null,
      ),
      create: jest.fn((_entity, record) => ({ ...record })),
      save: jest.fn((entity, record) => {
        const table =
          entity === Subscription ? storedSubscriptions : storedPayments;
        if (!record.id) record.id = `${entity.name}-${table.length + 1}`;
        const index = table.findIndex((entry) => entry.id === record.id);
        if (index === -1) table.push(record);
        else table[index] = record;
        return record;
      }),
      update: jest.fn((_entity, where, patch) =>
        Object.assign(users[where.id], patch),
      ),
    };
    // Model serialized advisory-lock transactions; assertions below verify the lock key.
    let last = Promise.resolve();
    manager.transaction = jest.fn((callback) => {
      const next = last.then(() => callback(manager));
      last = next.catch(() => undefined);
      return next;
    });
    const subscriptions: any = {
      manager,
      findOne: (query) => manager.findOne(Subscription, query),
    };
    const payments: any = {
      findOne: (query) => manager.findOne(SubscriptionPayment, query),
    };
    const stripe: any = {
      checkout: {
        sessions: {
          retrieve: jest.fn(() => session),
          list: jest.fn(() => ({ data: [] })),
          expire: jest.fn(),
          create: jest.fn(() => ({
            id: 'cs_test_new',
            url: 'https://checkout.stripe.com/example',
          })),
        },
      },
      subscriptions: { retrieve: jest.fn(() => provider) },
      invoices: { retrieve: jest.fn(() => invoice) },
      customers: {
        list: jest.fn(() => ({ data: [{ id: 'cus_one' }] })),
        create: jest.fn(),
      },
    };
    const config = new ConfigService({
      NODE_ENV: 'test',
      WEBSITE_URL: 'https://paydome.co',
    });
    const billing = new StripeSubscriptionBilling(
      stripe,
      subscriptions,
      payments,
      config,
    );
    const service = new StripeService(
      config,
      subscriptions,
      payments,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
    (service as any).stripe = stripe;
    return {
      now,
      session,
      provider,
      invoice,
      billing,
      service,
      manager,
      stripe,
      subscriptions,
      payments,
      storedSubscriptions,
      storedPayments,
      users,
    };
  }

  it('does not grant a subscription when checkout completes unpaid', async () => {
    const test = setup();
    test.session.payment_status = 'unpaid';
    await test.service.handleWebhook({
      type: 'checkout.session.completed',
      data: { object: { id: test.session.id } },
    } as any);
    expect(test.storedPayments).toHaveLength(0);
    expect(test.users['user-a'].tier).toBe('FREE');
    expect(test.manager.save).not.toHaveBeenCalled();
  });

  it('settles concurrent checkout and invoice callbacks once, including invoice-before-checkout', async () => {
    const test = setup();
    await Promise.all([
      test.service.handleWebhook({
        type: 'invoice.paid',
        data: { object: { id: test.invoice.id } },
      } as any),
      test.service.handleWebhook({
        type: 'checkout.session.completed',
        data: { object: { id: test.session.id } },
      } as any),
      test.service.handleWebhook({
        type: 'invoice.payment_succeeded',
        data: { object: { id: test.invoice.id } },
      } as any),
    ]);
    expect(test.storedSubscriptions).toHaveLength(1);
    expect(test.storedPayments).toHaveLength(1);
    expect(test.storedPayments[0]).toMatchObject({
      transactionId: 'in_one',
      status: PaymentStatus.COMPLETED,
      amount: 9.99,
    });
    expect(
      test.manager.save.mock.calls.filter(
        ([entity]) => entity === SubscriptionPayment,
      ),
    ).toHaveLength(1);
    expect(test.users['user-a'].tier).toBe('BASIC');
    expect(test.storedSubscriptions[0].nextBillingDate).toEqual(
      new Date(test.invoice.period_end * 1000),
    );
    expect(test.manager.query).toHaveBeenCalledWith(
      'SELECT pg_advisory_xact_lock(hashtext($1))',
      ['stripe-billing:user-a'],
    );
  });

  it('deduplicates invoice receipts even without a payment intent', async () => {
    const test = setup();
    test.invoice.payment_intent = null;
    await test.billing.invoicePaid('in_one');
    await test.billing.invoicePaid('in_one');
    expect(test.storedPayments).toHaveLength(1);
  });

  it('replaces an existing free period with the purchased Stripe period', async () => {
    const test = setup();
    test.storedSubscriptions.push({
      id: 'free-1',
      userId: 'user-a',
      tier: 'FREE',
      status: SubscriptionStatus.ACTIVE,
      nextBillingDate: new Date((test.now + 31536000) * 1000),
    });
    await test.billing.checkoutCompleted(test.session.id);
    expect(test.users['user-a'].tier).toBe('BASIC');
    expect(test.storedSubscriptions[0].nextBillingDate).toEqual(
      new Date(test.invoice.period_end * 1000),
    );
  });

  it('rechecks provider cancellation after acquiring the settlement lock', async () => {
    const test = setup();
    test.stripe.subscriptions.retrieve.mockResolvedValueOnce({
      ...test.provider,
    });
    test.provider.status = 'canceled';
    await test.billing.invoicePaid('in_one');
    expect(test.users['user-a'].tier).toBe('FREE');
    expect(test.storedPayments).toHaveLength(1);
    expect(test.storedSubscriptions[0].status).toBe(SubscriptionStatus.PENDING);
  });

  it('does not reset the paid period when an older invoice is retried', async () => {
    const test = setup();
    await test.billing.invoicePaid('in_one');
    const old = structuredClone(test.invoice);
    Object.assign(test.invoice, {
      id: 'in_two',
      payment_intent: 'pi_two',
      period_start: old.period_end,
      period_end: old.period_end + 2592000,
      lines: {
        data: [
          {
            type: 'subscription',
            proration: false,
            period: { start: old.period_end, end: old.period_end + 2592000 },
          },
        ],
      },
    });
    test.provider.latest_invoice = 'in_two';
    await test.billing.invoicePaid('in_two');
    const paidThrough = test.storedSubscriptions[0].nextBillingDate;
    Object.assign(test.invoice, old);
    await test.billing.invoicePaid('in_one');
    expect(test.storedPayments).toHaveLength(2);
    expect(test.storedSubscriptions[0].nextBillingDate).toEqual(paidThrough);
  });

  it('recovers a failed renewal with one receipt and rejects late failure regressions', async () => {
    const test = setup();
    await test.billing.invoicePaid('in_one');
    test.invoice.id = 'in_two';
    test.invoice.payment_intent = 'pi_two';
    test.invoice.paid = false;
    test.invoice.status = 'open';
    test.provider.status = 'past_due';
    test.provider.latest_invoice = 'in_two';
    await test.billing.invoiceFailed('in_two');
    expect(test.users['user-a'].tier).toBe('FREE');
    test.invoice.paid = true;
    test.invoice.status = 'paid';
    test.provider.status = 'active';
    await test.billing.invoicePaid('in_two');
    await test.billing.invoiceFailed('in_two');
    expect(test.storedPayments).toHaveLength(2);
    expect(test.storedPayments[1].status).toBe(PaymentStatus.COMPLETED);
    expect(test.users['user-a'].tier).toBe('BASIC');
  });

  it('revokes cancelled entitlements and ignores a late paid checkout callback', async () => {
    const test = setup();
    await test.billing.checkoutCompleted(test.session.id);
    test.provider.status = 'canceled';
    await test.billing.subscriptionChanged('sub_one');
    await test.billing.checkoutCompleted(test.session.id);
    expect(test.storedSubscriptions[0].status).toBe(
      SubscriptionStatus.CANCELLED,
    );
    expect(test.users['user-a'].tier).toBe('FREE');
    expect(test.storedPayments).toHaveLength(1);
  });

  it('does not reattach a cancelled Stripe contract after switching billing provider', async () => {
    const test = setup();
    await test.billing.checkoutCompleted(test.session.id);
    test.provider.status = 'canceled';
    await test.billing.subscriptionChanged('sub_one');
    Object.assign(test.storedSubscriptions[0], {
      stripeSubscriptionId: null,
      status: SubscriptionStatus.ACTIVE,
      tier: 'FREE',
    });
    await test.billing.invoicePaid('in_one');
    expect(test.storedSubscriptions[0].stripeSubscriptionId).toBeNull();
    expect(test.storedSubscriptions[0].tier).toBe('FREE');
    expect(test.users['user-a'].tier).toBe('FREE');
  });

  it('does not grant access from an active status update without a paid invoice', async () => {
    const test = setup();
    test.storedSubscriptions.push({
      id: 'local-1',
      userId: 'user-a',
      stripeSubscriptionId: 'sub_one',
      status: SubscriptionStatus.PENDING,
    });
    test.invoice.paid = false;
    test.invoice.status = 'open';
    await test.billing.subscriptionChanged('sub_one');
    expect(test.users['user-a'].tier).toBe('FREE');
    expect(test.storedPayments).toHaveLength(0);
  });

  it('requires session ownership and both a paid receipt and active entitlement in the read-only status route', async () => {
    const test = setup();
    await expect(
      test.billing.checkoutStatus('user-b', test.session.id),
    ).rejects.toMatchObject({ status: 404 });
    expect(
      await test.billing.checkoutStatus('user-a', test.session.id),
    ).toMatchObject({ paymentStatus: 'paid', entitlementActive: false });
    expect(test.manager.save).not.toHaveBeenCalled();
    await test.billing.checkoutCompleted(test.session.id);
    test.manager.save.mockClear();
    expect(
      await test.billing.checkoutStatus('user-a', test.session.id),
    ).toEqual({
      paymentStatus: 'paid',
      entitlementActive: true,
      tier: 'BASIC',
      billingPeriod: 'monthly',
    });
    expect(test.manager.save).not.toHaveBeenCalled();
  });

  it('charges server-owned USD prices and ignores client redirect destinations', async () => {
    const test = setup();
    await test.service.createCheckoutSession(
      'user-a',
      'BASIC',
      'a@example.com',
      'Customer',
      'monthly',
      'https://attacker.invalid/success',
      'https://attacker.invalid/cancel',
    );
    const input = test.stripe.checkout.sessions.create.mock.calls[0][0];
    expect(input.line_items[0].price_data).toMatchObject({
      currency: 'usd',
      unit_amount: 999,
    });
    expect(input.subscription_data.metadata).toMatchObject({
      userId: 'user-a',
      planTier: 'BASIC',
    });
    expect(input.success_url).toBe(
      'https://paydome.co/payments/subscriptions/success?session_id={CHECKOUT_SESSION_ID}',
    );
    expect(input.cancel_url).toBe(
      'https://paydome.co/payments/subscriptions/cancel',
    );
    await expect(
      test.billing.createCheckout('user-a', 'FREE', 'a@example.com'),
    ).rejects.toThrow('Invalid paid subscription');
  });

  it('reuses open checkout sessions and rejects duplicate active Stripe subscriptions', async () => {
    const test = setup();
    test.stripe.checkout.sessions.list.mockResolvedValue({
      data: [
        {
          ...test.session,
          status: 'open',
          url: 'https://checkout.stripe.com/existing',
        },
      ],
    });
    expect(
      await test.billing.createCheckout('user-a', 'BASIC', 'a@example.com'),
    ).toMatchObject({ sessionId: test.session.id });
    expect(test.stripe.checkout.sessions.create).not.toHaveBeenCalled();
    await test.billing.checkoutCompleted(test.session.id);
    await expect(
      test.billing.createCheckout('user-a', 'BASIC', 'a@example.com'),
    ).rejects.toThrow('already exists');
  });

  it('guards legacy checkout, cancellation and checkout-status endpoints', () => {
    for (const method of [
      'createCheckoutSession',
      'cancelSubscription',
      'getCheckoutStatus',
    ]) {
      expect(
        Reflect.getMetadata(
          GUARDS_METADATA,
          SubscriptionPaymentsController.prototype[method],
        ),
      ).toContain(JwtAuthGuard);
    }
  });

  it.each([
    ['open', 'pending'],
    ['expired', 'failed'],
  ])(
    'reports an unpaid %s checkout as %s without mutation',
    async (status, expected) => {
      const test = setup();
      test.session.status = status;
      test.session.payment_status = 'unpaid';
      expect(
        await test.billing.checkoutStatus('user-a', test.session.id),
      ).toMatchObject({ paymentStatus: expected, entitlementActive: false });
      expect(test.manager.save).not.toHaveBeenCalled();
    },
  );

  it('preserves paid access through a scheduled cancellation, then reports expiry', async () => {
    const test = setup();
    await test.billing.checkoutCompleted(test.session.id);
    test.provider.cancel_at_period_end = true;
    await test.billing.subscriptionChanged('sub_one');
    expect(test.storedSubscriptions[0].autoRenewal).toBe(false);
    expect(
      await test.billing.checkoutStatus('user-a', test.session.id),
    ).toMatchObject({ entitlementActive: true });
    test.storedSubscriptions[0].nextBillingDate = new Date(Date.now() - 1000);
    expect(
      await test.billing.checkoutStatus('user-a', test.session.id),
    ).toMatchObject({ paymentStatus: 'paid', entitlementActive: false });
  });

  it('rejects invalid callback signatures before processing any event', async () => {
    const constructEvent = jest.fn(() => {
      throw new Error('Invalid signature');
    });
    const handleWebhook = jest.fn();
    const controller = new SubscriptionPaymentsController(
      { constructEvent, handleWebhook } as any,
      {} as any,
      {} as any,
    );
    const rawBody = Buffer.from('{"type":"invoice.paid"}');
    await expect(
      controller.handleWebhook('invalid-signature', { rawBody }),
    ).rejects.toMatchObject({ status: 401 });
    expect(constructEvent).toHaveBeenCalledWith(rawBody, 'invalid-signature');
    expect(handleWebhook).not.toHaveBeenCalled();
  });

  it.each([
    { STRIPE_SECRET_KEY: undefined, STRIPE_WEBHOOK_SECRET: 'whsec_example' },
    {
      STRIPE_SECRET_KEY: 'sk_test_example',
      STRIPE_WEBHOOK_SECRET: 'whsec_example',
    },
    { STRIPE_SECRET_KEY: 'sk_live_example', STRIPE_WEBHOOK_SECRET: undefined },
  ])(
    'fails production startup for missing or sandbox Stripe credentials',
    (credentials) => {
      expect(
        () =>
          new StripeService(
            new ConfigService({ NODE_ENV: 'production', ...credentials }),
            {} as any,
            {} as any,
            {} as any,
            {} as any,
            {} as any,
            {} as any,
            {} as any,
            {} as any,
          ),
      ).toThrow('Production paid subscriptions require');
    },
  );

  it.each([true, false])(
    'only returns public user fields in current subscription (active=%s)',
    async (active) => {
      const user = {
        id: 'user-a',
        email: 'a@example.com',
        firstName: 'A',
        lastName: 'Customer',
        tier: 'BASIC',
        passwordHash: 'private-password-hash',
        stripeCustomerId: 'private-provider-id',
      };
      const repository = {
        findOne: () =>
          active ? { id: 'subscription-1', user, tier: 'BASIC' } : null,
        manager: { findOne: () => user },
      };
      const controller = new SubscriptionPaymentsController(
        {} as any,
        repository as any,
        {} as any,
      );
      const output = await controller.getCurrentSubscription({
        user: { userId: 'user-a' },
      });
      expect(JSON.stringify(output)).not.toContain('private-');
      expect(output.user).toEqual({
        id: 'user-a',
        email: 'a@example.com',
        firstName: 'A',
        lastName: 'Customer',
        tier: 'BASIC',
      });
    },
  );
});
