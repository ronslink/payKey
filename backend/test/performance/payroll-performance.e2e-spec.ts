// test/performance/payroll-performance.e2e-spec.ts
// Extracted from payroll.service.integration.spec.ts
// Run with: npm run test:performance

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { WorkersService } from '../../src/modules/workers/workers.service';
import { PayrollService } from '../../src/modules/payroll/payroll.service';
import { PayrollRecord } from '../../src/modules/payroll/entities/payroll-record.entity';
import { User } from '../../src/modules/users/entities/user.entity';

describe('Payroll Performance Benchmarks', () => {
  let app: INestApplication;
  let payrollService: PayrollService;
  let workersService: WorkersService;
  let payrollRecordRepo: Repository<PayrollRecord>;
  let userRepo: Repository<User>;
  let testUser: User;

  const PERFORMANCE_WORKER_COUNT = 50;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    payrollService = moduleFixture.get<PayrollService>(PayrollService);
    workersService = moduleFixture.get<WorkersService>(WorkersService);
    payrollRecordRepo = moduleFixture.get<Repository<PayrollRecord>>(
      getRepositoryToken(PayrollRecord),
    );
    userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));

    // Create test user
    testUser = await userRepo.save({
      email: `perf-benchmark-${Date.now()}@paykey.com`,
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
      firstName: 'Performance',
      lastName: 'Test',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    // Create multiple workers for performance testing
    console.log(
      `Creating ${PERFORMANCE_WORKER_COUNT} workers for benchmark...`,
    );
    for (let i = 0; i < PERFORMANCE_WORKER_COUNT; i++) {
      await workersService.create(testUser.id, {
        name: `Benchmark Worker ${i}`,
        phoneNumber: `+2547123456${i.toString().padStart(2, '0')}`,
        salaryGross: 30000 + i * 1000,
        startDate: '2024-01-01',
        jobTitle: `Position ${i}`,
      });
    }
    console.log(`✅ Created ${PERFORMANCE_WORKER_COUNT} workers`);
  }, 120000); // 2 minute timeout for setup

  afterAll(async () => {
    await app.close();
  });

  it('should process payroll for 50 workers in under 30 seconds', async () => {
    const startTime = Date.now();

    const payPeriod = await payrollService.runPayroll(
      testUser.id,
      new Date('2024-01-31'),
    );

    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`⏱️  Payroll calculation completed in ${duration}ms`);
    console.log(`   Threshold: 30000ms`);
    console.log(`   Result: ${duration < 30000 ? '✅ PASS' : '❌ FAIL'}`);

    // 30 seconds = 30000ms
    expect(duration).toBeLessThan(30000);

    // Verify all workers were processed
    const recordCount = await payrollRecordRepo.count({
      where: { payPeriodId: payPeriod.id },
    });

    expect(recordCount).toBe(PERFORMANCE_WORKER_COUNT);
    console.log(`   Workers processed: ${recordCount}`);
  }, 60000); // 1 minute timeout for the test
});
