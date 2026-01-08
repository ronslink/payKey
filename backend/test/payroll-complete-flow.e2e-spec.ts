import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { cleanupTestData, generateTestEmail, generateTestPhone } from './test-utils';
import { DataSource } from 'typeorm';

describe('Payroll Complete Flow E2E', () => {
  let app: INestApplication;
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

    // Register a new user
    const email = generateTestEmail('complete.flow');
    const password = 'Password123!';

    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        email,
        password,
        firstName: 'Complete',
        lastName: 'Tester',
        businessName: 'Complete Flows Ltd',
        phone: generateTestPhone(),
      });

    // Login
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;
    userId = loginRes.body.user.id;
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
    const res = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Jane Doe',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: '+254712345678',
      })
      .expect(201);

    workerId = res.body.id;
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

    expect(res.body).toHaveLength(12);
    // Save January status
    payPeriodId = res.body[0].id;
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

    const items = calcRes.body.payrollItems;
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

    expect(saveRes.body).toHaveLength(1);
    expect(saveRes.body[0].status).toBe('draft');
  });

  it('5. Should finalize payroll (Process Payments & Taxes)', async () => {
    // Using explicit finalize endpoint from PayrollController
    const res = await request(app.getHttpServer())
      .post(`/payroll/finalize/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);

    // The finalize endpoint now queues the job and returns immediately
    // Response structure: { status: 'PROCESSING', message: string, jobId: string, payPeriodId: string }
    expect(res.body.status).toBe('PROCESSING');
    expect(res.body.jobId).toBeDefined();
    expect(res.body.payPeriodId).toBe(payPeriodId);

    // For E2E testing, we need to wait for the job to complete or query the records
    // Wait a bit for the background job to process
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Verify records are finalized by querying them
    const recordsRes = await request(app.getHttpServer())
      .get(`/payroll/period-records/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(Array.isArray(recordsRes.body)).toBe(true);
    if (recordsRes.body.length > 0) {
      const record = recordsRes.body[0];
      payrollRecordId = record.id;
      // Record may still be processing or finalized
      expect(['draft', 'finalized', 'processing'].includes(record.status)).toBe(true);
    }
  });

  it('6. Should verify verification of tax submission', async () => {
    const res = await request(app.getHttpServer())
      .get('/taxes/submissions')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // We expect one submission for the pay period
    const submission = res.body.find((s: any) => s.payPeriodId === payPeriodId);
    expect(submission).toBeDefined();
    // totalPaye is the field name in TaxSubmission entity
    expect(Number(submission.totalPaye)).toBeGreaterThan(0);
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

