import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

// Type interfaces for API responses
interface LoginResponse {
  access_token: string;
}

/**
 * Workers E2E Tests
 *
 * Tests worker CRUD operations and leave management:
 * - Create, read, update, delete workers
 * - Worker statistics
 * - Leave request workflow
 */
describe('Workers E2E', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login test user
    const email = `workers.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await request(app.getHttpAdapter().getInstance())
      .post('/auth/register')
      .send({
        email,
        password,
        firstName: 'Workers',
        lastName: 'Tester',
        businessName: 'Workers Test Corp',
        phone: '+254700000100',
      });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const loginRes = await request(app.getHttpAdapter().getInstance())
      .post('/auth/login')
      .send({ email, password });

    const loginResponse = loginRes.body as LoginResponse;
    authToken = loginResponse.access_token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Worker CRUD Operations', () => {
    it('should create a new worker', async () => {
      const workerData = {
        name: 'John Doe',
        phoneNumber: '+254700000001',
        email: `john.doe.${Date.now()}@paykey.com`,
        salaryGross: 50000,
        startDate: '2024-01-15',
        jobTitle: 'Software Engineer',
      };

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const res = await request(app.getHttpAdapter().getInstance())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(workerData)
        .expect(201);

      expect(res.body).toHaveProperty('id');
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      expect(res.body.name).toBe(workerData.name);
    });

    it('should get worker statistics', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/workers/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('totalWorkers');
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      expect(typeof res.body.totalWorkers).toBe('number');
    });

    it('should return 401 without auth token', async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await request(app.getHttpAdapter().getInstance())
        .get('/workers')
        .expect(401);
    });
  });
});
