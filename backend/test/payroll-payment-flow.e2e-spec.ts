import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { cleanupTestData } from './test-utils';
import { DataSource } from 'typeorm';
import {
  RateType,
  TaxConfig,
  TaxType,
} from '../src/modules/tax-config/entities/tax-config.entity';

describe('Payroll Payment Flow E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let _userId: string;
  let payPeriodId: string;
  let _mpesaWorkerId: string;
  let _highNetSalaryWorkerId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Clean up DB before starting
    const dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);
    await dataSource.getRepository(TaxConfig).save([
      {
        taxType: TaxType.SHIF,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-01-01'),
        configuration: { percentage: 2.75, minAmount: 300 },
        isActive: true,
      },
      {
        taxType: TaxType.HOUSING_LEVY,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-01-01'),
        configuration: { percentage: 1.5 },
        isActive: true,
      },
      {
        taxType: TaxType.NSSF_TIER1,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          tiers: [
            { name: 'Tier 1', salaryFrom: 0, salaryTo: 7000, rate: 0.06 },
          ],
        },
        isActive: true,
      },
      {
        taxType: TaxType.NSSF_TIER2,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          tiers: [
            { name: 'Tier 2', salaryFrom: 7001, salaryTo: 36000, rate: 0.06 },
          ],
        },
        isActive: true,
      },
      {
        taxType: TaxType.PAYE,
        rateType: RateType.GRADUATED,
        effectiveFrom: new Date('2024-01-01'),
        configuration: {
          brackets: [
            { from: 0, to: 24000, rate: 0.1 },
            { from: 24001, to: 32333, rate: 0.25 },
            { from: 32334, to: 500000, rate: 0.3 },
            { from: 500001, to: 800000, rate: 0.325 },
            { from: 800001, to: null, rate: 0.35 },
          ],
          personalRelief: 2400,
        },
        isActive: true,
      },
    ]);

    // Register a new user
    const email = `payment.flow.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    const _registerRes = await request(app.getHttpServer())
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
    _userId = loginRes.body.user.id;
    await dataSource.query(
      `UPDATE "users" SET "tier" = 'BASIC' WHERE "id" = $1`,
      [_userId],
    );
  });

  afterAll(async () => {
    if (app) {
      try {
        const dataSource = app.get(DataSource);
        await cleanupTestData(dataSource);
      } catch (error) {
        console.error('Cleanup failed:', error);
      }
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
    _mpesaWorkerId = res1.body.id;

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
    _highNetSalaryWorkerId = res2.body.id;
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

  it('4. Should finalize payroll and queue payment processing', async () => {
    const res = await request(app.getHttpServer())
      .post(`/payroll/finalize/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(201);

    // The finalize endpoint now queues the job and returns immediately
    expect(res.body.status).toBe('PROCESSING');
    expect(res.body.jobId).toBeDefined();
    expect(res.body.payPeriodId).toBe(payPeriodId);

    // Wait for background job to process
    await new Promise((resolve) => setTimeout(resolve, 3000));

    // Verify records exist by querying them
    const recordsRes = await request(app.getHttpServer())
      .get(`/payroll/period-records/${payPeriodId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(Array.isArray(recordsRes.body)).toBe(true);
    expect(recordsRes.body.length).toBeGreaterThanOrEqual(1);
  });
});
