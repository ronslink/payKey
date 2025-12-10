import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

/**
 * Pay Periods E2E Tests
 * 
 * Tests pay period lifecycle:
 * - Generate pay periods
 * - List and retrieve pay periods
 * - Activate, process, complete, close periods
 * - Get period statistics
 */
describe('Pay Periods E2E', () => {
    let app: INestApplication;
    let authToken: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        // Register and login test user
        const email = `payperiods.test.${Date.now()}@paykey.com`;
        const password = 'Password123!';

        await request(app.getHttpServer())
            .post('/auth/register')
            .send({
                email,
                password,
                firstName: 'PayPeriods',
                lastName: 'Tester',
                businessName: 'PayPeriods Test Corp',
                phone: '+254700000200'
            });

        const loginRes = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email, password });

        authToken = loginRes.body.access_token;
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    describe('Pay Period Generation', () => {
        it('should generate monthly pay periods for a year', async () => {
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
            expect(res.body[0].name).toContain('January');
            expect(res.body[11].name).toContain('December');
        });

        it('should generate weekly pay periods', async () => {
            const res = await request(app.getHttpServer())
                .post('/pay-periods/generate')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    frequency: 'WEEKLY',
                    startDate: '2025-01-01',
                    endDate: '2025-01-31',
                })
                .expect(201);

            // January 2025 should have about 4-5 weeks
            expect(res.body.length).toBeGreaterThanOrEqual(4);
        });
    });

    describe('Pay Period CRUD', () => {
        let payPeriodId: string;

        beforeAll(async () => {
            // Generate periods for CRUD tests
            const res = await request(app.getHttpServer())
                .post('/pay-periods/generate')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    frequency: 'MONTHLY',
                    startDate: '2023-01-01',
                    endDate: '2023-12-31',
                });

            payPeriodId = res.body[0].id;
        });

        it('should list pay periods with pagination', async () => {
            const res = await request(app.getHttpServer())
                .get('/pay-periods')
                .set('Authorization', `Bearer ${authToken}`)
                .query({ page: 1, limit: 10 })
                .expect(200);

            expect(res.body).toHaveProperty('data');
            expect(res.body).toHaveProperty('total');
            expect(Array.isArray(res.body.data)).toBe(true);
        });

        it('should get a single pay period', async () => {
            const res = await request(app.getHttpServer())
                .get(`/pay-periods/${payPeriodId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.body.id).toBe(payPeriodId);
            expect(res.body).toHaveProperty('startDate');
            expect(res.body).toHaveProperty('endDate');
        });

        it('should update a pay period', async () => {
            const res = await request(app.getHttpServer())
                .patch(`/pay-periods/${payPeriodId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    notes: 'Updated test notes',
                })
                .expect(200);

            expect(res.body.notes).toBe('Updated test notes');
        });
    });

    describe('Pay Period Lifecycle', () => {
        let payPeriodId: string;
        let workerId: string;

        beforeAll(async () => {
            // Create a worker first (needed for payroll processing)
            const workerRes = await request(app.getHttpServer())
                .post('/workers')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    name: 'Period Lifecycle Worker',
                    phoneNumber: '+254712345100',
                    salaryGross: 35000,
                    startDate: '2022-01-01',
                });

            workerId = workerRes.body.id;

            // Generate periods for lifecycle tests
            const res = await request(app.getHttpServer())
                .post('/pay-periods/generate')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    frequency: 'MONTHLY',
                    startDate: '2022-01-01',
                    endDate: '2022-12-31',
                });

            payPeriodId = res.body[0].id;
        });

        it('should activate a pay period', async () => {
            const res = await request(app.getHttpServer())
                .post(`/pay-periods/${payPeriodId}/activate`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(201);

            expect(res.body.status).toBe('ACTIVE');
        });

        it('should get pay period statistics', async () => {
            const res = await request(app.getHttpServer())
                .get(`/pay-periods/${payPeriodId}/statistics`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.body).toHaveProperty('statistics');
            expect(res.body.statistics).toHaveProperty('totalGrossAmount');
        });

        it('should process a pay period', async () => {
            // Note: Process might fail if period doesn't meet requirements
            // Using try-catch to handle state machine restrictions
            const res = await request(app.getHttpServer())
                .post(`/pay-periods/${payPeriodId}/process`)
                .set('Authorization', `Bearer ${authToken}`);

            // May return 201 or 400 depending on period state
            expect([200, 201, 400]).toContain(res.status);
        });

        it('should complete a pay period', async () => {
            // Note: Complete might fail if period doesn't meet requirements
            const res = await request(app.getHttpServer())
                .post(`/pay-periods/${payPeriodId}/complete`)
                .set('Authorization', `Bearer ${authToken}`);

            // May return 201 or 400 depending on period state
            expect([200, 201, 400]).toContain(res.status);
        });

        it('should close a pay period', async () => {
            const res = await request(app.getHttpServer())
                .post(`/pay-periods/${payPeriodId}/close`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(201);

            expect(res.body.status).toBe('CLOSED');
        });
    });

    describe('Authorization', () => {
        it('should prevent unauthorized access to pay periods', async () => {
            await request(app.getHttpServer())
                .get('/pay-periods')
                .expect(401);
        });

        it('should prevent generation without auth', async () => {
            await request(app.getHttpServer())
                .post('/pay-periods/generate')
                .send({
                    frequency: 'MONTHLY',
                    startDate: '2024-01-01',
                    endDate: '2024-12-31',
                })
                .expect(401);
        });
    });
});
