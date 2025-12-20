import { Test, TestingModule } from '@nestjs/testing';
import { TaxesService } from './taxes.service';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { TaxSubmission } from './entities/tax-submission.entity';
import { TaxTable } from './entities/tax-table.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { UsersService } from '../users/users.service';
import { ActivitiesService } from '../activities/activities.service';
import { getRepositoryToken } from '@nestjs/typeorm';

describe('TaxesService', () => {
  let service: TaxesService;

  beforeEach(async () => {
    const mockTaxConfigService = {
      getActiveTaxConfig: jest.fn().mockResolvedValue(null),
      getAllActiveTaxConfigs: jest.fn().mockResolvedValue([]),
    };

    const mockTaxSubmissionRepo = {
      find: jest.fn().mockResolvedValue([]),
      findOne: jest.fn().mockResolvedValue(null),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
      create: jest.fn().mockImplementation((entity) => entity),
    };

    const mockTaxTableRepo = {
      findOne: jest.fn().mockResolvedValue(null),
      find: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockImplementation((entity) => entity),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    const mockPayrollRecordRepo = {
      find: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      findOne: jest.fn().mockResolvedValue(null),
    };

    const mockUsersService = {
      findOneById: jest.fn().mockResolvedValue({ id: 'user-1', email: 'test@example.com' }),
    };

    const mockActivitiesService = {
      logActivity: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TaxesService,
        { provide: TaxConfigService, useValue: mockTaxConfigService },
        { provide: getRepositoryToken(TaxSubmission), useValue: mockTaxSubmissionRepo },
        { provide: getRepositoryToken(TaxTable), useValue: mockTaxTableRepo },
        { provide: getRepositoryToken(PayrollRecord), useValue: mockPayrollRecordRepo },
        { provide: UsersService, useValue: mockUsersService },
        { provide: ActivitiesService, useValue: mockActivitiesService },
      ],
    }).compile();

    service = module.get<TaxesService>(TaxesService);
  });


  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculateTaxes', () => {
    it('should calculate all taxes correctly for salary of 50000', async () => {
      const result = await service.calculateTaxes(50000, new Date());

      expect(result.nssf).toBeGreaterThanOrEqual(0);
      expect(result.nhif).toBeGreaterThanOrEqual(0);
      expect(result.housingLevy).toBeGreaterThanOrEqual(0);
      expect(result.paye).toBeGreaterThanOrEqual(0);
      expect(result.totalDeductions).toBeGreaterThanOrEqual(0);
    });

    it('should calculate net pay correctly', async () => {
      const grossSalary = 50000;
      const taxes = await service.calculateTaxes(grossSalary, new Date());
      const netPay = await service.calculateNetPay(grossSalary);

      expect(netPay).toBe(grossSalary - taxes.totalDeductions);
      expect(netPay).toBeLessThan(grossSalary);
    });

    it('should handle zero salary with minimum SHIF', async () => {
      const taxes = await service.calculateTaxes(0, new Date());
      const netPay = await service.calculateNetPay(0);

      // SHIF has a minimum of 300 KES even at 0 salary
      expect(taxes.nhif).toBe(300);
      expect(taxes.nssf).toBe(0);
      expect(taxes.housingLevy).toBe(0);
      expect(taxes.paye).toBe(0);
      expect(netPay).toBe(-300); // Net is negative due to min SHIF
    });

    it('should have totalDeductions equal to sum of individual taxes', async () => {
      const taxes = await service.calculateTaxes(75000, new Date());
      const sumOfTaxes = taxes.nssf + taxes.nhif + taxes.housingLevy + taxes.paye;

      expect(taxes.totalDeductions).toBeCloseTo(sumOfTaxes, 2);
    });

    it('should calculate housing levy at 1.5%', async () => {
      const grossSalary = 100000;
      const taxes = await service.calculateTaxes(grossSalary, new Date());

      // Housing levy is 1.5% of gross
      expect(taxes.housingLevy).toBeCloseTo(1500, 2);
    });

    it('should calculate SHIF at approximately 2.75%', async () => {
      const grossSalary = 100000;
      const taxes = await service.calculateTaxes(grossSalary, new Date());

      // SHIF (stored as nhif) is 2.75% of gross
      expect(taxes.nhif).toBeCloseTo(2750, 2);
    });

    it('should increase taxes as salary increases', async () => {
      const lowSalaryTaxes = await service.calculateTaxes(30000, new Date());
      const highSalaryTaxes = await service.calculateTaxes(100000, new Date());

      expect(highSalaryTaxes.totalDeductions).toBeGreaterThan(lowSalaryTaxes.totalDeductions);
      expect(highSalaryTaxes.paye).toBeGreaterThan(lowSalaryTaxes.paye);
    });

    it('should have PAYE reduced by personal relief', async () => {
      // For very low income, personal relief should offset PAYE
      const taxes = await service.calculateTaxes(20000, new Date());

      // At 20k gross, PAYE should be low due to personal relief of 2400
      expect(taxes.paye).toBeLessThan(taxes.nssf + taxes.nhif);
    });
  });
});
