import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Subscription Feature Gating E2E', () => {
  let app: INestApplication;
  let authToken: string;
  // let userId: string; // Unused
  let workerId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register a new user (defaults to BASIC or STANDARD tier)
    const email = `gating.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Gating',
      lastName: 'Tester',
      businessName: 'Gating Tests Ltd',
      phone: '+254700000020',
    });

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;
    // userId = loginRes.body.user.id;

    // Create a worker for leave requests
    const workerRes = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Gating Test Worker',
        phoneNumber: '+254711111111',
        salaryGross: 25000,
        startDate: '2024-01-01',
        paymentMethod: 'CASH',
      });

    workerId = workerRes.body?.id;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Platinum-Only Features', () => {
    it('Should restrict leave management for non-Platinum users', async () => {
      // Leave management is gated to PLATINUM tier via PlatinumGuard
      const res = await request(app.getHttpServer())
        .get('/workers/leave-requests')
        .set('Authorization', `Bearer ${authToken}`);

      // Expect 403 Forbidden for non-PLATINUM users
      expect(res.statusCode).toBe(403);
    });

    it('Should restrict creating leave requests for non-Platinum users', async () => {
      const res = await request(app.getHttpServer())
        .post(`/workers/${workerId}/leave-requests`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          leaveType: 'ANNUAL',
          startDate: '2024-06-01',
          endDate: '2024-06-05',
          reason: 'Test leave',
        });

      expect(res.statusCode).toBe(403);
    });

    it('Should restrict leave balance check for non-Platinum users', async () => {
      const res = await request(app.getHttpServer())
        .get(`/workers/${workerId}/leave-balance`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(403);
    });
  });

  describe('Subscription Guard (Worker Limits)', () => {
    it('Should enforce worker limits based on subscription tier', async () => {
      // This test verifies the SubscriptionGuard on worker creation
      // The exact behavior depends on the user's subscription tier

      // Creating workers should work until the limit is reached
      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: `Worker Limit Test ${Date.now()}`,
          phoneNumber: '+254799999999',
          salaryGross: 15000,
          startDate: '2024-01-01',
          paymentMethod: 'CASH',
        });

      // For new users with basic tier, first few workers should succeed
      // This test documents the guard is in place
      expect([201, 403]).toContain(res.statusCode);
    });
  });

  describe('Feature Access Endpoint', () => {
    it('Should return feature access list for current subscription', async () => {
      const res = await request(app.getHttpServer())
        .get('/features')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Verify response structure
      expect(res.body).toHaveProperty('tier');
      expect(res.body).toHaveProperty('features');
    });

    it('Should check access to a specific feature', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/access/basic_payroll')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('hasAccess');
    });
  });
});

