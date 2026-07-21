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
        switch (type) {
          case TaxType.NSSF_TIER1:
            return {
              configuration: {
                tiers: [{ rate: 0.06, salaryFrom: 0, salaryTo: 9000 }],
              },
            };
          case TaxType.NSSF_TIER2:
            return {
              configuration: {
                tiers: [{ rate: 0.06, salaryFrom: 9000, salaryTo: 108000 }],
              },
            };
          case TaxType.SHIF:
            return { configuration: { percentage: 2.75, minAmount: 300 } };
          case TaxType.HOUSING_LEVY:
            return { configuration: { percentage: 1.5 } };
          case TaxType.PAYE:
            return {
              configuration: {
                personalRelief: 2400,
                insuranceRelief: 0.15,
                maxInsuranceRelief: 5000,
                maxAllowablePension: 30000,
                maxMortgageInterest: 30000,
                maxPostRetirementMedicalContribution: 15000,
                nonCashBenefitExemptionThreshold: 5000,
                brackets: [
                  { to: 24000, rate: 0.1 },
                  { to: 32333, rate: 0.25 },
                  { to: 500000, rate: 0.3 },
                  { to: 800000, rate: 0.325 },
                  { to: null, rate: 0.35 },
                ],
              },
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

      // Taxable = 50,000 - 3,000 NSSF - 1,375 SHIF - 750 AHL = 44,875
      // Tax = 8,245.85; less KES 2,400 personal relief = KES 5,845.85
      expect(result.paye).toBeCloseTo(5845.85, 2);

      expect(result.totalDeductions).toBeCloseTo(
        3000 + 1375 + 750 + 5845.85,
        2,
      );
    });

    it('should calculate net pay correctly', async () => {
      const grossSalary = 50000;
      const taxes = await service.calculateTaxes(grossSalary, new Date());
      const netPay = await service.calculateNetPay(grossSalary);

      expect(netPay).toBe(grossSalary - taxes.totalDeductions);
      expect(netPay).toBeLessThan(grossSalary);
    });

    it('should not create deductions or negative net pay for zero salary', async () => {
      const taxes = await service.calculateTaxes(0, new Date());
      const netPay = await service.calculateNetPay(0);

      expect(taxes.nhif).toBe(0);
      expect(taxes.nssf).toBe(0);
      expect(taxes.housingLevy).toBe(0);
      expect(taxes.paye).toBe(0);
      expect(netPay).toBe(0);
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

    it('should deduct SHIF and AHL from taxable pay', async () => {
      const taxes = await service.calculateTaxes(20000, new Date());

      // At 20k gross, PAYE should be 0 due to reliefs
      expect(taxes.paye).toBe(0);

      const taxesAbove = await service.calculateTaxes(30000, new Date());
      // Taxable = 30,000 - 1,800 NSSF - 825 SHIF - 450 AHL = 26,925
      // Tax = 3,131.25; less personal relief = 731.25
      expect(taxesAbove.paye).toBeCloseTo(731.25, 2);
    });

    it.each([
      [5000, 300],
      [9000, 540],
      [20000, 1200],
      [108000, 6480],
      [150000, 6480],
    ])(
      'uses 2026 NSSF Year 4 limits for gross salary %s',
      async (grossSalary, expectedNssf) => {
        const taxes = await service.calculateTaxes(grossSalary, new Date());
        expect(taxes.nssf).toBe(expectedNssf);
      },
    );

    it('adds non-cash benefits once for PAYE only', async () => {
      const taxes = await service.calculateTaxes(50000, new Date(), {
        nonCashBenefits: 10000,
      });

      expect(taxes.nssf).toBe(3000);
      expect(taxes.nhif).toBe(1375);
      expect(taxes.housingLevy).toBe(750);
      expect(taxes.paye).toBeCloseTo(8845.85, 2);
    });

    it('applies insurance relief only to a declared qualifying premium', async () => {
      const withoutPremium = await service.calculateTaxes(50000, new Date());
      const withPremium = await service.calculateTaxes(50000, new Date(), {
        lifeInsurancePremium: 1000,
      });

      expect(withoutPremium.paye - withPremium.paye).toBeCloseTo(150, 2);
    });
  });
});
