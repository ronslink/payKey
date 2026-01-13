import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { generateTestPhone } from './test-utils';
import {
  WorkerResponse,
  TerminationHistoryResponse,
  PayrollRecordResponse,
  TaxSubmissionResponse,
  FinalPaymentCalculation,
} from './types/test-types';

/**
 * Worker Termination E2E Tests
 * 
 * Tests the complete worker termination flow:
 * - Adding a worker
 * - Calculating final payment
 * - Terminating the worker
 * - Verifying status changes and records
 * 
 * Uses TestHelpers for type-safe operations.
 */
describe('Worker Termination E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;
  let userId: string;
  let workerId: string;

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
      emailPrefix: 'term.test',
      firstName: 'Term',
      lastName: 'Tester',
      businessName: 'Term Inc',
    });

    authToken = testUser.token;
    userId = testUser.userId;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('1. Should add a worker to verify termination', async () => {
    const workerPhone = generateTestPhone();

    const res = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Terminator Target',
        phoneNumber: workerPhone,
        salaryGross: 60000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: workerPhone,
      })
      .expect(201);

    const worker = res.body as WorkerResponse;
    workerId = worker.id;
    expect(workerId).toBeDefined();
    expect(worker.isActive).toBe(true);
  });

  it('1.5. Should generate pay periods for the year', async () => {
    const year = new Date().getFullYear();
    await request(app.getHttpServer())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: `${year}-01-01`,
        endDate: `${year}-12-31`,
      })
      .expect(201);
  });

  it('2. Should default to only showing active workers', async () => {
    const res = await request(app.getHttpServer())
      .get('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const workers = res.body as WorkerResponse[];
    expect(Array.isArray(workers)).toBe(true);
    const worker = workers.find((w) => w.id === workerId);
    expect(worker).toBeDefined();
  });

  it('3. Should calculate final payment before termination', async () => {
    const res = await request(app.getHttpServer())
      .post(`/workers/${workerId}/calculate-final-payment`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        terminationDate: new Date().toISOString(),
      })
      .expect(201);

    const calculation = res.body as FinalPaymentCalculation;
    expect(calculation.proratedSalary).toBeDefined();
    expect(calculation.taxDeductions).toBeDefined();
  });

  it('4. Should terminate the worker', async () => {
    const res = await request(app.getHttpServer())
      .post(`/workers/${workerId}/terminate`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        reason: 'RESIGNATION',
        terminationDate: new Date().toISOString(),
        noticePeriodDays: 30,
        notes: 'Leaving for greener pastures',
      })
      .expect(201);

    const termination = res.body as TerminationHistoryResponse;
    expect(termination.id).toBeDefined();
    expect(termination.workerId).toBe(workerId);
    expect(termination.reason).toBe('RESIGNATION');
  });

  it('5. Should verify worker status is inactive', async () => {
    const res = await request(app.getHttpServer())
      .get(`/workers/${workerId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const worker = res.body as WorkerResponse;
    expect(worker.isActive).toBe(false);
    expect(worker.terminationId).toBeDefined();
  });

  it('6. Should not show terminated worker in default list', async () => {
    const res = await request(app.getHttpServer())
      .get('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const workers = res.body as WorkerResponse[];
    const worker = workers.find((w) => w.id === workerId);
    expect(worker).toBeUndefined();
  });

  it('7. Should verify termination history', async () => {
    const res = await request(app.getHttpServer())
      .get('/workers/terminated/history')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const history = res.body as TerminationHistoryResponse[];
    const record = history.find((t) => t.workerId === workerId);
    expect(record).toBeDefined();
    expect(record?.reason).toBe('RESIGNATION');
  });

  it('8. Should verify payroll record and tax submission created', async () => {
    // Get all payroll records
    const payrollRes = await request(app.getHttpServer())
      .get('/payroll-records')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const payrollRecords = payrollRes.body as PayrollRecordResponse[];

    // Find the record for this worker
    const record = payrollRecords.find(
      (p) => p.workerId === workerId && p.status === 'finalized'
    );
    expect(record).toBeDefined();
    expect(parseFloat(String(record?.grossSalary))).toBeGreaterThan(0);

    // Get tax submissions
    const taxRes = await request(app.getHttpServer())
      .get('/taxes/submissions')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const taxSubmissions = taxRes.body as TaxSubmissionResponse[];

    // Find submission for the PayPeriod of the record
    const submission = taxSubmissions.find(
      (s) => s.payPeriod.id === record?.payPeriodId
    );
    expect(submission).toBeDefined();
    // Check Housing Levy which is 1.5% of gross, so must be > 0 for any salary
    expect(parseFloat(String(submission?.totalHousingLevy))).toBeGreaterThan(0);
  });
});
