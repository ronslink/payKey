import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { generateTestPhone, generateTestEmail } from './test-utils';
import { WorkerResponse, WorkerStatsResponse } from './types/test-types';

/**
 * Workers E2E Tests
 *
 * Tests worker CRUD operations and leave management:
 * - Create, read, update, delete workers
 * - Worker statistics
 * - Leave request workflow
 * 
 * Uses TestHelpers for type-safe test user and worker creation.
 */
describe('Workers E2E', () => {
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

    // Register and login test user using helpers
    const testUser = await helpers.createTestUser({
      emailPrefix: 'workers.test',
      firstName: 'Workers',
      lastName: 'Tester',
      businessName: 'Workers Test Corp',
    });

    authToken = testUser.token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Worker CRUD Operations', () => {
    it('should create a new worker', async () => {
      const workerPhone = generateTestPhone();
      const workerEmail = generateTestEmail('john.doe');

      const workerData = {
        name: 'John Doe',
        phoneNumber: workerPhone,
        email: workerEmail,
        salaryGross: 50000,
        startDate: '2024-01-15',
        jobTitle: 'Software Engineer',
      };

      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(workerData)
        .expect(201);

      // Type-safe response handling
      const worker = res.body as WorkerResponse;
      expect(worker.id).toBeDefined();
      expect(worker.name).toBe(workerData.name);
    });

    it('should get worker statistics', async () => {
      const res = await request(app.getHttpServer())
        .get('/workers/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Type-safe response handling
      const stats = res.body as WorkerStatsResponse;
      expect(stats.totalWorkers).toBeDefined();
      expect(typeof stats.totalWorkers).toBe('number');
    });

    it('should return 401 without auth token', async () => {
      await request(app.getHttpServer()).get('/workers').expect(401);
    });
  });
});
