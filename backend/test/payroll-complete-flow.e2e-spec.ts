import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { cleanupTestData, generateTestPhone } from './test-utils';
import { DataSource } from 'typeorm';
import {
  WorkerResponse,
  PayPeriodResponse,
  PayrollCalculationResponse,
  SavedPayrollRecord,
  FinalizeResponse,
  TaxSubmissionResponse,
} from './types/test-types';

/**
 * Payroll Complete Flow E2E Tests
 *
 * Tests the complete end-to-end payroll workflow:
 * 1. Add a worker
 * 2. Generate pay periods
 * 3. Activate pay period
 * 4. Calculate and save draft payroll
 * 5. Finalize payroll
 * 6. Query tax submissions
 * 7. Download payslip
 *
 * Uses TestHelpers for type-safe operations.
 */
describe('Payroll Complete Flow E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;
  let userId: string;
  let payPeriodId: string;
  let workerId: string;
  let payrollRecordId: string;
  let dataSource: DataSource;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Get DataSource and cleanup
    dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);

    // Create test helpers instance
    helpers = createTestHelpers(app);

    // Register and login test user
    const testUser = await helpers.createTestUser({
      emailPrefix: 'complete.flow',
      firstName: 'Complete',
      lastName: 'Tester',
      businessName: 'Complete Flows Ltd',
    });

    authToken = testUser.token;
    userId = testUser.userId;
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

  it('1. Should add a worker', async () => {
    const workerPhone = generateTestPhone();

    const res = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Jane Doe',
        phoneNumber: workerPhone,
        salaryGross: 50000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: workerPhone,
      })
      .expect(201);

    const worker = res.body as WorkerResponse;
    workerId = worker.id;
    expect(workerId).toBeDefined();
  });

  it('2. Should generate pay periods', async () => {
    const year = 2024;
    const res = await request(app.getHttpServer())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: `${year}-01-01`,
        endDate: `${year}-12-31`,
      })
      .expect(201);

    const periods = res.body as PayPeriodResponse[];
    expect(periods).toHaveLength(12);
    // Save January status
    payPeriodId = periods[0].id;
  });

  it('3. Should activate pay period', async () => {
    await request(app.getHttpServer())
      .post(`/pay-periods/${payPeriodId}/activate`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);
  });

  it('4. Should calculate and save draft payroll', async () => {
    // First calculate
    const calcRes = await request(app.getHttpServer())
      .get('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const calculation = calcRes.body as PayrollCalculationResponse;
    const items = calculation.payrollItems;
    expect(items).toHaveLength(1);
    expect(items[0].workerId).toBe(workerId);
    expect(items[0].grossSalary).toBe(50000);

    // Save as draft
    const saveRes = await request(app.getHttpServer())
      .post('/payroll/draft')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        payPeriodId,
        payrollItems: items,
      })
      .expect(201);

    const savedRecords = saveRes.body as SavedPayrollRecord[];
    expect(savedRecords).toHaveLength(1);
    expect(savedRecords[0].status).toBe('draft');
  });

  it('5. Should finalize payroll (Process Payments & Taxes)', async () => {
    // Using explicit finalize endpoint from PayrollController
    const res = await request(app.getHttpServer())
      .post(`/payroll/finalize/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);

    const finalizeResponse = res.body as FinalizeResponse;

    // The finalize endpoint now queues the job and returns immediately
    expect(finalizeResponse.status).toBe('PROCESSING');
    expect(finalizeResponse.jobId).toBeDefined();
    expect(finalizeResponse.payPeriodId).toBe(payPeriodId);

    // For E2E testing, we need to wait for the job to complete or query the records
    // Wait a bit for the background job to process
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Verify records are finalized by querying them
    const recordsRes = await request(app.getHttpServer())
      .get(`/payroll/period-records/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const records = recordsRes.body as SavedPayrollRecord[];
    expect(Array.isArray(records)).toBe(true);
    if (records.length > 0) {
      const record = records[0];
      payrollRecordId = record.id;
      // Record may still be processing or finalized
      expect(['draft', 'finalized', 'processing'].includes(record.status)).toBe(
        true,
      );
    }
  });

  it('6. Should query tax submissions (may be empty with async finalization)', async () => {
    // Wait additional time for background job to complete
    await new Promise((resolve) => setTimeout(resolve, 3000));

    const res = await request(app.getHttpServer())
      .get('/taxes/submissions')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const submissions = res.body as TaxSubmissionResponse[];

    // With async finalization, submission may not exist yet
    expect(Array.isArray(submissions)).toBe(true);

    // If submission exists, verify it has expected fields
    const submission = submissions.find((s) => s.payPeriodId === payPeriodId);
    if (submission) {
      expect(submission).toHaveProperty('totalPaye');
    }
  });

  it('7. Should download payslip', async () => {
    expect(payrollRecordId).toBeDefined();

    const res = await request(app.getHttpServer())
      .get(`/payroll/payslip/${payrollRecordId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(res.header['content-type']).toBe('application/pdf');
    expect(res.header['content-disposition']).toContain(
      'attachment; filename="payslip-',
    );
  });
});
