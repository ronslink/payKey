import { PaymentsController } from './payments.controller';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
} from '../subscriptions/entities/subscription-payment.entity';
import {
  TransactionStatus,
  TransactionType,
} from './entities/transaction.entity';

describe('production webhook enforcement', () => {
  const previous = { ...process.env };
  const makeController = () => {
    const manager = {
      find: jest
        .fn()
        .mockResolvedValue([
          { status: TransactionStatus.SUCCESS, providerRef: 'provider-id' },
        ]),
      save: jest.fn(),
      update: jest.fn(),
      increment: jest.fn(),
      decrement: jest.fn(),
      query: jest.fn(),
      findOne: jest.fn(),
    };
    const transaction = jest.fn((callback) => callback(manager));
    const verifyWebhookSignature = jest.fn(
      (signature) => signature === 'verified-signature',
    );
    const controller = new PaymentsController(
      { transaction } as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      { findOne: jest.fn().mockResolvedValue(null) } as never,
      { verifyWebhookSignature } as never,
      {} as never,
      {} as never,
    );
    return { controller, manager, transaction, verifyWebhookSignature };
  };
  const req = { headers: {}, rawBody: Buffer.from('{}') } as never;

  beforeEach(() => {
    process.env.NODE_ENV = 'production';
    delete process.env.INTASEND_IS_LIVE;
  });
  afterEach(() => {
    process.env = { ...previous };
  });

  it.each(['INTASEND_SIMULATE', 'INTASEND_DISABLE_SIG_CHECK'])(
    'does not let %s bypass production verification',
    async (flag) => {
      process.env[flag] = 'true';
      const { controller, transaction } = makeController();
      await expect(
        controller.handleIntaSendWebhook(req, '', {
          invoice_id: 'INV_SIM_1',
          host: 'localhost',
          state: 'COMPLETE',
        }),
      ).rejects.toThrow('Invalid signature');
      expect(transaction).not.toHaveBeenCalled();
    },
  );

  it('also rejects bypasses for live credentials outside NODE_ENV=production', async () => {
    process.env.NODE_ENV = 'development';
    process.env.INTASEND_IS_LIVE = 'true';
    process.env.INTASEND_DISABLE_SIG_CHECK = 'true';
    const { controller, transaction } = makeController();
    await expect(
      controller.handleIntaSendWebhook(req, '', {
        invoice_id: 'INV_SIM_1',
        host: 'localhost',
      }),
    ).rejects.toThrow('Invalid signature');
    expect(transaction).not.toHaveBeenCalled();
  });

  it('acknowledges verified retries without repeating settlement', async () => {
    const { controller, manager } = makeController();
    const body = { invoice_id: 'provider-id', state: 'COMPLETE' };
    for (let attempt = 0; attempt < 2; attempt++) {
      await expect(
        controller.handleIntaSendWebhook(req, 'verified-signature', body),
      ).resolves.toEqual({ status: 'ignored', reason: 'Already finalized' });
    }
    expect(manager.find).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ lock: { mode: 'pessimistic_write' } }),
    );
    expect(manager.save).not.toHaveBeenCalled();
    expect(manager.update).not.toHaveBeenCalled();
  });

  it('credits pending → clearing → paid once across differently shaped retries', async () => {
    const { controller, manager } = makeController();
    const stored = {
      status: TransactionStatus.PENDING,
      providerRef: 'provider-id',
      type: TransactionType.DEPOSIT,
      userId: 'owner',
      amount: 100,
      metadata: {},
    };
    manager.find.mockResolvedValue([stored]);
    for (const body of [
      { state: 'CLEARING' },
      { status: 'CLEARING' },
      { state: 'COMPLETE', clearing_status: 'CLEARING' },
      { state: 'COMPLETE' },
      { state: 'COMPLETE' },
    ])
      await controller.handleIntaSendWebhook(req, 'verified-signature', {
        ...body,
        invoice_id: 'provider-id',
        challenge: 'shared-provider-secret',
      });
    expect(manager.increment.mock.calls.map((call) => call.slice(2))).toEqual([
      ['clearingBalance', 100],
      ['walletBalance', 100],
    ]);
    expect(manager.decrement).toHaveBeenCalledTimes(1);
    expect(manager.decrement).toHaveBeenCalledWith(
      expect.anything(),
      { id: 'owner' },
      'clearingBalance',
      100,
    );
    expect(JSON.stringify(stored.metadata)).not.toContain(
      'shared-provider-secret',
    );
    expect(stored.status).toBe(TransactionStatus.SUCCESS);
  });

  it('releases clearing balance once when a deposit fails', async () => {
    const { controller, manager } = makeController();
    manager.find.mockResolvedValue([
      {
        status: TransactionStatus.CLEARING,
        providerRef: 'provider-id',
        type: TransactionType.DEPOSIT,
        userId: 'owner',
        amount: 100,
        metadata: {},
      },
    ]);
    await controller.handleIntaSendWebhook(req, 'verified-signature', {
      invoice_id: 'provider-id',
      state: 'FAILED',
    });
    await controller.handleIntaSendWebhook(req, 'verified-signature', {
      invoice_id: 'provider-id',
      state: 'FAILED',
    });
    expect(manager.increment).not.toHaveBeenCalled();
    expect(manager.decrement).toHaveBeenCalledTimes(1);
  });

  it('records a late legacy payment without overwriting Stripe entitlement', async () => {
    const { controller, manager } = makeController();
    manager.find.mockResolvedValue([
      {
        status: TransactionStatus.PENDING,
        providerRef: 'provider-id',
        userId: 'owner',
        amount: 100,
        metadata: { subscriptionPaymentId: 'legacy-payment' },
      },
    ]);
    manager.findOne.mockImplementation((entity) =>
      Promise.resolve(
        entity === SubscriptionPayment
          ? {
              id: 'legacy-payment',
              userId: 'owner',
              subscriptionId: 'subscription',
            }
          : { id: 'subscription', stripeSubscriptionId: 'sub_existing' },
      ),
    );
    await controller.handleIntaSendWebhook(req, 'verified-signature', {
      invoice_id: 'provider-id',
      state: 'COMPLETE',
    });
    expect(manager.query).toHaveBeenCalledWith(
      'SELECT pg_advisory_xact_lock(hashtext($1))',
      ['stripe-billing:owner'],
    );
    expect(manager.update).toHaveBeenCalledWith(
      SubscriptionPayment,
      'legacy-payment',
      expect.objectContaining({ status: PaymentStatus.COMPLETED }),
    );
    expect(manager.update).toHaveBeenCalledWith(
      SubscriptionPayment,
      'legacy-payment',
      expect.objectContaining({
        notes: expect.stringContaining('reconciliation required'),
      }),
    );
    expect(
      manager.save.mock.calls.some(([entity]) => entity === Subscription),
    ).toBe(false);
  });
});
