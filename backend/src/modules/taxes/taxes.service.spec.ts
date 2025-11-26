import { Test, TestingModule } from '@nestjs/testing';
import { TaxesService } from './taxes.service';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { Repository } from 'typeorm';
import { TaxSubmission } from './entities/tax-submission.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

describe('TaxesService', () => {
  let service: TaxesService;
  let mockTaxConfigService: Partial<TaxConfigService>;
  let mockTaxSubmissionRepo: Partial<Repository<TaxSubmission>>;
  let mockTaxTableRepo: Partial<Repository<any>>;
  let mockPayrollRecordRepo: Partial<Repository<any>>;
  let mockUsersService: Partial<any>;

  beforeEach(async () => {
    // Mock TaxConfigService
    mockTaxConfigService = {
      getActiveTaxConfig: jest.fn().mockImplementation((_taxType: string, _date: Date) => {
        return Promise.resolve(null);
      }),
      getAllActiveTaxConfigs: jest.fn().mockResolvedValue([]),
    };

    mockTaxSubmissionRepo = {
      find: jest.fn().mockResolvedValue([]),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    mockTaxTableRepo = {
      findOne: jest.fn().mockResolvedValue(null),
      find: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockImplementation((entity) => entity),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    mockPayrollRecordRepo = {
      find: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockImplementation((entity) => entity),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    mockUsersService = {
      findOneById: jest.fn().mockResolvedValue({ id: 'user-1', email: 'test@example.com' }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TaxesService,
        {
          provide: TaxConfigService,
          useValue: mockTaxConfigService,
        },
        {
          provide: getRepositoryToken(TaxSubmission),
          useValue: mockTaxSubmissionRepo,
        },
        {
          provide: 'TaxTableRepository',
          useValue: mockTaxTableRepo,
        },
        {
          provide: 'PayrollRecordRepository',
          useValue: mockPayrollRecordRepo,
        },
        {
          provide: 'USERS_SERVICE_TOKEN',
          useValue: mockUsersService,
        },
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

    it('should handle zero salary', async () => {
      const taxes = await service.calculateTaxes(0, new Date());
      const netPay = await service.calculateNetPay(0);

      expect(taxes.totalDeductions).toBe(0);
      expect(netPay).toBe(0);
    });
  });
});
