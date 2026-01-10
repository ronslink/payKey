import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import {
  cleanupTestData,
  generateTestEmail,
  generateTestPhone,
} from './test-utils';
import { DataSource } from 'typeorm';

/**
 * Payroll E2E Tests
 *
 * Tests the complete payroll workflow:
 * 1. Create a worker
 * 2. Generate pay periods
 * 3. Activate a pay period
 * 4. Calculate payroll
 * 5. Save draft payroll
 * 6. Finalize payroll
 * 7. Download payslip
 */
describe('Payroll E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let userId: string;
  let dataSource: DataSource;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Get DataSource instance
    dataSource = app.get(DataSource);

    // Clean up DB before starting
    await cleanupTestData(dataSource);

    // Register a unique test user
    const email = generateTestEmail('payroll.test');
    const password = 'Password123!';

    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        email,
        password,
        firstName: 'Payroll',
        lastName: 'Tester',
        businessName: 'Payroll Test Corp',
        phone: generateTestPhone(),
      })
      .expect(201);

    // Login to get auth token
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password })
      .expect(201);

    authToken = loginRes.body.access_token;
    userId = loginRes.body.user.id;

    expect(authToken).toBeDefined();
    expect(userId).toBeDefined();
  });

  afterAll(async () => {
    if (app) {
      try {
        if (dataSource && dataSource.isInitialized) {
          await cleanupTestData(dataSource);
        }
      } catch (error) {
        console.error('Cleanup failed:', error);
      }
      await app.close();
    }
  });

  describe('Complete Payroll Workflow', () => {
    let workerId: string;
    let payPeriodId: string;
    let payrollRecordId: string;

    it('1. should create a worker', async () => {
      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'John Doe',
          phoneNumber: generateTestPhone(),
          salaryGross: 50000,
          startDate: '2024-01-01',
          paymentMethod: 'MPESA',
          mpesaNumber: generateTestPhone(),
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.name).toBe('John Doe');
      expect(res.body.salaryGross).toBe(50000);
      workerId = res.body.id;
    });

    it('2. should generate pay periods for the year', async () => {
      const res = await request(app.getHttpServer())
        .post('/pay-periods/generate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          frequency: 'MONTHLY',
          startDate: '2024-01-01',
          endDate: '2024-12-31',
        })
        .expect(201);

      expect(res.body).toHaveLength(12);
      expect(res.body[0]).toHaveProperty('id');
      payPeriodId = res.body[0].id; // January pay period
    });

    it('3. should activate the pay period', async () => {
      const res = await request(app.getHttpServer())
        .post(`/pay-periods/${payPeriodId}/activate`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.id).toBe(payPeriodId);
    });

    it('4. should calculate payroll', async () => {
      const res = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('payrollItems');
      expect(Array.isArray(res.body.payrollItems)).toBe(true);
      expect(res.body.payrollItems.length).toBeGreaterThanOrEqual(1);

      const firstItem = res.body.payrollItems[0];
      expect(firstItem.workerId).toBe(workerId);
      expect(firstItem.grossSalary).toBe(50000);
    });

    it('5. should save draft payroll', async () => {
      const calcRes = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const res = await request(app.getHttpServer())
        .post('/payroll/draft')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          payPeriodId,
          payrollItems: calcRes.body.payrollItems.map(
            (item: { workerId: string; grossSalary: number }) => ({
              workerId: item.workerId,
              grossSalary: item.grossSalary,
            }),
          ),
        })
        .expect(201);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0].status).toBe('draft');
      payrollRecordId = res.body[0].id;
    });

    it('6. should finalize payroll', async () => {
      const res = await request(app.getHttpServer())
        .post(`/payroll/finalize/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      // The finalize endpoint now queues the job and returns immediately
      expect(res.body.status).toBe('PROCESSING');
      expect(res.body.jobId).toBeDefined();
      expect(res.body.payPeriodId).toBe(payPeriodId);

      // Wait for background job to process
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Verify records by querying them
      const recordsRes = await request(app.getHttpServer())
        .get(`/payroll/period-records/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(recordsRes.body)).toBe(true);
      if (recordsRes.body.length > 0) {
        payrollRecordId = recordsRes.body[0].id;
      }
    });

    it('7. should download payslip as PDF', async () => {
      const res = await request(app.getHttpServer())
        .get(`/payroll/payslip/${payrollRecordId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.headers['content-type']).toBe('application/pdf');
      expect(res.headers['content-disposition']).toContain('attachment');
      expect(res.body).toBeDefined();
    });

    it('8. should get period payroll records', async () => {
      const res = await request(app.getHttpServer())
        .get(`/payroll/period-records/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);

      const record = res.body[0];
      expect(record).toHaveProperty('id');
      expect(record).toHaveProperty('status');
    });

    it('9. should get payroll statistics', async () => {
      const res = await request(app.getHttpServer())
        .get('/payroll/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('thisMonthTotal');
      expect(typeof res.body.thisMonthTotal).toBe('number');
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access to payroll calculate', async () => {
      await request(app.getHttpServer()).get('/payroll/calculate').expect(401);
    });

    it('should prevent access with invalid token', async () => {
      await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });

  describe('Error Handling', () => {
    it('should reject draft save without auth', async () => {
      await request(app.getHttpServer())
        .post('/payroll/draft')
        .send({
          payPeriodId: 'any-id',
          payrollItems: [],
        })
        .expect(401);
    });

    it('should reject finalize without auth', async () => {
      await request(app.getHttpServer())
        .post('/payroll/finalize/some-id')
        .expect(401);
    });
  });
});
