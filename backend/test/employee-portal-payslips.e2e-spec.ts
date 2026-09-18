import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { User, UserTier } from '../src/modules/users/entities/user.entity';
import {
  PayPeriod,
  PayPeriodFrequency,
} from '../src/modules/payroll/entities/pay-period.entity';
import {
  PayrollRecord,
  PayrollStatus,
} from '../src/modules/payroll/entities/payroll-record.entity';
import { createTestUserData, createTestWorkerData } from './test-utils';

describe('Employee Portal - Payslips & Leave E2E', () => {
  let app: INestApplication;
  let employerToken: string;
  let employerId: string;
  let workerId: string;
  let employeeToken: string;
  let otherEmployeeToken: string;
  let finalizedRecord: PayrollRecord;
  let paidRecord: PayrollRecord;
  let draftRecord: PayrollRecord;
  let otherRecord: PayrollRecord;

  async function createEmployee(name: string) {
    const workerData = createTestWorkerData({ name });
    const worker = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${employerToken}`)
      .send(workerData)
      .expect(201);
    expect(worker.body.id).toEqual(expect.any(String));
    const invite = await request(app.getHttpServer())
      .post(`/employee-portal/invite/${worker.body.id}`)
      .set('Authorization', `Bearer ${employerToken}`)
      .expect(201);
    expect(invite.body.inviteCode).toEqual(expect.any(String));
    const claim = await request(app.getHttpServer())
      .post('/employee-portal/claim-account')
      .send({
        phoneNumber: workerData.phoneNumber,
        inviteCode: invite.body.inviteCode,
        pin: '1234',
      })
      .expect(201);
    expect(claim.body.accessToken).toEqual(expect.any(String));
    const login = await request(app.getHttpServer())
      .post('/employee-portal/login')
      .send({ phoneNumber: workerData.phoneNumber, pin: '1234' })
      .expect(201);
    expect(login.body.accessToken).toEqual(expect.any(String));
    expect(login.body.user.linkedWorkerId).toBe(worker.body.id);
    return {
      workerId: worker.body.id as string,
      token: login.body.accessToken as string,
    };
  }

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    await app.init();
    const dataSource = app.get(DataSource);
    if (
      process.env.NODE_ENV !== 'test' ||
      !String(dataSource.options.database).endsWith('_test')
    ) {
      throw new Error('Employee fixtures require a dedicated test database');
    }

    const employer = createTestUserData({
      firstName: 'Employer',
      lastName: 'Payslip',
    });
    const registered = await request(app.getHttpServer())
      .post('/auth/register')
      .send(employer)
      .expect(201);
    employerId = registered.body.user.id;
    expect(employerId).toEqual(expect.any(String));
    // A fixture grants feature access; never invoke a payment provider to set up tests.
    await dataSource
      .getRepository(User)
      .update(employerId, { tier: UserTier.PLATINUM });
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: employer.email, password: employer.password })
      .expect(201);
    employerToken = login.body.access_token;
    expect(employerToken).toEqual(expect.any(String));

    const employee = await createEmployee('Payslip Worker');
    workerId = employee.workerId;
    employeeToken = employee.token;
    const otherEmployee = await createEmployee('Another Worker');
    otherEmployeeToken = otherEmployee.token;

    const period = await dataSource.getRepository(PayPeriod).save({
      userId: employerId,
      name: 'Employee payslip fixture',
      frequency: PayPeriodFrequency.MONTHLY,
      startDate: new Date('2026-08-01'),
      endDate: new Date('2026-08-31'),
    });
    const records = dataSource.getRepository(PayrollRecord);
    const createRecord = (ownerWorkerId: string, status: PayrollStatus) =>
      records.save({
        userId: employerId,
        workerId: ownerWorkerId,
        payPeriodId: period.id,
        status,
        periodStart: new Date('2026-08-01'),
        periodEnd: new Date('2026-08-31'),
        grossSalary: 30000,
        netSalary: 25000,
        taxAmount: 5000,
        paymentMethod: 'cash',
        paymentStatus: status === PayrollStatus.PAID ? 'paid' : 'pending',
      });
    finalizedRecord = await createRecord(workerId, PayrollStatus.FINALIZED);
    paidRecord = await createRecord(workerId, PayrollStatus.PAID);
    draftRecord = await createRecord(workerId, PayrollStatus.DRAFT);
    otherRecord = await createRecord(
      otherEmployee.workerId,
      PayrollStatus.PAID,
    );
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  it('lists only this employee finalized and paid records, excluding drafts', async () => {
    const response = await request(app.getHttpServer())
      .get('/payroll/me')
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(
      response.body
        .map((record: PayrollRecord) => record.id)
        .sort((left: string, right: string) => left.localeCompare(right)),
    ).toEqual(
      [finalizedRecord.id, paidRecord.id].sort((left, right) =>
        left.localeCompare(right),
      ),
    );
    expect(
      response.body.every(
        (record: PayrollRecord) => record.workerId === workerId,
      ),
    ).toBe(true);
  });

  it.each([PayrollStatus.FINALIZED, PayrollStatus.PAID])(
    'downloads an actual PDF for own %s record',
    async (status) => {
      const record =
        status === PayrollStatus.PAID ? paidRecord : finalizedRecord;
      const response = await request(app.getHttpServer())
        .get(`/payroll/me/${record.id}/pdf`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .expect(200);
      expect(response.headers['content-type']).toMatch(/application\/pdf/);
      expect(Buffer.isBuffer(response.body)).toBe(true);
      expect(response.body.subarray(0, 5).toString()).toBe('%PDF-');
    },
  );

  it('rejects another worker real paid PDF even under the same employer', async () => {
    await request(app.getHttpServer())
      .get(`/payroll/me/${otherRecord.id}/pdf`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(404);
    await request(app.getHttpServer())
      .get(`/payroll/me/${paidRecord.id}/pdf`)
      .set('Authorization', `Bearer ${otherEmployeeToken}`)
      .expect(404);
  });

  it('rejects own draft PDF', async () => {
    await request(app.getHttpServer())
      .get(`/payroll/me/${draftRecord.id}/pdf`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(404);
  });

  it('requires authentication for both real payslip routes', async () => {
    await request(app.getHttpServer()).get('/payroll/me').expect(401);
    await request(app.getHttpServer())
      .get(`/payroll/me/${paidRecord.id}/pdf`)
      .expect(401);
  });

  it('returns the signed-in employee profile and actual leave balance', async () => {
    const profile = await request(app.getHttpServer())
      .get('/employee-portal/my-profile')
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(200);
    expect(profile.body.workerId).toBe(workerId);
    const balance = await request(app.getHttpServer())
      .get('/employee-portal/my-leave-balance')
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(200);
    expect(balance.body.workerId).toBe(workerId);
    expect(balance.body.remainingAnnualLeaves).toEqual(expect.any(Number));
  });

  it('creates and lists own future leave, rejects another employee cancellation, then cancels own request', async () => {
    const startDate = new Date(Date.now() + 30 * 86400000)
      .toISOString()
      .slice(0, 10);
    const endDate = new Date(Date.now() + 32 * 86400000)
      .toISOString()
      .slice(0, 10);
    const created = await request(app.getHttpServer())
      .post('/employee-portal/request-leave')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ leaveType: 'ANNUAL', startDate, endDate, reason: 'E2E fixture' })
      .expect(201);
    expect(created.body.workerId).toBe(workerId);
    const history = await request(app.getHttpServer())
      .get('/employee-portal/my-leave-requests')
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(200);
    expect(history.body.map((leave: { id: string }) => leave.id)).toContain(
      created.body.id,
    );
    await request(app.getHttpServer())
      .post(`/employee-portal/cancel-leave/${created.body.id}`)
      .set('Authorization', `Bearer ${otherEmployeeToken}`)
      .expect(404);
    const cancelled = await request(app.getHttpServer())
      .post(`/employee-portal/cancel-leave/${created.body.id}`)
      .set('Authorization', `Bearer ${employeeToken}`)
      .expect(201);
    expect(cancelled.body.status).toBe('CANCELLED');
  });

  it('requires authentication for employee leave routes', async () => {
    await request(app.getHttpServer())
      .get('/employee-portal/my-leave-balance')
      .expect(401);
    await request(app.getHttpServer())
      .post('/employee-portal/request-leave')
      .send({})
      .expect(401);
  });
});
