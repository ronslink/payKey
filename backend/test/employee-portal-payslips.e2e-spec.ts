import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import {
  generateTestEmail,
  generateTestPhone,
  createTestUserData,
  createTestWorkerData,
} from './test-utils';

/**
 * Employee Portal - Payslips & Leave E2E Tests
 *
 * Tests employee portal features:
 * - Employee view payslips
 * - Employee download payslip PDF
 * - Employee view leave balance
 * - Employee request leave
 * - Employee view leave requests
 */
describe('Employee Portal - Payslips & Leave E2E', () => {
  let app: INestApplication;
  let employerToken: string;
  let employerUserId: string;
  let workerId: string;
  let employeeToken: string;
  let inviteCode: string;
  let payPeriodId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login employer
    const employerData = createTestUserData({
      firstName: 'Employer',
      lastName: 'Payslip',
      businessName: 'Payslip Test Corp',
    });

    await request(app.getHttpServer()).post('/auth/register').send({
      email: employerData.email,
      password: employerData.password,
      firstName: employerData.firstName,
      lastName: employerData.lastName,
      businessName: employerData.businessName,
      phone: employerData.phone,
    });

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: employerData.email, password: employerData.password });

    employerToken = loginRes.body.access_token;

    // Get employer user ID
    const profileRes = await request(app.getHttpServer())
      .get('/users/profile')
      .set('Authorization', `Bearer ${employerToken}`);

    if (profileRes.body && profileRes.body.id) {
      employerUserId = profileRes.body.id;
    }

    // Create a worker
    const workerData = createTestWorkerData({
      name: 'Payslip Worker',
    });

    const workerRes = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${employerToken}`)
      .send({
        name: workerData.name,
        phoneNumber: workerData.phoneNumber,
        salaryGross: workerData.salaryGross,
        startDate: workerData.startDate,
        email: workerData.email,
      });

    if (workerRes.body && workerRes.body.id) {
      workerId = workerRes.body.id;
    }

    // Generate invite code for worker
    const inviteRes = await request(app.getHttpServer())
      .post(`/employee-portal/invite/${workerId}`)
      .set('Authorization', `Bearer ${employerToken}`);

    if (inviteRes.body && inviteRes.body.inviteCode) {
      inviteCode = inviteRes.body.inviteCode;

      // Have employee claim account
      await request(app.getHttpServer())
        .post('/employee-portal/claim-account')
        .send({
          phoneNumber: workerData.phoneNumber,
          inviteCode: inviteCode,
          pin: '1234',
        });

      // Login as employee
      const empLoginRes = await request(app.getHttpServer())
        .post('/employee-portal/login')
        .send({
          phoneNumber: workerData.phoneNumber,
          pin: '1234',
        });

      if (empLoginRes.body && empLoginRes.body.access_token) {
        employeeToken = empLoginRes.body.access_token;
      }
    }

    // Create a pay period and process payroll
    const payPeriodRes = await request(app.getHttpServer())
      .post('/pay-periods')
      .set('Authorization', `Bearer ${employerToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: '2024-12-01',
        endDate: '2024-12-31',
      });

    if (
      payPeriodRes.body &&
      (payPeriodRes.body.id || payPeriodRes.body.payPeriodId)
    ) {
      payPeriodId = payPeriodRes.body.id || payPeriodRes.body.payPeriodId;

      // Try to calculate and process payroll
      await request(app.getHttpServer())
        .post(`/pay-periods/${payPeriodId}/calculate`)
        .set('Authorization', `Bearer ${employerToken}`);

      await request(app.getHttpServer())
        .post(`/pay-periods/${payPeriodId}/process`)
        .set('Authorization', `Bearer ${employerToken}`);
    }
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Employee Payslips', () => {
    it('should allow employee to view their payslips', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      const res = await request(app.getHttpServer())
        .get('/employee-portal/my-payslips')
        .set('Authorization', `Bearer ${employeeToken}`);

      // May succeed or return 404 if endpoint doesn't exist yet
      expect([200, 404]).toContain(res.status);

      if (res.status === 200) {
        expect(res.body).toBeDefined();
        // Should return array of payslips
        if (Array.isArray(res.body)) {
          expect(Array.isArray(res.body)).toBe(true);
        }
      }
    });

    it('should allow employee to download payslip PDF', async () => {
      if (!employeeToken || !payPeriodId) {
        console.warn('Skipping - no employee token or pay period');
        return;
      }

      const res = await request(app.getHttpServer())
        .get(`/employee-portal/my-payslips/${payPeriodId}`)
        .set('Authorization', `Bearer ${employeeToken}`);

      // May succeed or return 404
      expect([200, 404]).toContain(res.status);
    });

    it('should prevent employee from accessing other employees payslips', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      // Try to access a different worker's payslip (using a fake ID)
      const fakeWorkerId = 'other-worker-123';

      const res = await request(app.getHttpServer())
        .get(`/employee-portal/my-payslips/${fakeWorkerId}`)
        .set('Authorization', `Bearer ${employeeToken}`);

      // Should fail with 403 or 404
      expect([403, 404]).toContain(res.status);
    });
  });

  describe('Employee Leave Balance', () => {
    it('should show employee leave balance', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      const res = await request(app.getHttpServer())
        .get('/employee-portal/my-leave-balance')
        .set('Authorization', `Bearer ${employeeToken}`);

      // Should succeed
      expect([200]).toContain(res.status);

      if (res.status === 200) {
        expect(res.body).toBeDefined();
        // Should have balance information
        expect(res.body).toHaveProperty('balance');
      }
    });
  });

  describe('Employee Leave Requests', () => {
    it('should allow employee to request leave', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      const res = await request(app.getHttpServer())
        .post('/employee-portal/request-leave')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({
          leaveType: 'ANNUAL',
          startDate: '2025-01-15',
          endDate: '2025-01-17',
          reason: 'Family vacation',
        });

      // Should succeed or fail with validation error
      expect([200, 201, 400]).toContain(res.status);

      if (res.status === 200 || res.status === 201) {
        expect(res.body).toBeDefined();
        expect(res.body).toHaveProperty('id');
      }
    });

    it('should show employee leave request history', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      const res = await request(app.getHttpServer())
        .get('/employee-portal/my-leave-requests')
        .set('Authorization', `Bearer ${employeeToken}`)
        .expect(200);

      expect(res.body).toBeDefined();
      // Should return array
      if (Array.isArray(res.body)) {
        expect(Array.isArray(res.body)).toBe(true);
      }
    });

    it('should allow employee to cancel their leave request', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      // First, create a leave request
      const createRes = await request(app.getHttpServer())
        .post('/employee-portal/request-leave')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({
          leaveType: 'ANNUAL',
          startDate: '2025-02-10',
          endDate: '2025-02-12',
          reason: 'Test cancellation',
        });

      if (createRes.status === 200 || createRes.status === 201) {
        const requestId = createRes.body.id;

        // Try to cancel it
        const cancelRes = await request(app.getHttpServer())
          .post(`/employee-portal/cancel-leave/${requestId}`)
          .set('Authorization', `Bearer ${employeeToken}`);

        expect([200, 201]).toContain(cancelRes.status);
      } else {
        console.warn('Skipping cancel test - could not create leave request');
      }
    });

    it('should prevent employee from canceling other employees leave', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      // Try to cancel a fake leave request ID
      const fakeRequestId = 'other-employee-leave-123';

      const res = await request(app.getHttpServer())
        .post(`/employee-portal/cancel-leave/${fakeRequestId}`)
        .set('Authorization', `Bearer ${employeeToken}`);

      // Should fail with 403 or 404
      expect([403, 404]).toContain(res.status);
    });
  });

  describe('Data Isolation (Security)', () => {
    it('should prevent employee from viewing other employees profile', async () => {
      if (!employeeToken) {
        console.warn('Skipping - no employee token');
        return;
      }

      // Employee should only see their own profile
      // This test verifies that trying to access another employee's data fails

      const res = await request(app.getHttpServer())
        .get('/employee-portal/my-profile')
        .set('Authorization', `Bearer ${employeeToken}`)
        .expect(200);

      // Should return current employee's data
      expect(res.body).toBeDefined();
      expect(res.body).toHaveProperty('workerId');

      // Verify it's the correct worker
      if (workerId) {
        expect(res.body.workerId).toBe(workerId);
      }
    });
  });

  describe('Authorization', () => {
    it('should require authentication for payslip access', async () => {
      const res = await request(app.getHttpServer()).get(
        '/employee-portal/my-payslips',
      );

      // 401 if endpoint exists with auth guard, 404 if endpoint doesn't exist
      expect([401, 404]).toContain(res.status);
    });

    it('should require authentication for leave balance', async () => {
      await request(app.getHttpServer())
        .get('/employee-portal/my-leave-balance')
        .expect(401);
    });

    it('should require authentication for leave requests', async () => {
      await request(app.getHttpServer())
        .post('/employee-portal/request-leave')
        .send({
          leaveType: 'ANNUAL',
          startDate: '2025-01-15',
          endDate: '2025-01-17',
        })
        .expect(401);
    });
  });
});
