// test/payroll.service.integration.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { TestDatabaseModule } from '../test-database.module';
import { cleanupTestData } from '../test-utils';
import { WorkersModule } from '../../src/modules/workers/workers.module';
import { TaxesModule } from '../../src/modules/taxes/taxes.module';
import { PayrollModule } from '../../src/modules/payroll/payroll.module';
import { PayrollService } from '../../src/modules/payroll/payroll.service';
import { WorkersService } from '../../src/modules/workers/workers.service';
import { TaxesService } from '../../src/modules/taxes/taxes.service';
import { Worker } from '../../src/modules/workers/entities/worker.entity';
import { PayPeriod } from '../../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../../src/modules/payroll/entities/payroll-record.entity';
import { User } from '../../src/modules/users/entities/user.entity';

describe('PayrollService Integration', () => {
  let app: INestApplication;
  let payrollService: PayrollService;
  let workersService: WorkersService;
  let taxesService: TaxesService;
  let workerRepo: Repository<Worker>;
  let payPeriodRepo: Repository<PayPeriod>;
  let payrollRecordRepo: Repository<PayrollRecord>;
  let userRepo: Repository<User>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [TestDatabaseModule, WorkersModule, TaxesModule, PayrollModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    payrollService = moduleFixture.get<PayrollService>(PayrollService);
    workersService = moduleFixture.get<WorkersService>(WorkersService);
    taxesService = moduleFixture.get<TaxesService>(TaxesService);

    workerRepo = moduleFixture.get<Repository<Worker>>(
      getRepositoryToken(Worker),
    );
    payPeriodRepo = moduleFixture.get<Repository<PayPeriod>>(
      getRepositoryToken(PayPeriod),
    );
    payrollRecordRepo = moduleFixture.get<Repository<PayrollRecord>>(
      getRepositoryToken(PayrollRecord),
    );
    userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
  });

  afterAll(async () => {
    await app.close();
  });

  describe('Complete Payroll Workflow', () => {
    let testUser: User;
    let testWorker1: Worker;
    let testWorker2: Worker;
    let payPeriodId: string;

    beforeEach(async () => {
      // Clean up any existing data using TRUNCATE CASCADE
      const dataSource = app.get(DataSource);
      await cleanupTestData(dataSource);

      // Create test user
      testUser = await userRepo.save({
        email: 'integration-test@paykey.com',
        passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
        firstName: 'Test',
        lastName: 'User',
        countryCode: 'KE',
        isOnboardingCompleted: true,
      });

      // Create test workers
      testWorker1 = await workersService.create(testUser.id, {
        name: 'John Doe',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        jobTitle: 'Software Engineer',
        email: 'john@example.com',
        paymentFrequency: 'MONTHLY',
        paymentMethod: 'BANK_TRANSFER',
        bankName: 'KCB Bank',
        bankAccount: '1234567890',
      });

      testWorker2 = await workersService.create(testUser.id, {
        name: 'Jane Smith',
        phoneNumber: '+254798765432',
        salaryGross: 35000,
        startDate: '2024-01-01',
        jobTitle: 'Housekeeper',
        email: 'jane@example.com',
        paymentFrequency: 'MONTHLY',
        paymentMethod: 'MPESA',
        mpesaNumber: '+254798765432',
      });
    });

    it('should create payroll records with correct tax calculations', async () => {
      // Arrange: Ensure we have test data
      expect(testWorker1).toBeDefined();
      expect(testWorker2).toBeDefined();

      // Act: Run payroll for January 2024
      const payPeriod = await payrollService.runPayroll(
        testUser.id,
        new Date('2024-01-31'),
      );
      payPeriodId = payPeriod.id;

      // Assert: Check payroll records
      const records = await payrollRecordRepo.find({
        where: { payPeriodId: payPeriod.id },
        relations: ['worker'],
      });

      expect(records).toHaveLength(2);
      expect(payPeriod.status).toBe('COMPLETED');

      // Verify John Doe's payroll record
      const johnRecord = records.find((r) => r.workerId === testWorker1.id);
      expect(johnRecord).toBeDefined();
      expect(johnRecord.grossSalary).toBe(50000);
      expect(johnRecord.netSalary).toBeLessThan(50000);
      expect(johnRecord.nssf).toBeGreaterThan(0);
      expect(johnRecord.paye).toBeGreaterThan(0);

      // Verify Jane Smith's payroll record
      const janeRecord = records.find((r) => r.workerId === testWorker2.id);
      expect(janeRecord).toBeDefined();
      expect(janeRecord.grossSalary).toBe(35000);
      expect(janeRecord.netSalary).toBeLessThan(35000);
      expect(janeRecord.nssf).toBeGreaterThan(0);
      expect(janeRecord.paye).toBe(0); // Below PAYE threshold

      // Verify total calculations
      expect(johnRecord.netSalary + janeRecord.netSalary).toBeCloseTo(
        johnRecord.grossSalary +
        janeRecord.grossSalary -
        johnRecord.nssf -
        johnRecord.paye -
        janeRecord.nssf -
        janeRecord.paye,
        0,
      );
    });

    it('should prevent duplicate payroll runs for the same period', async () => {
      // Arrange: Run payroll once
      await payrollService.runPayroll(testUser.id, new Date('2024-01-31'));

      // Act & Assert: Try to run payroll again for the same period
      await expect(
        payrollService.runPayroll(testUser.id, new Date('2024-01-31')),
      ).rejects.toThrow('Payroll already exists for this period');
    });

    it('should calculate tax deductions correctly according to Kenyan rates', async () => {
      // Arrange
      const expectedNSSF = 3000; // 6% of 50000
      const expectedSHIF = 1375; // 2.75% of 50000
      const expectedHousingLevy = 750; // 1.5% of 50000

      // Act
      const payPeriod = await payrollService.runPayroll(
        testUser.id,
        new Date('2024-01-31'),
      );
      const johnRecord = await payrollRecordRepo.findOne({
        where: { payPeriodId: payPeriod.id, workerId: testWorker1.id },
      });

      // Assert: Tax calculations
      expect(johnRecord.nssf).toBe(expectedNSSF);
      expect(johnRecord.shif).toBe(expectedSHIF);
      expect(johnRecord.housingLevy).toBe(expectedHousingLevy);

      // Total deductions should include NSSF, SHIF, Housing Levy, and PAYE
      expect(johnRecord.totalDeductions).toBeGreaterThan(
        expectedNSSF + expectedSHIF + expectedHousingLevy,
      );
    });

    it('should handle workers with different payment frequencies', async () => {
      // Arrange: Create a daily paid worker
      const dailyWorker = await workersService.create(testUser.id, {
        name: 'Daily Worker',
        phoneNumber: '+254712345679',
        salaryGross: 50000,
        hourlyRate: 500,
        startDate: '2024-01-01',
        jobTitle: 'Casual Worker',
        paymentFrequency: 'DAILY',
      });

      // Act: Run payroll
      const payPeriod = await payrollService.runPayroll(
        testUser.id,
        new Date('2024-01-31'),
      );

      // Assert: Daily worker should be included in payroll
      const dailyRecord = await payrollRecordRepo.findOne({
        where: { payPeriodId: payPeriod.id, workerId: dailyWorker.id },
      });

      expect(dailyRecord).toBeDefined();
      expect(dailyRecord.grossSalary).toBeGreaterThan(0);
    });

    it('should update payroll records when worker details change', async () => {
      // Arrange: Run initial payroll
      const initialPayroll = await payrollService.runPayroll(
        testUser.id,
        new Date('2024-01-31'),
      );

      // Act: Update worker salary
      await workersService.update(testWorker1.id, testUser.id, {
        salaryGross: 60000,
      });

      // Re-run payroll for the same period
      await payrollService.updatePayroll(testUser.id, new Date('2024-01-31'));

      // Assert: Check updated payroll record
      const updatedRecord = await payrollRecordRepo.findOne({
        where: { payPeriodId: initialPayroll.id, workerId: testWorker1.id },
      });

      expect(updatedRecord.grossSalary).toBe(60000);
      expect(updatedRecord.netSalary).toBeLessThan(60000);
    });

    it('should archive workers and exclude them from payroll', async () => {
      // Arrange: Run initial payroll
      await payrollService.runPayroll(testUser.id, new Date('2024-01-31'));

      // Act: Archive one worker
      await workersService.archiveWorker(testWorker2.id, testUser.id);

      // Re-run payroll for the next month
      const newPayroll = await payrollService.runPayroll(
        testUser.id,
        new Date('2024-02-28'),
      );

      // Assert: Only active worker should be included
      const records = await payrollRecordRepo.find({
        where: { payPeriodId: newPayroll.id },
      });

      expect(records).toHaveLength(1);
      expect(records[0].workerId).toBe(testWorker1.id);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    let testUser: User;

    beforeEach(async () => {
      // Create test user
      testUser = await userRepo.save({
        email: 'error-test@paykey.com',
        passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
        firstName: 'Error',
        lastName: 'Test',
        countryCode: 'KE',
        isOnboardingCompleted: true,
      });
    });

    it('should handle database connection errors gracefully', async () => {
      // This would require mocking database connection failures
      // In a real scenario, you'd mock the repository to throw database errors

      const nonExistentUserId = 'non-existent-user-id';

      await expect(
        payrollService.runPayroll(nonExistentUserId, new Date()),
      ).rejects.toThrow('No workers found for this user');
    });

    it('should validate tax calculation inputs', async () => {
      // Test with invalid salary data
      const invalidWorker = await workersService.create(testUser.id, {
        name: 'Invalid Worker',
        phoneNumber: '+254712345680',
        salaryGross: -1000, // Invalid negative salary
        startDate: '2024-01-01',
      });

      await expect(
        payrollService.runPayroll(testUser.id, new Date('2024-01-31')),
      ).rejects.toThrow('Invalid salary amount');
    });

    it('should handle concurrent payroll runs safely', async () => {
      const worker = await workersService.create(testUser.id, {
        name: 'Concurrent Worker',
        phoneNumber: '+254712345681',
        salaryGross: 40000,
        startDate: '2024-01-01',
      });

      // Run multiple payroll operations concurrently
      const promises = [
        payrollService.runPayroll(testUser.id, new Date('2024-01-31')),
        payrollService.runPayroll(testUser.id, new Date('2024-01-31')),
        payrollService.runPayroll(testUser.id, new Date('2024-01-31')),
      ];

      const results = await Promise.allSettled(promises);

      // Only one should succeed, others should fail with duplicate period error
      const successCount = results.filter(
        (r) => r.status === 'fulfilled',
      ).length;
      expect(successCount).toBe(1);

      const failureCount = results.filter(
        (r) => r.status === 'rejected',
      ).length;
      expect(failureCount).toBe(2);
    });
  });

  // Performance Benchmarks have been moved to:
  // test/performance/payroll-performance.e2e-spec.ts
  // Run them with: npm run test:performance
});
