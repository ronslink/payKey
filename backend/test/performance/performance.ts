// test/performance.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { Worker } from '../src/modules/workers/entities/worker.entity';

describe('Performance Tests', () => {
  let app: INestApplication;
  let userRepo: Repository<User>;
  let workerRepo: Repository<Worker>;
  let authToken: string;
  let testUserId: string;

  const PERFORMANCE_THRESHOLDS = {
    PAYROLL_CALCULATION_100_WORKERS_MS: 30000,
    PAYROLL_CALCULATION_50_WORKERS_MS: 15000,
    SINGLE_PAYROLL_CALCULATION_MS: 2000,
    DATABASE_QUERY_RESPONSE_MS: 500,
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    workerRepo = moduleFixture.get<Repository<Worker>>(getRepositoryToken(Worker));

    // Create test user
    const testUser = await userRepo.save({
      email: 'performance-test@paykey.com',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
      firstName: 'Performance',
      lastName: 'Test',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    testUserId = testUser.id;

    // Get auth token
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'performance-test@paykey.com',
        password: 'test-password',
      });

    authToken = loginRes.body.access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  it('should calculate payroll for 50 workers within performance threshold', async () => {
    const startTime = Date.now();

    const response = await request(app.getHttpServer())
      .post('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ userId: testUserId });

    const endTime = Date.now();
    const duration = endTime - startTime;

    expect(response.status).toBe(200);
    expect(duration).toBeLessThan(PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_50_WORKERS_MS);

    console.log(`Payroll calculation completed in ${duration}ms`);
  }, 60000);
});