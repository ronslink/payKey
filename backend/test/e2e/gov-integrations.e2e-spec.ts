import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { AppModule } from '../../src/app.module';
import { TestDatabaseModule } from '../test-database.module';
import { cleanupTestData } from '../test-utils';
import { PayrollService } from '../../src/modules/payroll/payroll.service';
import { WorkersService } from '../../src/modules/workers/workers.service';
import { KraService } from '../../src/modules/gov-integrations/services/kra.service';
import { NssfService } from '../../src/modules/gov-integrations/services/nssf.service';
import { ShifService } from '../../src/modules/gov-integrations/services/shif.service';
import { User } from '../../src/modules/users/entities/user.entity';
import { PayPeriod } from '../../src/modules/payroll/entities/pay-period.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as fs from 'fs';

describe('Gov Integrations E2E', () => {
  let app: INestApplication;
  let kraService: KraService;
  let nssfService: NssfService;
  let shifService: ShifService;
  let payrollService: PayrollService;
  let workersService: WorkersService;
  let userRepo: Repository<User>;
  let payPeriodRepo: Repository<PayPeriod>;
  let testUser: User;
  let payPeriodId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule, TestDatabaseModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    kraService = moduleFixture.get<KraService>(KraService);
    nssfService = moduleFixture.get<NssfService>(NssfService);
    shifService = moduleFixture.get<ShifService>(ShifService);
    payrollService = moduleFixture.get<PayrollService>(PayrollService);
    workersService = moduleFixture.get<WorkersService>(WorkersService);
    userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    payPeriodRepo = moduleFixture.get<Repository<PayPeriod>>(
      getRepositoryToken(PayPeriod),
    );

    const dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);

    // Setup test user
    testUser = await userRepo.save({
      email: 'gov-test@paykey.com',
      passwordHash: 'hash',
      firstName: 'Gov',
      lastName: 'Tester',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    // Setup workers
    await workersService.create(testUser.id, {
      name: 'Tester 1',
      phoneNumber: '+254700000001',
      salaryGross: 50000,
      startDate: '2024-01-01',
      kraPin: 'A123456789Z',
    });

    // Create and finalize payroll
    const calculation = await payrollService.calculatePayrollForUser(
      testUser.id,
    );
    const payPeriod = await payPeriodRepo.save({
      userId: testUser.id,
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-01-31'),
      status: 'OPEN' as any,
    });
    payPeriodId = payPeriod.id;

    const draftItems = calculation.payrollItems.map((item) => ({
      workerId: item.workerId,
      grossSalary: item.grossSalary,
    }));

    await payrollService.saveDraftPayroll(
      testUser.id,
      payPeriod.id,
      draftItems,
    );
    await payrollService.executePayrollFinalization(
      testUser.id,
      payPeriod.id,
      true,
    );
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('should generate KRA P10 Excel file', async () => {
    const submission = await kraService.generateP10Excel(
      payPeriodId,
      testUser.id,
    );
    expect(submission).toBeDefined();
    expect(submission.filePath).toContain('kra');
    expect(fs.existsSync(submission.filePath)).toBe(true);
  });

  it('should generate NSSF Excel file', async () => {
    const submission = await nssfService.generateNSSFExcel(
      payPeriodId,
      testUser.id,
    );
    expect(submission).toBeDefined();
    expect(submission.filePath).toContain('nssf');
    expect(fs.existsSync(submission.filePath)).toBe(true);
  });

  it('should generate SHIF Excel file', async () => {
    const submission = await shifService.generateSHIFExcel(
      payPeriodId,
      testUser.id,
    );
    expect(submission).toBeDefined();
    expect(submission.filePath).toContain('shif');
    expect(fs.existsSync(submission.filePath)).toBe(true);
  });
});
