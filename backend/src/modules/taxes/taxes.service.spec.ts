import { Test, TestingModule } from '@nestjs/testing';
import { TaxesService } from './taxes.service';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';
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
      getActiveTaxConfig: jest.fn().mockImplementation((type) => {
        switch(type) {
          case TaxType.NSSF_TIER1:
            return { configuration: { tiers: [{ rate: 0.06, salaryTo: 8000 }] } };
          case TaxType.NSSF_TIER2:
            return { configuration: { tiers: [{ rate: 0.06, salaryFrom: 8001, salaryTo: 72000 }] } };
          case TaxType.SHIF:
            return { configuration: { percentage: 2.75, minAmount: 300 } };
          case TaxType.HOUSING_LEVY:
            return { configuration: { percentage: 1.5 } };
          case TaxType.PAYE:
            return {
              configuration: {
                personalRelief: 2400,
                brackets: [
                  { to: 24000, rate: 0.1 },
                  { to: 32333, rate: 0.25 },
                  { to: null, rate: 0.3 }
                ]
              }
            };
          default:
            return null;
        }
      }),
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
      findOneById: jest
        .fn()
        .mockResolvedValue({ id: 'user-1', email: 'test@example.com' }),
    };

    const mockActivitiesService = {
      logActivity: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TaxesService,
        { provide: TaxConfigService, useValue: mockTaxConfigService },
        {
          provide: getRepositoryToken(TaxSubmission),
          useValue: mockTaxSubmissionRepo,
        },
        { provide: getRepositoryToken(TaxTable), useValue: mockTaxTableRepo },
        {
          provide: getRepositoryToken(PayrollRecord),
          useValue: mockPayrollRecordRepo,
        },
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

      // SHIF: 2.75% of 50k = 1375
      expect(result.nhif).toBeCloseTo(1375, 2);
      // AHL: 1.5% of 50k = 750
      expect(result.housingLevy).toBeCloseTo(750, 2);
      // NSSF: Tier 1 (8000*0.06 = 480) + Tier 2 ((50000-8000)*0.06 = 2520) = 3000
      expect(result.nssf).toBeCloseTo(3000, 2);
      
      // Taxable Income = 50000 - 3000 = 47000
      // PAYE: (24000*0.1) + (8333*0.25) + (14667*0.3) = 8883.35
      // Reliefs: 2400 (Personal) + (1375 * 0.15 = 206.25 Insurance Relief) = 2606.25
      // Final PAYE = 8883.35 - 2606.25 = 6277.10
      expect(result.paye).toBeCloseTo(6277.10, 2);
      
      expect(result.totalDeductions).toBeCloseTo(3000 + 1375 + 750 + 6277.10, 2);
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
      const sumOfTaxes =
        taxes.nssf + taxes.nhif + taxes.housingLevy + taxes.paye;

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

      expect(highSalaryTaxes.totalDeductions).toBeGreaterThan(
        lowSalaryTaxes.totalDeductions,
      );
      expect(highSalaryTaxes.paye).toBeGreaterThan(lowSalaryTaxes.paye);
    });

    it('should have PAYE reduced by personal and insurance relief', async () => {
      // For very low income, personal and insurance relief should completely offset PAYE
      const taxes = await service.calculateTaxes(20000, new Date());

      // At 20k gross, PAYE should be 0 due to reliefs
      expect(taxes.paye).toBe(0);
      
      // Let's test a case where PAYE is slightly above relief
      const taxesAbove = await service.calculateTaxes(30000, new Date());
      // Taxable = 30000 - 1800 (NSSF) = 28200
      // PAYE before = (24000*0.1) + (4200*0.25) = 3450
      // Relief = 2400 + (825*0.15 = 123.75) = 2523.75
      // Final PAYE = 3450 - 2523.75 = 926.25
      expect(taxesAbove.paye).toBeCloseTo(926.25, 2);
    });
  });
});
