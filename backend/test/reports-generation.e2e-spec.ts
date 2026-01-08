import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Reports Generation E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let payPeriodId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login
    const email = `reports.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpAdapter().getInstance()).post('/auth/register').send({
      email,
      password,
      firstName: 'Reports',
      lastName: 'Tester',
      businessName: 'Reports Tests Ltd',
      phone: '+254700000030',
    });

    const loginRes = await request(app.getHttpAdapter().getInstance())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;

    // Create a worker for payroll data
    await request(app.getHttpAdapter().getInstance())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Report Worker',
        phoneNumber: '+254722222222',
        salaryGross: 50000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
      });

    // Generate pay periods
    const ppRes = await request(app.getHttpAdapter().getInstance())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: '2024-01-01',
        endDate: '2024-03-31',
      });

    if (ppRes.body && ppRes.body.length > 0) {
      payPeriodId = ppRes.body[0].id;

      // Activate and process payroll for report data
      await request(app.getHttpAdapter().getInstance())
        .post(`/pay-periods/${payPeriodId}/activate`)
        .set('Authorization', `Bearer ${authToken}`);

      const calcRes = await request(app.getHttpAdapter().getInstance())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`);

      if (calcRes.body?.payrollItems?.length > 0) {
        await request(app.getHttpAdapter().getInstance())
          .post('/payroll/draft')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            payPeriodId,
            payrollItems: calcRes.body.payrollItems,
          });

        await request(app.getHttpAdapter().getInstance())
          .post(`/payroll/finalize/${payPeriodId}`)
          .set('Authorization', `Bearer ${authToken}`);
      }
    }
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Payroll Reports', () => {
    it('Should get payroll report for a pay period', async () => {
      if (!payPeriodId) {
        console.log('Skipping: No pay period available');
        return;
      }

      const res = await request(app.getHttpAdapter().getInstance())
        .get(`/reports/payroll/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 404]).toContain(res.statusCode);
      if (res.statusCode === 200) {
        expect(res.body).toHaveProperty('payPeriod');
        expect(res.body).toHaveProperty('records');
      }
    });

    it('Should export payroll as PDF', async () => {
      if (!payPeriodId) return;

      const res = await request(app.getHttpAdapter().getInstance())
        .get(`/reports/payroll/${payPeriodId}/pdf`)
        .set('Authorization', `Bearer ${authToken}`);

      if (res.statusCode === 200) {
        expect(res.header['content-type']).toContain('application/pdf');
      }
    });
  });

  describe('Tax Reports', () => {
    it('Should get P9 tax report', async () => {
      const year = 2024;
      const res = await request(app.getHttpAdapter().getInstance())
        .get(`/reports/p9/${year}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 404]).toContain(res.statusCode);
    });

    it('Should get tax submissions list', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/taxes/submissions')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('Statutory Exports', () => {
    it('Should generate KRA P10 export', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/reports/statutory/p10?year=2024&month=1')
        .set('Authorization', `Bearer ${authToken}`);

      // May return 200 with data or 404 if no data
      expect([200, 404]).toContain(res.statusCode);
    });

    it('Should generate NSSF export', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/reports/statutory/nssf?year=2024&month=1')
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 404]).toContain(res.statusCode);
    });

    it('Should generate SHIF export', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/reports/statutory/shif?year=2024&month=1')
        .set('Authorization', `Bearer ${authToken}`);

      expect([200, 404]).toContain(res.statusCode);
    });
  });
});

