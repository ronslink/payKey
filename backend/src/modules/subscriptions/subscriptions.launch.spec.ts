import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import request from 'supertest';
import { SubscriptionsController } from './subscriptions.controller';
import {
  Subscription,
  SubscriptionStatus,
} from './entities/subscription.entity';
import {
  SubscriptionPayment,
  PaymentStatus,
} from './entities/subscription-payment.entity';
import { Campaign } from './entities/campaign.entity';
import { PromotionalItem } from './entities/promotional-item.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { UsersService } from '../users/users.service';
import { IntaSendService } from '../payments/intasend.service';
import { StripeService } from '../payments/stripe.service';
import { WorkersService } from '../workers/workers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

describe('subscription launch boundaries', () => {
  let app: INestApplication;
  let controller: SubscriptionsController;
  const user = {
    id: 'user-a',
    email: 'a@example.com',
    firstName: 'A',
    lastName: 'Customer',
    businessName: 'Business',
    tier: 'BASIC',
    passwordHash: 'private-password',
    stripeCustomerId: 'private-customer',
  };
  const subscriptionRepository = {
    findOne: jest.fn(),
    findOneBy: jest.fn(),
    save: jest.fn(),
    manager: { transaction: jest.fn() },
  };
  const paymentRepository = { findOne: jest.fn(), find: jest.fn() };
  const stripe = {
    createCheckoutSession: jest.fn(),
    setCancelAtPeriodEnd: jest.fn(),
  };
  const intasend = { initiateStkPush: jest.fn(), createCheckoutUrl: jest.fn() };
  const users = { findOneById: jest.fn(), update: jest.fn() };
  const manager = {
    query: jest.fn(),
    find: jest.fn(),
    update: jest.fn(),
    getRepository: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [SubscriptionsController],
      providers: [
        {
          provide: getRepositoryToken(Subscription),
          useValue: subscriptionRepository,
        },
        {
          provide: getRepositoryToken(SubscriptionPayment),
          useValue: paymentRepository,
        },
        { provide: getRepositoryToken(Campaign), useValue: {} },
        { provide: getRepositoryToken(PromotionalItem), useValue: {} },
        { provide: getRepositoryToken(Transaction), useValue: {} },
        { provide: UsersService, useValue: users },
        { provide: IntaSendService, useValue: intasend },
        { provide: StripeService, useValue: stripe },
        { provide: WorkersService, useValue: {} },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({
        canActivate: (context) => {
          context.switchToHttp().getRequest().user = { userId: 'user-a' };
          return true;
        },
      })
      .compile();
    app = module.createNestApplication();
    controller = module.get(SubscriptionsController);
    await app.init();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    subscriptionRepository.findOne.mockResolvedValue(null);
    subscriptionRepository.findOneBy.mockResolvedValue(null);
    paymentRepository.findOne.mockResolvedValue(null);
    users.findOneById.mockResolvedValue(user);
    stripe.createCheckoutSession.mockResolvedValue({
      sessionId: 'cs_test_1',
      url: 'https://checkout.stripe.com/example',
    });
    subscriptionRepository.manager.transaction.mockImplementation((callback) =>
      callback(manager),
    );
    manager.find.mockResolvedValue([]);
  });
  afterAll(async () => app.close());

  it.each([
    {},
    { planId: 123, paymentMethod: 'STRIPE' },
    { planId: 'basic', paymentMethod: 'STRIPE', amount: 0 },
    { planId: 'basic', paymentMethod: 'STRIPE', userId: 'other-user' },
    { planId: 'basic', paymentMethod: 'STRIPE', billingPeriod: 'forever' },
    { planId: 'basic', paymentMethod: 'unknown' },
  ])(
    'rejects malformed or client-owned billing fields before creating checkout',
    async (body) => {
      await request(app.getHttpServer())
        .post('/subscriptions/subscribe')
        .send(body)
        .expect(400);
      expect(stripe.createCheckoutSession).not.toHaveBeenCalled();
      expect(subscriptionRepository.manager.transaction).not.toHaveBeenCalled();
    },
  );

  it('accepts validated card checkout using the signed-in owner and stored email', async () => {
    const response = await request(app.getHttpServer())
      .post('/subscriptions/subscribe')
      .send({
        planId: 'basic',
        paymentMethod: 'stripe',
        billingPeriod: 'monthly',
      })
      .expect(201);
    expect(response.body.checkoutUrl).toContain('checkout.stripe.com');
    expect(stripe.createCheckoutSession).toHaveBeenCalledWith(
      'user-a',
      'BASIC',
      'a@example.com',
      'A Customer',
      'monthly',
    );
  });

  it.each(['BANK', 'WALLET', undefined])(
    'blocks %s mutation while a Stripe subscription exists',
    async (paymentMethod) => {
      manager.find.mockResolvedValue([
        {
          id: 'sub-1',
          userId: 'user-a',
          stripeSubscriptionId: 'sub_stripe',
          status: SubscriptionStatus.ACTIVE,
        },
      ]);
      await request(app.getHttpServer())
        .post('/subscriptions/subscribe')
        .send({ planId: paymentMethod ? 'basic' : 'free', paymentMethod })
        .expect(400);
      expect(manager.query).toHaveBeenCalledWith(
        'SELECT pg_advisory_xact_lock(hashtext($1))',
        ['stripe-billing:user-a'],
      );
      expect(manager.update).not.toHaveBeenCalled();
      expect(manager.getRepository).not.toHaveBeenCalled();
      expect(intasend.createCheckoutUrl).not.toHaveBeenCalled();
      expect(users.update).not.toHaveBeenCalled();
    },
  );

  it.each([
    SubscriptionStatus.ACTIVE,
    SubscriptionStatus.PAST_DUE,
    SubscriptionStatus.PENDING,
  ])(
    'blocks M-Pesa for a %s Stripe contract before any provider call',
    async (status) => {
      manager.find.mockResolvedValue([
        { stripeSubscriptionId: 'sub_stripe', status },
      ]);
      await request(app.getHttpServer())
        .post('/subscriptions/mpesa-subscribe')
        .send({
          planId: 'basic',
          phoneNumber: '+254712345678',
          expectedAmount: 1300,
        })
        .expect(400);
      expect(manager.query).toHaveBeenCalledWith(
        'SELECT pg_advisory_xact_lock(hashtext($1))',
        ['stripe-billing:user-a'],
      );
      expect(intasend.initiateStkPush).not.toHaveBeenCalled();
      expect(manager.getRepository).not.toHaveBeenCalled();
    },
  );

  it('validates M-Pesa and auto-renew mutation fields', async () => {
    await request(app.getHttpServer())
      .post('/subscriptions/mpesa-subscribe')
      .send({ planId: 'basic', phoneNumber: {} })
      .expect(400);
    await request(app.getHttpServer())
      .post('/subscriptions/auto-renew')
      .send({ enable: 'false' })
      .expect(400);
    expect(subscriptionRepository.findOne).not.toHaveBeenCalled();
    expect(subscriptionRepository.manager.transaction).not.toHaveBeenCalled();
  });

  it.each([true, false])(
    'projects safe user fields for current subscription (active=%s)',
    async (active) => {
      subscriptionRepository.findOne.mockResolvedValue(
        active ? { id: 'sub-1', tier: 'BASIC', user, autoRenewal: true } : null,
      );
      const response = await request(app.getHttpServer())
        .get('/subscriptions/current')
        .expect(200);
      expect(response.body.user).toMatchObject({
        id: 'user-a',
        email: 'a@example.com',
        businessName: 'Business',
      });
      expect(JSON.stringify(response.body)).not.toContain('private-');
    },
  );

  it('never reactivates an old payment by polling its status', async () => {
    paymentRepository.findOne.mockResolvedValue({
      id: 'payment-1',
      userId: 'user-a',
      subscriptionId: 'sub-1',
      status: PaymentStatus.COMPLETED,
      amount: 1300,
      currency: 'KES',
      metadata: { entitlementApplied: true },
    });
    subscriptionRepository.findOneBy.mockResolvedValue({
      id: 'sub-1',
      userId: 'user-a',
      status: SubscriptionStatus.CANCELLED,
      stripeSubscriptionId: 'sub_stripe',
      endDate: new Date(Date.now() + 86400000),
    });
    const result = await controller.checkMpesaPaymentStatus(
      { user: { userId: 'user-a' } },
      'payment-1',
    );
    expect(result).toMatchObject({
      status: PaymentStatus.COMPLETED,
      entitlementActive: false,
    });
    expect(subscriptionRepository.findOneBy).toHaveBeenCalledWith({
      id: 'sub-1',
      userId: 'user-a',
    });
    expect(subscriptionRepository.findOne).not.toHaveBeenCalled();
    expect(subscriptionRepository.save).not.toHaveBeenCalled();
    expect(users.update).not.toHaveBeenCalled();
  });
});
