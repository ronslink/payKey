import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

/**
 * Subscription Payments E2E Tests
 *
 * Tests subscription and payment features:
 * - List subscription plans
 * - Get current subscription
 * - Usage tracking
 * - Payment history
 */
describe('Subscription Payments E2E', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login test user
    const email = `subscriptions.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpAdapter().getInstance()).post('/auth/register').send({
      email,
      password,
      firstName: 'Subscriptions',
      lastName: 'Tester',
      businessName: 'Subscriptions Test Corp',
      phone: '+254700000600',
    });

    const loginRes = await request(app.getHttpAdapter().getInstance())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Subscription Plans', () => {
    it('should list available subscription plans', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/plans')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);
      expect(res.body[0]).toHaveProperty('tier');
      expect(res.body[0]).toHaveProperty('name');
      expect(res.body[0]).toHaveProperty('price_usd');
    });
  });

  describe('Current Subscription', () => {
    it('should get current subscription (defaults to FREE)', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/current')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('tier');
      // New users should be on FREE tier
      expect(res.body.tier).toBe('FREE');
    });
  });

  describe('Usage Tracking', () => {
    it('should get usage statistics', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/usage')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('currentPlan');
      expect(res.body).toHaveProperty('workerUsage');
      expect(res.body).toHaveProperty('workerLimit');
      expect(res.body).toHaveProperty('usagePercentage');
    });
  });

  describe('Payment History', () => {
    it('should get payment history', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/payment-history')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('Stripe Integration', () => {
    it('should get Stripe status', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/stripe-status')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Returns account info or error
      expect(res.body).toBeDefined();
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access', async () => {
      await request(app.getHttpAdapter().getInstance())
        .get('/payments/subscriptions/current')
        .expect(401);
    });
  });
});

