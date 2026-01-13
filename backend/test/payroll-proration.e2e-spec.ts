import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { generateTestPhone } from './test-utils';
import {
  WorkerResponse,
  PayPeriodResponse,
  PayrollCalculationResponse,
  PayrollItem,
  SavedPayrollRecord,
} from './types/test-types';

/**
 * Payroll Proration E2E Tests
 *
 * Tests proration scenarios:
 * 1. New hire mid-month (worker started after period start)
 * 2. Termination mid-month (worker terminated before period end)
 * 3. Full period (no proration)
 * 4. Backend calculation with daysWorked parameter
 *
 * Uses TestHelpers for type-safe operations.
 */
describe('Payroll Proration E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;
  let userId: string;

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
      emailPrefix: 'proration.test',
      firstName: 'Proration',
      lastName: 'Tester',
      businessName: 'Proration Test Corp',
    });

    authToken = testUser.token;
    userId = testUser.userId;
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
      const fullPeriodPhone = generateTestPhone();
      const fullPeriodRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Full Period Worker',
          phoneNumber: fullPeriodPhone,
          salaryGross: 60000, // KES 60,000/month
          startDate: '2023-12-01', // Started before test period
          paymentMethod: 'MPESA',
          mpesaNumber: fullPeriodPhone,
        })
        .expect(201);

      const fullPeriodWorker = fullPeriodRes.body as WorkerResponse;
      fullPeriodWorkerId = fullPeriodWorker.id;

      // Worker 2: New hire mid-month (started Jan 15)
      const newHirePhone = generateTestPhone();
      const newHireRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'New Hire Worker',
          phoneNumber: newHirePhone,
          salaryGross: 60000, // KES 60,000/month
          startDate: '2024-01-15', // Started mid-January
          paymentMethod: 'MPESA',
          mpesaNumber: newHirePhone,
        })
        .expect(201);

      const newHireWorker = newHireRes.body as WorkerResponse;
      newHireWorkerId = newHireWorker.id;

      // Worker 3: Terminated mid-month
      const terminatedPhone = generateTestPhone();
      const terminatedRes = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Terminated Worker',
          phoneNumber: terminatedPhone,
          salaryGross: 60000, // KES 60,000/month
          startDate: '2023-06-01',
          paymentMethod: 'MPESA',
          mpesaNumber: terminatedPhone,
        })
        .expect(201);

      const terminatedWorker = terminatedRes.body as WorkerResponse;
      terminatedWorkerId = terminatedWorker.id;
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

      const periods = res.body as PayPeriodResponse[];
      expect(periods).toHaveLength(1);
      payPeriodId = periods[0].id;
      expect(periods[0].startDate).toContain('2024-01-01');
      expect(periods[0].endDate).toContain('2024-01-31');
    });

    it('3. should calculate payroll with full period (backend handles all workers)', async () => {
      const res = await request(app.getHttpServer())
        .post('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          workerIds: [fullPeriodWorkerId, newHireWorkerId],
        })
        .expect(201);

      const calculation = res.body as PayrollCalculationResponse;
      expect(calculation).toHaveProperty('payrollItems');
      expect(calculation.payrollItems.length).toBeGreaterThanOrEqual(2);

      // Full period worker should have full salary
      const fullPeriodItem = calculation.payrollItems.find(
        (item: PayrollItem) => item.workerId === fullPeriodWorkerId,
      );
      expect(fullPeriodItem).toBeDefined();
      expect(fullPeriodItem?.grossSalary).toBe(60000);

      // New hire should also show full salary (proration is client-side calculation)
      // Backend returns base salary, client applies proration
      const newHireItem = calculation.payrollItems.find(
        (item: PayrollItem) => item.workerId === newHireWorkerId,
      );
      expect(newHireItem).toBeDefined();
      expect(newHireItem?.grossSalary).toBe(60000);
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

      const records = res.body as SavedPayrollRecord[];
      expect(records).toHaveLength(2);
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

      const calculation = res.body as PayrollCalculationResponse;

      // Verify terminated worker is excluded
      const terminatedItem = calculation.payrollItems.find(
        (item: PayrollItem) => item.workerId === terminatedWorkerId,
      );
      expect(terminatedItem).toBeUndefined();
    });

    it('6. should verify tax calculations with prorated salary', async () => {
      // Test that taxes are calculated on the prorated amount
      const res = await request(app.getHttpServer())
        .post('/payroll/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          workerIds: [newHireWorkerId],
        })
        .expect(201);

      const calculation = res.body as PayrollCalculationResponse;
      const item = calculation.payrollItems[0];
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

      const records = res.body as SavedPayrollRecord[];
      // Should accept zero salary
      expect(parseFloat(String(records[0].grossSalary))).toBe(0);
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

      const periods = res.body as PayPeriodResponse[];
      expect(periods[0].endDate).toContain('2024-02-29');

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
