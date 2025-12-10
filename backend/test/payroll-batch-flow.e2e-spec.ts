import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { createTestUserData } from './test-utils';

describe('Payroll Batch Flow E2E', () => {
    let app: INestApplication;
    let authToken: string;
    let userId: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        // Register a new user for this test to ensure clean state
        const userData = createTestUserData({
            firstName: 'Batch',
            lastName: 'Tester',
            businessName: 'Batch Inc'
        });

        const registerRes = await request(app.getHttpServer())
            .post('/auth/register')
            .send({
                email: userData.email,
                password: userData.password,
                firstName: userData.firstName,
                lastName: userData.lastName,
                businessName: userData.businessName,
                phone: userData.phone
            });

        // If registration fails (e.g. user exists), try login
        if (registerRes.status !== 201) {
            // login logic if needed
        }

        const loginRes = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email: userData.email, password: userData.password });

        authToken = loginRes.body.access_token;
        userId = loginRes.body.user.id;
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    it('should generate pay periods for the year', async () => {
        const year = 2024;
        const startDate = `${year}-01-01`;
        const endDate = `${year}-12-31`;

        const res = await request(app.getHttpServer())
            .post('/pay-periods/generate')
            .set('Authorization', `Bearer ${authToken}`)
            .send({
                frequency: 'MONTHLY',
                startDate,
                endDate,
            })
            .expect(201);

        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBe(12); // Should be 12 months
        expect(res.body[0].startDate).toBe(`${year}-01-01`);
        expect(res.body[0].endDate).toBe(`${year}-01-31`);
        expect(res.body[1].startDate).toBe(`${year}-02-01`);
        // Leap year check if 2024
        expect(res.body[1].endDate).toContain(year === 2024 ? '02-29' : '02-28');
    });

    it('should list the generated periods', async () => {
        const res = await request(app.getHttpServer())
            .get('/pay-periods?limit=20')
            .set('Authorization', `Bearer ${authToken}`)
            .expect(200);

        expect(res.body.data).toHaveLength(12);
    });
});
