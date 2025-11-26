import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { Repository } from 'typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

describe('Payroll E2E', () => {
    let app: INestApplication;
    let authToken: string;
    let userId: string;
    let userRepo: Repository<User>;
    let workerRepo: Repository<Worker>;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        userRepo = moduleFixture.get(getRepositoryToken(User));
        workerRepo = moduleFixture.get(getRepositoryToken(Worker));

        // Create test user and login
        const testUser = await userRepo.save({
            email: 'test@paykey.com',
            passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz', // Pre-hashed password
            firstName: 'Test',
            lastName: 'User',
        });
        userId = testUser.id;

        const loginRes = await request(app.getHttpServer())
            .post('/auth/login')
            .send({
                email: 'test@paykey.com',
                password: 'password123',
            });

        authToken = loginRes.body.access_token;
    });

    afterAll(async () => {
        // Cleanup: Delete test data
        await workerRepo.delete({ userId });
        await userRepo.delete({ id: userId });
        await app.close();
    });

    describe('Complete Payroll Workflow', () => {
        let workerId: string;
        let payPeriodId: string;

        it('should create a worker', async () => {
            const res = await request(app.getHttpServer())
                .post('/workers')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    name: 'Jane Doe',
                    email: 'jane@example.com',
                    phoneNumber: '+254712345678',
                    salary: 60000,
                    position: 'Housekeeper',
                    startDate: '2024-01-01',
                })
                .expect(201);

            expect(res.body).toHaveProperty('id');
            expect(res.body.name).toBe('Jane Doe');
            expect(res.body.salary).toBe(60000);
            workerId = res.body.id;
        });

        it('should run payroll for the month', async () => {
            const res = await request(app.getHttpServer())
                .post('/payroll/run')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    date: '2024-01-31',
                })
                .expect(201);

            expect(res.body).toHaveProperty('id');
            expect(res.body).toHaveProperty('records');
            expect(res.body.records).toHaveLength(1);
            expect(res.body.records[0].workerId).toBe(workerId);
            expect(res.body.records[0].grossSalary).toBe(60000);
            expect(res.body.records[0].netSalary).toBeLessThan(60000);
            payPeriodId = res.body.id;
        });

        it('should retrieve payroll records', async () => {
            const res = await request(app.getHttpServer())
                .get(`/payroll/${payPeriodId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.body.id).toBe(payPeriodId);
            expect(res.body.records).toHaveLength(1);
        });

        it('should download payslip as PDF', async () => {
            const res = await request(app.getHttpServer())
                .get(`/payroll/${payPeriodId}/payslip/${workerId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);

            expect(res.headers['content-type']).toContain('pdf');
            expect(res.body).toBeDefined();
        });
    });

    describe('Authorization', () => {
        it('should prevent unauthorized access to payroll', async () => {
            await request(app.getHttpServer())
                .get('/payroll')
                .expect(401);
        });

        it('should prevent access with invalid token', async () => {
            await request(app.getHttpServer())
                .get('/payroll')
                .set('Authorization', 'Bearer invalid-token')
                .expect(401);
        });
    });
});
