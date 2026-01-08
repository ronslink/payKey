// test/performance.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../src/modules/users/entities/user.entity';
import { Worker } from '../../src/modules/workers/entities/worker.entity';

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
    workerRepo = moduleFixture.get<Repository<Worker>>(
      getRepositoryToken(Worker),
    );

    const testEmail = `performance-test-${Date.now()}@paykey.com`;
    const testPassword = 'PerformanceTest123!';

    // Register test user
    await request(app.getHttpServer()).post('/auth/register').send({
      email: testEmail,
      password: testPassword,
      firstName: 'Performance',
      lastName: 'Test',
      businessName: 'Performance Testing Inc',
      phone: '+254700000500',
    });

    // Login to get auth token
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: testEmail,
        password: testPassword,
      });

    authToken = loginRes.body.access_token || loginRes.body.accessToken;

    // Get user ID from the database
    const testUser = await userRepo.findOne({ where: { email: testEmail } });
    if (!testUser) {
      throw new Error('Test user not found after registration');
    }
    testUserId = testUser.id;

    // 🔧 FIX: Seed 50 workers for realistic performance testing
    console.log('Seeding 50 workers for performance test...');
    const workers = [];
    for (let i = 0; i < 50; i++) {
      workers.push({
        name: `Performance Test Worker ${i + 1}`,
        phoneNumber: `+2547${String(i).padStart(8, '0')}`,
        salaryGross: 50000 + i * 1000, // Vary salaries slightly
        startDate: new Date('2024-01-01'),
        userId: testUserId,
        isActive: true,
      });
    }

    await workerRepo.save(workers);
    console.log(`✅ Successfully seeded ${workers.length} workers`);
  });

  afterAll(async () => {
    await app.close();
  });

  it('should calculate payroll for 50 workers within performance threshold', async () => {
    // Verify workers exist before test
    const workerCount = await workerRepo.count({
      where: { userId: testUserId },
    });
    expect(workerCount).toBe(50);
    console.log(`✅ Verified ${workerCount} workers exist before test`);

    const startTime = Date.now();

    const response = await request(app.getHttpServer())
      .post('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ userId: testUserId });

    const endTime = Date.now();
    const duration = endTime - startTime;

    // Accept both 200 and 201 as success (endpoint may return either)
    expect([200, 201]).toContain(response.status);
    expect(duration).toBeLessThan(
      PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_50_WORKERS_MS,
    );

    // Log results
    console.log(
      `✅ Payroll calculation for 50 workers completed in ${duration}ms`,
    );
    console.log(
      `   Threshold: ${PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_50_WORKERS_MS}ms`,
    );
    console.log(
      `   Performance: ${duration < PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_50_WORKERS_MS ? '✅ PASS' : '❌ FAIL'}`,
    );

    // Verify response contains worker data
    if (response.body && response.body.records) {
      console.log(`   Workers processed: ${response.body.records.length}`);
      expect(response.body.records.length).toBeGreaterThan(0);
    }
  }, 60000);

  it('should calculate payroll for 100 workers within performance threshold', async () => {
    // Seed additional 50 workers (total = 100)
    const additionalWorkers = [];
    for (let i = 50; i < 100; i++) {
      additionalWorkers.push({
        name: `Performance Test Worker ${i + 1}`,
        phoneNumber: `+2547${String(i).padStart(8, '0')}`,
        salaryGross: 50000 + i * 1000,
        startDate: new Date('2024-01-01'),
        userId: testUserId,
        isActive: true,
      });
    }
    await workerRepo.save(additionalWorkers);

    // Verify total count
    const workerCount = await workerRepo.count({
      where: { userId: testUserId },
    });
    expect(workerCount).toBe(100);
    console.log(`✅ Verified ${workerCount} workers exist before test`);

    const startTime = Date.now();

    const response = await request(app.getHttpServer())
      .post('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ userId: testUserId });

    const endTime = Date.now();
    const duration = endTime - startTime;

    expect([200, 201]).toContain(response.status);
    expect(duration).toBeLessThan(
      PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_100_WORKERS_MS,
    );

    // Log results
    console.log(
      `✅ Payroll calculation for 100 workers completed in ${duration}ms`,
    );
    console.log(
      `   Threshold: ${PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_100_WORKERS_MS}ms`,
    );
    console.log(
      `   Performance: ${duration < PERFORMANCE_THRESHOLDS.PAYROLL_CALCULATION_100_WORKERS_MS ? '✅ PASS' : '❌ FAIL'}`,
    );
    console.log(`   Rate: ${(duration / 100).toFixed(2)}ms per worker`);

    if (response.body && response.body.records) {
      console.log(`   Workers processed: ${response.body.records.length}`);
      expect(response.body.records.length).toBeGreaterThan(0);
    }
  }, 120000);

  it('should calculate payroll for 500 workers within performance threshold', async () => {
    // Seed additional 400 workers (total = 500)
    console.log('Seeding 400 additional workers for 500-worker test...');
    const largeWorkerBatch = [];
    for (let i = 100; i < 500; i++) {
      largeWorkerBatch.push({
        name: `Performance Test Worker ${i + 1}`,
        phoneNumber: `+2547${String(i).padStart(8, '0')}`,
        salaryGross: 50000 + i * 500, // Vary salaries
        startDate: new Date('2024-01-01'),
        userId: testUserId,
        isActive: true,
      });
    }

    // Save in batches of 100 for better performance
    for (let i = 0; i < largeWorkerBatch.length; i += 100) {
      const batch = largeWorkerBatch.slice(i, i + 100);
      await workerRepo.save(batch);
      console.log(
        `   Saved batch ${Math.floor(i / 100) + 1}/4 (${batch.length} workers)`,
      );
    }

    // Verify total count
    const workerCount = await workerRepo.count({
      where: { userId: testUserId },
    });
    expect(workerCount).toBe(500);
    console.log(`✅ Verified ${workerCount} workers exist before test`);

    const startTime = Date.now();

    const response = await request(app.getHttpServer())
      .post('/payroll/calculate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ userId: testUserId });

    const endTime = Date.now();
    const duration = endTime - startTime;

    expect([200, 201]).toContain(response.status);

    // 500 workers test - may take longer, but should still be reasonable
    const threshold = 120000; // 2 minutes max
    expect(duration).toBeLessThan(threshold);

    // Log results
    console.log(
      `✅ Payroll calculation for 500 workers completed in ${duration}ms`,
    );
    console.log(`   Threshold: ${threshold}ms`);
    console.log(
      `   Performance: ${duration < threshold ? '✅ PASS' : '❌ FAIL'}`,
    );
    console.log(`   Rate: ${(duration / 500).toFixed(2)}ms per worker`);
    console.log(`   Total time: ${(duration / 1000).toFixed(2)}s`);

    if (response.body && response.body.records) {
      console.log(`   Workers processed: ${response.body.records.length}`);
      expect(response.body.records.length).toBeGreaterThan(0);
    }
  }, 180000); // 3 minute timeout for large test
});

