import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { cleanupTestData, generateTestPhone } from './test-utils';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { DataSource } from 'typeorm';
import {
  WorkerResponse,
  PayPeriodResponse,
  PayrollCalculationResponse,
  PayrollItem,
  SavedPayrollRecord,
  FinalizeResponse,
} from './types/test-types';

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
 * 
 * Uses TestHelpers for type-safe operations.
 */
describe('Payroll E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
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

    // Create test helpers instance
    helpers = createTestHelpers(app);

    // Register and login test user
    const testUser = await helpers.createTestUser({
      emailPrefix: 'payroll.test',
      firstName: 'Payroll',
      lastName: 'Tester',
      businessName: 'Payroll Test Corp',
    });

    authToken = testUser.token;
    userId = testUser.userId;

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
      const workerPhone = generateTestPhone();

      const res = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'John Doe',
          phoneNumber: workerPhone,
          salaryGross: 50000,
          startDate: '2024-01-01',
          paymentMethod: 'MPESA',
          mpesaNumber: workerPhone,
        })
        .expect(201);

      const worker = res.body as WorkerResponse;
      expect(worker).toHaveProperty('id');
      expect(worker.name).toBe('John Doe');
      expect(worker.salaryGross).toBe(50000);
      workerId = worker.id;
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

      const periods = res.body as PayPeriodResponse[];
      expect(periods).toHaveLength(12);
      expect(periods[0]).toHaveProperty('id');
      payPeriodId = periods[0].id; // January pay period
    });

    it('3. should activate the pay period', async () => {
      const res = await request(app.getHttpServer())
        .post(`/pay-periods/${payPeriodId}/activate`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      const period = res.body as PayPeriodResponse;
      expect(period).toHaveProperty('id');
      expect(period.id).toBe(payPeriodId);
    });

    it('4. should calculate payroll', async () => {
      const res = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const calculation = res.body as PayrollCalculationResponse;
      expect(calculation).toHaveProperty('payrollItems');
      expect(Array.isArray(calculation.payrollItems)).toBe(true);
      expect(calculation.payrollItems.length).toBeGreaterThanOrEqual(1);

      const firstItem = calculation.payrollItems[0];
      expect(firstItem.workerId).toBe(workerId);
      expect(firstItem.grossSalary).toBe(50000);
    });

    it('5. should save draft payroll', async () => {
      const calcRes = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const calculation = calcRes.body as PayrollCalculationResponse;

      const res = await request(app.getHttpServer())
        .post('/payroll/draft')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          payPeriodId,
          payrollItems: calculation.payrollItems.map(
            (item: PayrollItem) => ({
              workerId: item.workerId,
              grossSalary: item.grossSalary,
            })
          ),
        })
        .expect(201);

      const savedRecords = res.body as SavedPayrollRecord[];
      expect(Array.isArray(savedRecords)).toBe(true);
      expect(savedRecords.length).toBeGreaterThanOrEqual(1);
      expect(savedRecords[0].status).toBe('draft');
      payrollRecordId = savedRecords[0].id;
    });

    it('6. should finalize payroll', async () => {
      const res = await request(app.getHttpServer())
        .post(`/payroll/finalize/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      const finalizeResponse = res.body as FinalizeResponse;

      // The finalize endpoint now queues the job and returns immediately
      expect(finalizeResponse.status).toBe('PROCESSING');
      expect(finalizeResponse.jobId).toBeDefined();
      expect(finalizeResponse.payPeriodId).toBe(payPeriodId);

      // Wait for background job to process
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Verify records by querying them
      const recordsRes = await request(app.getHttpServer())
        .get(`/payroll/period-records/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const records = recordsRes.body as SavedPayrollRecord[];
      expect(Array.isArray(records)).toBe(true);
      if (records.length > 0) {
        payrollRecordId = records[0].id;
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

      const records = res.body as SavedPayrollRecord[];
      expect(Array.isArray(records)).toBe(true);
      expect(records.length).toBeGreaterThanOrEqual(1);

      const record = records[0];
      expect(record).toHaveProperty('id');
      expect(record).toHaveProperty('status');
    });

    it('9. should get payroll statistics', async () => {
      interface PayrollStats {
        thisMonthTotal: number;
      }

      const res = await request(app.getHttpServer())
        .get('/payroll/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const stats = res.body as PayrollStats;
      expect(stats).toHaveProperty('thisMonthTotal');
      expect(typeof stats.thisMonthTotal).toBe('number');
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
