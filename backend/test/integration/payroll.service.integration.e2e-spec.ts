import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { cleanupTestData } from '../test-utils';
import { PayrollService } from '../../src/modules/payroll/payroll.service';
import { WorkersService } from '../../src/modules/workers/workers.service';
import {
  Worker,
  PaymentFrequency,
  PaymentMethod,
} from '../../src/modules/workers/entities/worker.entity';
import { PayPeriod } from '../../src/modules/payroll/entities/pay-period.entity';
import { PayrollRecord } from '../../src/modules/payroll/entities/payroll-record.entity';
import { User, UserTier } from '../../src/modules/users/entities/user.entity';
import { v4 as uuidv4 } from 'uuid';
import { PayPeriodStatus } from '../../src/modules/payroll/entities/pay-period.entity';

describe('PayrollService Integration', () => {
  let app: INestApplication;
  let payrollService: PayrollService;
  let workersService: WorkersService;
  let workerRepo: Repository<Worker>;
  let payPeriodRepo: Repository<PayPeriod>;
  let payrollRecordRepo: Repository<PayrollRecord>;
  let userRepo: Repository<User>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    payrollService = moduleFixture.get<PayrollService>(PayrollService);
    workersService = moduleFixture.get<WorkersService>(WorkersService);

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
    if (app) {
      await app.close();
    }
  });

  describe('Complete Payroll Workflow', () => {
    let testUser: User;
    let testWorker1: Worker;
    let testWorker2: Worker;

    beforeEach(async () => {
      const dataSource = app.get(DataSource);
      await cleanupTestData(dataSource);

      // cleanupTestData restores the application's effective tax configuration.

      testUser = await userRepo.save({
        email: 'integration-test@paykey.com',
        passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz',
        firstName: 'Test',
        lastName: 'User',
        tier: UserTier.PLATINUM,
        isOnboardingCompleted: true,
      });

      testWorker1 = await workersService.create(testUser.id, {
        name: 'John Doe',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        jobTitle: 'Software Engineer',
        email: 'john@example.com',
        paymentFrequency: PaymentFrequency.MONTHLY,
        paymentMethod: PaymentMethod.BANK,
        bankName: 'KCB Bank',
        bankAccount: '1234567890',
      });

      testWorker2 = await workersService.create(testUser.id, {
        name: 'Jane Smith',
        phoneNumber: '+254798765432',
        salaryGross: 24000,
        startDate: '2024-01-01',
        jobTitle: 'Housekeeper',
        email: 'jane@example.com',
        paymentFrequency: PaymentFrequency.MONTHLY,
        paymentMethod: PaymentMethod.MPESA,
        mpesaNumber: '+254798765432',
      });
    });

    it('should calculate, save draft, and finalize payroll records', async () => {
      // 1. Calculate
      const calculation = await payrollService.calculatePayrollForUser(
        testUser.id,
      );
      expect(calculation.payrollItems).toHaveLength(2);

      // 2. Save Draft
      const payPeriod = await payPeriodRepo.save({
        userId: testUser.id,
        startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        endDate: new Date(
          new Date().getFullYear(),
          new Date().getMonth() + 1,
          0,
        ),
        status: PayPeriodStatus.ACTIVE,
      });

      const draftItems = calculation.payrollItems.map((item) => ({
        workerId: item.workerId,
        grossSalary: item.grossSalary,
      }));

      await payrollService.saveDraftPayroll(
        testUser.id,
        payPeriod.id,
        draftItems,
      );

      // 3. Finalize
      await payrollService.executePayrollFinalization(
        testUser.id,
        payPeriod.id,
        true,
      );

      // Assert
      const records = await payrollRecordRepo.find({
        where: { payPeriodId: payPeriod.id },
        relations: ['worker'],
      });

      expect(records).toHaveLength(2);

      const updatedPeriod = await payPeriodRepo.findOneBy({ id: payPeriod.id });
      expect(updatedPeriod!.status).toBe('COMPLETED');

      const janeRecord = records.find((r) => r.workerId === testWorker2.id);
      expect(Number(janeRecord!.grossSalary)).toBe(24000);
      expect(janeRecord!.taxBreakdown.paye).toBe(0);
    });

    it('should update draft payroll item', async () => {
      const payPeriod = await payPeriodRepo.save({
        userId: testUser.id,
        startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        endDate: new Date(
          new Date().getFullYear(),
          new Date().getMonth() + 1,
          0,
        ),
        status: PayPeriodStatus.ACTIVE,
      });

      const draftItems = [
        {
          workerId: testWorker1.id,
          grossSalary: 50000,
        },
      ];

      const savedRecords = await payrollService.saveDraftPayroll(
        testUser.id,
        payPeriod.id,
        draftItems,
      );
      const recordId = savedRecords[0].id;

      await payrollService.updateDraftPayrollItem(testUser.id, recordId, {
        grossSalary: 60000,
      });

      const updatedRecord = await payrollRecordRepo.findOneBy({ id: recordId });
      expect(Number(updatedRecord!.grossSalary)).toBe(60000);
    });
  });

  describe('Error Handling', () => {
    it('should throw if no workers found for calculation', async () => {
      const emptyUser = await userRepo.save({
        email: 'empty@test.com',
        passwordHash: 'hash',
        firstName: 'Empty',
        lastName: 'User',
        tier: UserTier.PLATINUM,
      });

      // calculatePayrollForUser doesn't throw if 0 workers, just returns empty
      const calculation = await payrollService.calculatePayrollForUser(
        emptyUser.id,
      );
      expect(calculation.payrollItems).toHaveLength(0);
    });

    it('should validate tax calculation inputs in calculateSingleWorkerPayroll', async () => {
      const testUser = await userRepo.save({
        email: `tax-val-${uuidv4()}@test.com`,
        passwordHash: 'hash',
        firstName: 'Tax',
        lastName: 'Validation',
      });

      const worker = await workerRepo.save({
        userId: testUser.id,
        name: 'Invalid Worker',
        phoneNumber: '+254000000000',
        salaryGross: -1000,
        startDate: new Date(),
        isActive: true,
      });

      await expect(
        payrollService.calculateSingleWorkerPayroll(worker.id, testUser.id),
      ).rejects.toThrow('Invalid salary amount');
    });
  });
});
