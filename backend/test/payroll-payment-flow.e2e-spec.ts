import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Payroll Payment Flow E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let userId: string;
  let payPeriodId: string;
  let mpesaWorkerId: string;
  let highNetSalaryWorkerId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register a new user
    const email = `payment.flow.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    const registerRes = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        email,
        password,
        firstName: 'Payment',
        lastName: 'Tester',
        businessName: 'Payment Flows Ltd',
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

  it('1. Should add workers (Standard and High Salary)', async () => {
    // 1. Standard M-Pesa Worker
    const res1 = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Standard Pay Worker',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: '+254712345678',
      })
      .expect(201);
    mpesaWorkerId = res1.body.id;

    // 2. High Salary Worker > 150k limit to test splitting
    // Net Pay > 150k required.
    // If Gross is 300,000, Taxes approx:
    // PAYE (~30%) = ~90k.
    // Net = ~210k.
    // Splitting should happen.
    const res2 = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'High Roller',
        phoneNumber: '+254722222222',
        salaryGross: 300000,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        mpesaNumber: '+254722222222',
      })
      .expect(201);
    highNetSalaryWorkerId = res2.body.id;
  });

  it('2. Should generate and activate pay period', async () => {
    const year = 2024;
    const res = await request(app.getHttpServer())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: `${year}-02-01`,
        endDate: `${year}-12-31`,
      })
      .expect(201);

    payPeriodId = res.body[0].id; // Feb 2024

    await request(app.getHttpServer())
      .post(`/pay-periods/${payPeriodId}/activate`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);
  });

  it('3. Should calculate and draft payroll', async () => {
    const calcRes = await request(app.getHttpServer())
      .get('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    const items = calcRes.body.payrollItems;
    expect(items).toHaveLength(2);

    await request(app.getHttpServer())
      .post('/payroll/draft')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        payPeriodId,
        payrollItems: items,
      })
      .expect(201);
  });

  it('4. Should finalize payroll and process payments correctly', async () => {
    const res = await request(app.getHttpServer())
      .post(`/payroll/finalize/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);

    // Assert response structure detail
    const { payoutResults, finalizedRecords } = res.body;

    expect(payoutResults.successCount).toBe(2);
    expect(payoutResults.failureCount).toBe(0);
    expect(payoutResults.results).toHaveLength(2);

    // Verify Standard Worker Result
    const standardResult = payoutResults.results.find(
      (r) => r.workerId === mpesaWorkerId,
    );
    expect(standardResult.success).toBe(true);
    // Should have single transaction ID
    expect(standardResult.transactionId).not.toContain(',');

    // Verify High Salary Worker Result (Splitting)
    const highResult = payoutResults.results.find(
      (r) => r.workerId === highNetSalaryWorkerId,
    );
    expect(highResult.success).toBe(true);
    // Should have multiple transaction IDs (comma separated)
    expect(highResult.transactionId).toContain(',');
  });
});
