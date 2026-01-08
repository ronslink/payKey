import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

/**
 * Feature Access E2E Tests
 *
 * Tests subscription tier feature access:
 * - Get all features for user
 * - Check specific feature access
 * - Trial status
 * - Upgrade benefits
 * - Worker limits
 * - Mock data endpoints for premium features
 */
describe('Feature Access E2E', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login test user
    const email = `features.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Features',
      lastName: 'Tester',
      businessName: 'Features Test Corp',
      phone: '+254700000300',
    });

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Feature Access Endpoints', () => {
    it('should get all features for user', async () => {
      const res = await request(app.getHttpServer())
        .get('/features')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('tier');
      expect(res.body).toHaveProperty('features');
      expect(res.body.features).toHaveProperty('accessible');
      expect(res.body.features).toHaveProperty('preview');
      expect(res.body.features).toHaveProperty('locked');
      expect(res.body).toHaveProperty('allFeatures');
    });

    it('should check access to a specific feature', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/access/basic_payroll')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('hasAccess');
      expect(res.body).toHaveProperty('feature');
    });

    it('should get trial status', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/trial-status')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('isActive');
    });

    it('should get upgrade benefits for PROFESSIONAL tier', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/upgrade-benefits/professional')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('targetTier');
      expect(res.body.targetTier).toBe('PROFESSIONAL');
      expect(res.body).toHaveProperty('newFeatures');
      expect(res.body).toHaveProperty('allTierFeatures');
    });

    it('should get upgrade benefits for ENTERPRISE tier', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/upgrade-benefits/enterprise')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('targetTier');
      expect(res.body.targetTier).toBe('ENTERPRISE');
    });

    it('should check if user can add worker', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/can-add-worker')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('canAdd');
    });
  });

  describe('Mock Data Endpoints (Premium Feature Previews)', () => {
    it('should get reports data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/reports')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get time tracking data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/time-tracking')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get leave management data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/leave')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get properties data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/properties')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      // May have data or message depending on access level
      expect(res.body.accessLevel).toBeDefined();
    });

    it('should get accounting data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/accounting')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get P9 data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/p9')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get P9 data for specific year', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/p9/2024')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });

    it('should get advanced reports data', async () => {
      const res = await request(app.getHttpServer())
        .get('/features/data/advanced-reports')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('accessLevel');
      expect(res.body).toHaveProperty('data');
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access to features', async () => {
      await request(app.getHttpServer()).get('/features').expect(401);
    });

    it('should prevent access with invalid token', async () => {
      await request(app.getHttpServer())
        .get('/features')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});
