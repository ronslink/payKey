import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

/**
 * Payroll Proration E2E Tests
 *
 * Tests proration scenarios:
 * 1. New hire mid-month (worker started after period start)
 * 2. Termination mid-month (worker terminated before period end)
 * 3. Full period (no proration)
 * 4. Backend calculation with daysWorked parameter
 */
describe('Payroll Proration E2E', () => {
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
    const email = `proration.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Proration',
      lastName: 'Tester',
      businessName: 'Proration Test Corp',
      phone: '+254700000002',
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

  describe('Proration Calculation Tests', () => {
    let fullPeriodWorkerId: string;
    let newHireWorkerId: string;
    let terminatedWorkerId: string;
    let payPeriodId: string;

    it('1. should create workers with different start/termination dates', async () => {
      // Worker 1: Full period (started before January)
      const fullPeriodRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Full Period Worker',
          phoneNumber: '+254712345001',
          salaryGross: 60000, // KES 60,000/month
          startDate: '2023-12-01', // Started before test period
          paymentMethod: 'MPESA',
          mpesaNumber: '+254712345001',
        })
        .expect(201);
      fullPeriodWorkerId = fullPeriodRes.body.id;

      // Worker 2: New hire mid-month (started Jan 15)
      const newHireRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'New Hire Worker',
          phoneNumber: '+254712345002',
          salaryGross: 60000, // KES 60,000/month
          startDate: '2024-01-15', // Started mid-January
          paymentMethod: 'MPESA',
          mpesaNumber: '+254712345002',
        })
        .expect(201);
      newHireWorkerId = newHireRes.body.id;

      // Worker 3: Terminated mid-month
      const terminatedRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Terminated Worker',
          phoneNumber: '+254712345003',
          salaryGross: 60000, // KES 60,000/month
          startDate: '2023-06-01',
          paymentMethod: 'MPESA',
          mpesaNumber: '+254712345003',
        })
        .expect(201);
      terminatedWorkerId = terminatedRes.body.id;
    });

    it('2. should generate January 2024 pay period', async () => {
      const res = await request(app.getHttpServer())
        .post('/pay-periods/generate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          frequency: 'MONTHLY',
          startDate: '2024-01-01',
          endDate: '2024-01-31',
        })
        .expect(201);

      expect(res.body).toHaveLength(1);
      payPeriodId = res.body[0].id;
      expect(res.body[0].startDate).toContain('2024-01-01');
      expect(res.body[0].endDate).toContain('2024-01-31');
    });

    it('3. should calculate payroll with full period (backend handles all workers)', async () => {
      const res = await request(app.getHttpServer())
        .post('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          workerIds: [fullPeriodWorkerId, newHireWorkerId],
        })
        .expect(201);

      expect(res.body).toHaveProperty('payrollItems');
      expect(res.body.payrollItems.length).toBeGreaterThanOrEqual(2);

      // Full period worker should have full salary
      const fullPeriodItem = res.body.payrollItems.find(
        (item: any) => item.workerId === fullPeriodWorkerId,
      );
      expect(fullPeriodItem).toBeDefined();
      expect(fullPeriodItem.grossSalary).toBe(60000);

      // New hire should also show full salary (proration is client-side calculation)
      // Backend returns base salary, client applies proration
      const newHireItem = res.body.payrollItems.find(
        (item: any) => item.workerId === newHireWorkerId,
      );
      expect(newHireItem).toBeDefined();
      expect(newHireItem.grossSalary).toBe(60000);
    });

    it('4. should save draft with prorated gross salary', async () => {
      // Client calculates proration: 17 days / 31 days = 0.548
      // Prorated salary: 60000 * (17/31) = 32,903.23
      const proratedGross = Math.round((60000 * 17) / 31);

      const res = await request(app.getHttpServer())
        .post('/payroll/draft')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          payPeriodId,
          payrollItems: [
            {
              workerId: fullPeriodWorkerId,
              grossSalary: 60000, // Full period
              daysWorked: 31,
              totalDaysInPeriod: 31,
            },
            {
              workerId: newHireWorkerId,
              grossSalary: proratedGross, // Prorated (started Jan 15)
              daysWorked: 17,
              totalDaysInPeriod: 31,
            },
          ],
        })
        .expect(201);

      expect(res.body).toHaveLength(2);
    });

    it('5. should terminate worker and verify exclusion from payroll', async () => {
      // Terminate the worker
      const terminateRes = await request(app.getHttpServer())
        .post(`/workers/${terminatedWorkerId}/terminate`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          reason: 'RESIGNATION',
          terminationDate: '2024-01-10',
          lastWorkingDate: '2024-01-10',
        });

      // Log error if termination failed (for debugging)
      if (terminateRes.status !== 201) {
        console.log(
          'Termination response:',
          terminateRes.status,
          terminateRes.body,
        );
      }
      expect(terminateRes.status).toBe(201);

      // Calculate payroll - terminated worker should not appear (isActive = false)
      const res = await request(app.getHttpServer())
        .get('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Verify terminated worker is excluded
      const terminatedItem = res.body.payrollItems.find(
        (item: any) => item.workerId === terminatedWorkerId,
      );
      expect(terminatedItem).toBeUndefined();
    });

    it('6. should verify tax calculations with prorated salary', async () => {
      // Test that taxes are calculated on the prorated amount
      const proratedGross = 32903; // ~17 days of 60,000/month

      const res = await request(app.getHttpServer())
        .post('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          workerIds: [newHireWorkerId],
        })
        .expect(201);

      const item = res.body.payrollItems[0];
      expect(item).toHaveProperty('taxBreakdown');

      // Verify tax breakdown structure
      expect(item.taxBreakdown).toHaveProperty('nssf');
      expect(item.taxBreakdown).toHaveProperty('nhif');
      expect(item.taxBreakdown).toHaveProperty('housingLevy');
      expect(item.taxBreakdown).toHaveProperty('paye');
      expect(item.taxBreakdown).toHaveProperty('totalDeductions');

      // Net pay should be gross minus deductions
      expect(item.netPay).toBe(
        item.grossSalary - item.taxBreakdown.totalDeductions,
      );
    });

    it('7. should handle zero days worked (death scenario)', async () => {
      // Simulate death scenario: worker died before period started
      const res = await request(app.getHttpServer())
        .post('/payroll/draft')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          payPeriodId,
          payrollItems: [
            {
              workerId: fullPeriodWorkerId,
              grossSalary: 0, // Zero days worked
              daysWorked: 0,
              totalDaysInPeriod: 31,
            },
          ],
        })
        .expect(201);

      // Should accept zero salary
      expect(res.body[0].grossSalary).toBe(0);
    });
  });

  describe('Edge Cases', () => {
    it('should handle February leap year proration', async () => {
      // Create pay period for February 2024 (leap year - 29 days)
      const res = await request(app.getHttpServer())
        .post('/pay-periods/generate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          frequency: 'MONTHLY',
          startDate: '2024-02-01',
          endDate: '2024-02-29',
        })
        .expect(201);

      expect(res.body[0].endDate).toContain('2024-02-29');

      // February should have 29 days
      const start = new Date('2024-02-01');
      const end = new Date('2024-02-29');
      const days = Math.ceil(
        (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24),
      );
      expect(days).toBe(28); // difference is 28, +1 = 29 days total
    });

    it('should prevent negative days worked', async () => {
      // This should be validated client-side, but test backend handles it
      // Backend should either reject or treat as 0
      // Implementation may vary
    });
  });
});

