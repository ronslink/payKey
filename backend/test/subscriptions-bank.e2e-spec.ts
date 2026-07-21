import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { DataSource } from 'typeorm';
import {
  TestHelpers,
  createTestHelpers,
  type TestUserResult,
} from './helpers/test-helpers';
import { SubscriptionPlan } from './types/test-types';
import { IntaSendService } from '../src/modules/payments/intasend.service';
import { SubscriptionPayment } from '../src/modules/subscriptions/entities/subscription-payment.entity';
import {
  Subscription,
  SubscriptionStatus,
} from '../src/modules/subscriptions/entities/subscription.entity';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../src/modules/payments/entities/transaction.entity';
import { User } from '../src/modules/users/entities/user.entity';

/**
 * Bank Subscription E2E Tests
 *
 * Verifies:
 * 1. User can save bank details to profile.
 * 2. User can initiate a Bank Subscription (IntaSend PesaLink).
 */
describe('Bank Subscription Flow E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;
  let testUser: TestUserResult;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(IntaSendService)
      .useValue({
        createCheckoutUrl: jest.fn().mockResolvedValue({
          url: 'https://sandbox.intasend.com/checkout/mock-url-123',
          id: 'mock-checkout-id',
          signature: 'mock-signature',
        }),
        verifyWebhookSignature: jest.fn().mockReturnValue(true),
        initiateStkPush: jest.fn().mockResolvedValue({
          invoice: { invoice_id: 'mock-invoice-id' },
          tracking_id: 'mock-tracking-id',
        }),
      })
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    helpers = createTestHelpers(app);

    // Create a fresh user for this test
    testUser = await helpers.createTestUser({
      emailPrefix: 'bank-sub-test',
      firstName: 'BankTester',
      lastName: 'User',
      businessName: 'Bank Test Ltd',
    });

    authToken = testUser.token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('1. Bank Details Collection', () => {
    it('should allow saving bank details to profile', async () => {
      const bankDetails = {
        bankName: 'KCB Bank',
        bankAccount: '1234567890',
      };

      const res = await request(app.getHttpServer())
        .patch('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send(bankDetails)
        .expect(200);

      expect(res.body).toHaveProperty('bankName', bankDetails.bankName);
      expect(res.body).toHaveProperty('bankAccount', bankDetails.bankAccount);
    });
  });

  describe('2. Bank Subscription Initiation', () => {
    let targetPlan: SubscriptionPlan;

    // Fetch a paid plan first
    it('should find a paid plan to subscribe to', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/plans') // Note: Using existing endpoint from other tests
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const plans = res.body as SubscriptionPlan[];
      // Find a paid plan (e.g. BASIC or GOLD)
      targetPlan = plans.find((p) => p.price_usd > 0);

      expect(targetPlan).toBeDefined();
      console.log('Target Plan:', targetPlan.name, targetPlan.id);
    });

    it('should generate IntaSend Checkout URL for Bank Payment', async () => {
      if (!targetPlan) throw new Error('No paid plan found');

      const payload = {
        planId: targetPlan.id,
        paymentMethod: 'BANK',
        billingPeriod: 'monthly',
      };

      // Try /subscriptions/subscribe first (Standard Controller)
      // If fails, try /payments/subscriptions/subscribe (if proxied)
      // Based on code, Controller is @Controller('subscriptions')

      const res = await request(app.getHttpServer())
        .post('/subscriptions/subscribe')
        .set('Authorization', `Bearer ${authToken}`)
        .send(payload)
        .expect(201); // Standard NestJS POST returns 201

      // Verify Response structure
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Bank transfer checkout initiated');
      expect(res.body).toHaveProperty('checkoutUrl');
      expect(res.body).toHaveProperty('reference');
      // IntaSend URL usually contains 'intasend.com'
      expect(res.body.checkoutUrl).toContain('intasend');

      const dataSource = app.get(DataSource);
      const payment = await dataSource
        .getRepository(SubscriptionPayment)
        .findOne({
          where: {
            transactionId: res.body.reference,
          },
        });

      expect(payment).toBeDefined();
      expect(payment?.status).toBe('PENDING');
      expect(payment?.paymentProvider).toBe('INTASEND');

      const transaction = await dataSource.getRepository(Transaction).findOne({
        where: {
          accountReference: res.body.reference,
        },
      });

      expect(transaction).toBeDefined();
      expect(transaction?.type).toBe(TransactionType.SUBSCRIPTION);
      expect(transaction?.status).toBe(TransactionStatus.PENDING);
      expect(transaction?.providerRef).toBe('mock-checkout-id');
      expect(transaction?.metadata?.subscriptionPaymentId).toBe(payment?.id);

      const pendingPaymentRes = await request(app.getHttpServer())
        .get('/subscriptions/pending-payment')
        .set('Authorization', `Bearer ${testUser.token}`)
        .expect(200);

      expect(pendingPaymentRes.body.hasPendingPayment).toBe(true);
      expect(pendingPaymentRes.body.pendingPayment.checkoutUrl).toBe(
        res.body.checkoutUrl,
      );
      expect(pendingPaymentRes.body.pendingPayment.reference).toBe(
        res.body.reference,
      );

      await request(app.getHttpServer())
        .post('/webhooks/intasend')
        .send({
          challenge: 'paykey2026!',
          invoice_id: 'mock-checkout-id',
          api_ref: res.body.reference,
          state: 'COMPLETE',
          provider: 'PESALINK',
          currency: 'KES',
          value: targetPlan.price_kes,
        })
        .expect(201);

      const updatedPayment = await dataSource
        .getRepository(SubscriptionPayment)
        .findOne({
          where: {
            id: payment?.id,
          },
        });

      const updatedTransaction = await dataSource
        .getRepository(Transaction)
        .findOne({
          where: {
            id: transaction?.id,
          },
        });
      const updatedSubscription = await dataSource
        .getRepository(Subscription)
        .findOne({
          where: {
            id: payment?.subscriptionId,
          },
        });
      const updatedUser = await dataSource.getRepository(User).findOne({
        where: {
          id: testUser.userId,
        },
      });

      expect(updatedPayment?.status).toBe('COMPLETED');
      expect(updatedPayment?.paidDate).toBeDefined();
      expect(updatedTransaction?.status).toBe(TransactionStatus.SUCCESS);
      expect(updatedSubscription?.status).toBe(SubscriptionStatus.ACTIVE);
      expect(updatedSubscription?.tier).toBe(targetPlan.tier);
      expect(updatedUser?.tier).toBe(targetPlan.tier);
    });
  });
});
