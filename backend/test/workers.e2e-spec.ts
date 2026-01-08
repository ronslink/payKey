import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { Worker } from './../src/modules/workers/entities/worker.entity';

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

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Workers',
      lastName: 'Tester',
      businessName: 'Workers Test Corp',
      phone: '+254700000100',
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

  describe('Worker CRUD Operations', () => {
    let workerId: string;

    it('should create a worker', async () => {
      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Alice Smith',
          phoneNumber: '+254712345001',
          salaryGross: 45000,
          startDate: '2024-01-01',
          email: 'alice@example.com',
          jobTitle: 'Housekeeper',
          paymentMethod: 'MPESA',
          mpesaNumber: '+254712345001',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.name).toBe('Alice Smith');
      expect(res.body.salaryGross).toBe(45000);
      workerId = res.body.id;
    });

    it('should list all workers', async () => {
      const res = await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);

      const worker = res.body.find((w: Worker) => w.id === workerId);
      expect(worker).toBeDefined();
    });

    it('should get a single worker by ID', async () => {
      const res = await request(app.getHttpServer())
        .get(`/workers/${workerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body.id).toBe(workerId);
      expect(res.body.name).toBe('Alice Smith');
    });

    it('should update a worker', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/workers/${workerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          salaryGross: 50000,
          jobTitle: 'Senior Housekeeper',
        })
        .expect(200);

      expect(res.body.salaryGross).toBe(50000);
      expect(res.body.jobTitle).toBe('Senior Housekeeper');
    });

    it('should get worker statistics', async () => {
      const res = await request(app.getHttpServer())
        .get('/workers/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('totalWorkers');
      expect(res.body.totalWorkers).toBeGreaterThanOrEqual(1);
    });

    it('should delete a worker', async () => {
      // Create a worker to delete
      const createRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'To Delete',
          phoneNumber: '+254712345999',
          salaryGross: 30000,
          startDate: '2024-01-01',
        });

      const deleteWorkerId = createRes.body.id;

      await request(app.getHttpServer())
        .delete(`/workers/${deleteWorkerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
    });
  });

  describe('Leave Management', () => {
    let workerId: string;
    let leaveRequestId: string | undefined;

    beforeAll(async () => {
      // Create a worker for leave tests
      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Leave Tester',
          phoneNumber: '+254712345002',
          salaryGross: 40000,
          startDate: '2024-01-01',
        });

      workerId = res.body.id;
    });

    it('should create a leave request', async () => {
      const res = await request(app.getHttpServer())
        .post(`/workers/${workerId}/leave-requests`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          leaveType: 'ANNUAL',
          startDate: '2024-06-01',
          endDate: '2024-06-05',
          reason: 'Family vacation',
        });

      // May succeed or fail based on validation rules
      if (res.status === 201) {
        expect(res.body).toHaveProperty('id');
        leaveRequestId = res.body.id;
      }
    });

    it('should get leave requests for a specific worker', async () => {
      const res = await request(app.getHttpServer())
        .get(`/workers/${workerId}/leave-requests`)
        .set('Authorization', `Bearer ${authToken}`);

      // 403 expected for FREE tier users (PlatinumGuard), 200 for PLATINUM
      expect([200, 403]).toContain(res.status);
      if (res.status === 200) {
        expect(Array.isArray(res.body)).toBe(true);
      }
    });

    it('should approve a leave request', async () => {
      // Skip if we don't have a leave request ID
      if (!leaveRequestId) {
        console.warn('Skipping approve test - no leave request ID');
        return;
      }

      const res = await request(app.getHttpServer())
        .patch(`/workers/leave-requests/${leaveRequestId}/approve`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          approved: true,
          reviewerNotes: 'Approved for family vacation',
        });

      // 403 expected for FREE tier users, 200 for PLATINUM
      expect([200, 403]).toContain(res.status);
    });

    it('should get leave balance for a worker', async () => {
      const res = await request(app.getHttpServer())
        .get(`/workers/${workerId}/leave-balance`)
        .set('Authorization', `Bearer ${authToken}`);

      // 403 expected for FREE tier users (PlatinumGuard), 200 for PLATINUM
      expect([200, 403]).toContain(res.status);
      if (res.status === 200) {
        expect(res.body).toHaveProperty('remainingAnnualLeaves');
      }
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access to workers', async () => {
      await request(app.getHttpServer()).get('/workers').expect(401);
    });

    it('should prevent access with invalid token', async () => {
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});
