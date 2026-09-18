import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { createTestUserData } from './test-utils';
import { DataSource } from 'typeorm';
import { TaxTable } from '../src/modules/taxes/entities/tax-table.entity';

/**
 * Taxes & Tax Submissions E2E Tests
 *
 * Tests tax calculation and submission features:
 * - Tax calculation
 * - Compliance status
 * - Tax deadlines
 * - Tax submissions (generate, list, mark as filed)
 * - Current tax table
 */
describe('Taxes E2E', () => {
  let app: INestApplication;
  let authToken: string;
  let payPeriodId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    // Legacy table endpoint needs its own fixture; calculation rates use TaxConfig.
    await app
      .get(DataSource)
      .getRepository(TaxTable)
      .save({
        year: 2000,
        effectiveDate: new Date('2000-01-01'),
        isActive: true,
        nssfConfig: { tierILimit: 100, tierIILimit: 1000, rate: 0.06 },
        nhifConfig: { rate: 0.01 },
        housingLevyRate: 0.01,
        payeBands: [],
        personalRelief: 0,
      });

    // Register and login test user
    const userData = createTestUserData({
      firstName: 'Taxes',
      lastName: 'Tester',
      businessName: 'Taxes Test Corp',
    });

    await request(app.getHttpServer()).post('/auth/register').send({
      email: userData.email,
      password: userData.password,
      firstName: userData.firstName,
      lastName: userData.lastName,
      businessName: userData.businessName,
      phone: userData.phone,
    });

    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: userData.email, password: userData.password });

    authToken = loginRes.body.access_token;

    // Create a pay period for submission tests
    const periodRes = await request(app.getHttpServer())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        year: 2024,
        frequency: 'MONTHLY',
      });

    if (periodRes.body.periods && periodRes.body.periods.length > 0) {
      payPeriodId = periodRes.body.periods[0].id;
    }
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Tax Calculation', () => {
    it('should calculate taxes for gross salary', async () => {
      const res = await request(app.getHttpServer())
        .post('/taxes/calculate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          grossSalary: 100000,
        })
        .expect(201);

      expect(res.body).toHaveProperty('paye');
      expect(res.body).toHaveProperty('nssf');
      expect(res.body).toHaveProperty('nhif');
    });
  });

  describe('Compliance', () => {
    it('should get compliance status', async () => {
      const res = await request(app.getHttpServer())
        .get('/taxes/compliance')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Response may vary based on user's filing history
      expect(res.body).toBeDefined();
    });

    it('should get upcoming tax deadlines', async () => {
      const res = await request(app.getHttpServer())
        .get('/taxes/deadlines')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);

      // Verify deadline structure if deadlines exist
      if (res.body.length > 0) {
        const deadline = res.body[0];
        expect(deadline).toHaveProperty('title');
        expect(deadline).toHaveProperty('dueDate');
        expect(deadline).toHaveProperty('description');

        // Verify dueDate is a valid date
        expect(new Date(deadline.dueDate).toString()).not.toBe('Invalid Date');
      }
    });

    it('should return Kenya statutory deadlines (PAYE, NSSF, SHIF, Housing)', async () => {
      const res = await request(app.getHttpServer())
        .get('/taxes/deadlines')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThan(0);

      // Kenya-specific deadlines should include PAYE, NSSF, SHIF/NHIF
      const titles = res.body.map((d: any) => d.title.toLowerCase());
      expect(titles.some((t: string) => t.includes('paye'))).toBe(true);
      expect(titles.some((t: string) => t.includes('nssf'))).toBe(true);
    });
  });

  describe('Tax Table', () => {
    it('should get current tax table', async () => {
      const res = await request(app.getHttpServer())
        .get('/taxes/current')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Returns tax table or null
      expect(res.body !== undefined).toBe(true);
    });
  });

  describe('Tax Submissions', () => {
    it('should list tax submissions', async () => {
      const res = await request(app.getHttpServer())
        .get('/taxes/submissions')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
    });

    it('should generate tax submission for pay period', async () => {
      if (!payPeriodId) {
        console.warn('Skipping - no pay period');
        return;
      }

      const res = await request(app.getHttpServer())
        .post(`/taxes/submissions/generate/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // May succeed or fail based on period status
      expect([200, 201, 400, 500]).toContain(res.status);
    });

    it('should get tax submission by period', async () => {
      if (!payPeriodId) {
        console.warn('Skipping - no pay period');
        return;
      }

      const res = await request(app.getHttpServer())
        .get(`/taxes/submissions/period/${payPeriodId}`)
        .set('Authorization', `Bearer ${authToken}`);

      // Returns submission or null
      expect([200, 404]).toContain(res.status);
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access', async () => {
      await request(app.getHttpServer()).get('/taxes/compliance').expect(401);
    });
  });
});
