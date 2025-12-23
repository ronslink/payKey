import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

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

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register a unique test user
    const email = `payroll.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Payroll',
      lastName: 'Tester',
      businessName: 'Payroll Test Corp',
      phone: '+254700000001',
    });

    // Login to get auth token
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
          phoneNumber: '+254712345678',
          salaryGross: 50000,
          startDate: '2024-01-01',
          paymentMethod: 'MPESA',
          mpesaNumber: '+254712345678',
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
      payPeriodId = res.body[0].id; // January pay period
    });

    it('3. should activate the pay period', async () => {
      await request(app.getHttpServer())
        .post(`/pay-periods/${payPeriodId}/activate`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);
    });

    it('4. should calculate payroll', async () => {
      const res = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('payrollItems');
      expect(res.body.payrollItems).toHaveLength(1);
      expect(res.body.payrollItems[0].workerId).toBe(workerId);
      expect(res.body.payrollItems[0].grossSalary).toBe(50000);
    });

    it('5. should save draft payroll', async () => {
      const calcRes = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`);

      const res = await request(app.getHttpServer())
        .post('/payroll/draft')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          payPeriodId,
          payrollItems: calcRes.body.payrollItems.map((item: any) => ({
            workerId: item.workerId,
            grossSalary: item.grossSalary,
          })),
        })
        .expect(201);

      expect(res.body).toHaveLength(1);
      expect(res.body[0].status).toBe('draft');
      payrollRecordId = res.body[0].id;
    });

    it('6. should finalize payroll', async () => {
      const res = await request(app.getHttpServer())
        .post(`/payroll/finalize/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(201);

      expect(res.body).toHaveProperty('finalizedRecords');
      expect(res.body.finalizedRecords).toHaveLength(1);
      expect(res.body.finalizedRecords[0].status).toBe('finalized');
      payrollRecordId = res.body.finalizedRecords[0].id;
    });

    it('7. should download payslip as PDF', async () => {
      const res = await request(app.getHttpServer())
        .get(`/payroll/payslip/${payrollRecordId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.headers['content-type']).toBe('application/pdf');
      expect(res.headers['content-disposition']).toContain('attachment');
    });

    it('8. should get period payroll records', async () => {
      const res = await request(app.getHttpServer())
        .get(`/payroll/period-records/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
    });

    it('9. should get payroll statistics', async () => {
      const res = await request(app.getHttpServer())
        .get('/payroll/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('thisMonthTotal');
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
});
