import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import {
  SubscriptionPlan,
  CurrentSubscriptionResponse,
  UsageResponse,
} from './types/test-types';

/**
 * Subscription Payments E2E Tests
 *
 * Tests subscription and payment features:
 * - List subscription plans
 * - Get current subscription
 * - Usage tracking
 * - Payment history
 * 
 * Uses TestHelpers for type-safe test user creation.
 */
describe('Subscription Payments E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Create test helpers instance
    helpers = createTestHelpers(app);

    // Register and login test user
    const testUser = await helpers.createTestUser({
      emailPrefix: 'subscriptions.test',
      firstName: 'Subscriptions',
      lastName: 'Tester',
      businessName: 'Subscriptions Test Corp',
    });

    authToken = testUser.token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Subscription Plans', () => {
    it('should list available subscription plans', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/plans')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const plans = res.body as SubscriptionPlan[];
      expect(Array.isArray(plans)).toBe(true);
      expect(plans.length).toBeGreaterThan(0);
      expect(plans[0]).toHaveProperty('tier');
      expect(plans[0]).toHaveProperty('name');
      expect(plans[0]).toHaveProperty('price_usd');
    });
  });

  describe('Current Subscription', () => {
    it('should get current subscription (defaults to FREE)', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/current')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const subscription = res.body as CurrentSubscriptionResponse;
      expect(subscription).toHaveProperty('tier');
      // New users should be on FREE tier
      expect(subscription.tier).toBe('FREE');
    });
  });

  describe('Usage Tracking', () => {
    it('should get usage statistics', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/usage')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const usage = res.body as UsageResponse;
      expect(usage).toHaveProperty('currentPlan');
      expect(usage).toHaveProperty('workerUsage');
      expect(usage).toHaveProperty('workerLimit');
      expect(usage).toHaveProperty('usagePercentage');
    });
  });

  describe('Payment History', () => {
    it('should get payment history', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/payment-history')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('Stripe Integration', () => {
    it('should get Stripe status', async () => {
      const res = await request(app.getHttpServer())
        .get('/payments/subscriptions/stripe-status')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Returns account info or error
      expect(res.body).toBeDefined();
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access', async () => {
      await request(app.getHttpServer())
        .get('/payments/subscriptions/current')
        .expect(401);
    });
  });
});
