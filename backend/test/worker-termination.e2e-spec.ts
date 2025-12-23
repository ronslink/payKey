import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Worker Termination E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let userId: string;
  let workerId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register a new user
    const email = `term.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Term',
      lastName: 'Tester',
      businessName: 'Term Inc',
      phone: '+254700000003',
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
      await app.close();
    }
  });

  it('1. Should add a worker to verify termination', async () => {
    const res = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Terminator Target',
        phoneNumber: '+254712345679',
        salaryGross: 60000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: '+254712345679',
      })
      .expect(201);

    workerId = res.body.id;
    expect(workerId).toBeDefined();
    expect(res.body.isActive).toBe(true);
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

    expect(Array.isArray(res.body)).toBe(true);
    const worker = res.body.find((w: any) => w.id === workerId);
    expect(worker).toBeDefined();
  });

  it('3. Should calculate final payment before termination', async () => {
    const res = await request(app.getHttpServer())
      .post(`/workers/${workerId}/calculate-final-payment`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        terminationDate: new Date().toISOString(),
      })
      .expect(201); // Controller returns 201 for POST by default

    expect(res.body.proratedSalary).toBeDefined();
    expect(res.body.taxDeductions).toBeDefined();
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

    expect(res.body.id).toBeDefined(); // Termination record ID
    expect(res.body.workerId).toBe(workerId);
    expect(res.body.reason).toBe('RESIGNATION');
  });

  it('5. Should verify worker status is inactive', async () => {
    const res = await request(app.getHttpServer())
      .get(`/workers/${workerId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(res.body.isActive).toBe(false);
    expect(res.body.terminationId).toBeDefined();
  });

  it('6. Should not show terminated worker in default list', async () => {
    const res = await request(app.getHttpServer())
      .get('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const worker = res.body.find((w: any) => w.id === workerId);
    expect(worker).toBeUndefined();
  });

  it('7. Should verify termination history', async () => {
    const res = await request(app.getHttpServer())
      .get('/workers/terminated/history')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const history = res.body.find((t: any) => t.workerId === workerId);
    expect(history).toBeDefined();
    expect(history.reason).toBe('RESIGNATION');
  });

  it('8. Should verify payroll record and tax submission created', async () => {
    // Get all payroll records
    const payrollRes = await request(app.getHttpServer())
      .get('/payroll-records')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // Find the record for this worker
    // Since we created multiple pay periods, we need to find the one covering 'today'
    // But simply checking if *any* finalized record exists for this worker is enough for this test context
    const record = payrollRes.body.find(
      (p: any) => p.workerId === workerId && p.status === 'finalized',
    );
    expect(record).toBeDefined();
    expect(parseFloat(record.grossSalary)).toBeGreaterThan(0);

    // Get tax submissions
    const taxRes = await request(app.getHttpServer())
      .get('/taxes/submissions')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // Find submission for the PayPeriod of the record
    const submission = taxRes.body.find(
      (s: any) => s.payPeriod.id === record.payPeriodId,
    );
    expect(submission).toBeDefined();
    // Check Housing Levy which is 1.5% of gross, so must be > 0 for any salary
    expect(parseFloat(submission.totalHousingLevy)).toBeGreaterThan(0);
  });
});
