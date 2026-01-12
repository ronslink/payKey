import { Test, TestingModule } from '@nestjs/testing';
import { PayPeriodsService } from './pay-periods.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  PayPeriod,
  PayPeriodStatus,
  PayPeriodFrequency,
} from './entities/pay-period.entity';
import { PayrollRecord } from './entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { TaxPaymentsService } from '../tax-payments/services/tax-payments.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('PayPeriodsService', () => {
  let service: PayPeriodsService;
  let payPeriodRepo: {
    create: jest.Mock;
    save: jest.Mock;
    findOne: jest.Mock;
    update: jest.Mock;
    remove: jest.Mock;
    createQueryBuilder: jest.Mock;
  };
  let payrollRecordRepo: {
    find: jest.Mock;
    count: jest.Mock;
    update: jest.Mock;
  };

  const mockPayPeriod: Partial<PayPeriod> = {
    id: 'period-1',
    name: 'January 2025',
    startDate: '2025-01-01',
    endDate: '2025-01-31',
    status: PayPeriodStatus.DRAFT,
    userId: 'user-1',
  };

  beforeEach(async () => {
    const queryBuilder = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue(null),
      orderBy: jest.fn().mockReturnThis(),
      skip: jest.fn().mockReturnThis(),
      take: jest.fn().mockReturnThis(),
      getManyAndCount: jest.fn().mockResolvedValue([[], 0]),
    };

    payPeriodRepo = {
      create: jest.fn().mockImplementation((dto) => ({ ...dto, id: 'new-id' })),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
      findOne: jest.fn(),
      update: jest.fn().mockResolvedValue({ affected: 1 }),
      remove: jest.fn().mockResolvedValue(undefined),
      createQueryBuilder: jest.fn().mockReturnValue(queryBuilder),
    };

    payrollRecordRepo = {
      find: jest.fn().mockResolvedValue([]),
      count: jest.fn().mockResolvedValue(0),
      update: jest.fn().mockResolvedValue({ affected: 0 }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PayPeriodsService,
        { provide: getRepositoryToken(PayPeriod), useValue: payPeriodRepo },
        {
          provide: getRepositoryToken(PayrollRecord),
          useValue: payrollRecordRepo,
        },
        {
          provide: getRepositoryToken(TaxSubmission),
          useValue: { findOne: jest.fn(), create: jest.fn(), save: jest.fn() },
        },
        {
          provide: TaxPaymentsService,
          useValue: { ensureObligation: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<PayPeriodsService>(PayPeriodsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a pay period with valid dates', async () => {
      const dto = {
        name: 'February 2025',
        startDate: '2025-02-01',
        endDate: '2025-02-28',
        payDate: '2025-02-28',
        frequency: PayPeriodFrequency.MONTHLY,
      };

      const result = await service.create(dto as any, 'user-1');

      expect(payPeriodRepo.create).toHaveBeenCalled();
      expect(payPeriodRepo.save).toHaveBeenCalled();
      expect(result.status).toBe(PayPeriodStatus.DRAFT);
    });

    it('should reject if start date is after end date', async () => {
      const dto = {
        name: 'Invalid Period',
        startDate: '2025-02-28',
        endDate: '2025-02-01',
        payDate: '2025-02-28',
        frequency: PayPeriodFrequency.MONTHLY,
      };

      await expect(service.create(dto as any, 'user-1')).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.create(dto as any, 'user-1')).rejects.toThrow(
        'Start date must be before end date',
      );
    });

    it('should reject overlapping pay periods', async () => {
      // Mock overlap detection
      const queryBuilder = payPeriodRepo.createQueryBuilder();
      queryBuilder.getOne.mockResolvedValue(mockPayPeriod); // Simulate overlap found

      const dto = {
        name: 'Overlapping Period',
        startDate: '2025-01-15',
        endDate: '2025-02-15',
        payDate: '2025-02-15',
        frequency: PayPeriodFrequency.MONTHLY,
      };

      await expect(service.create(dto as any, 'user-1')).rejects.toThrow(
        'Standard pay period overlaps with existing standard period',
      );
    });
  });

  describe('findOne', () => {
    it('should return a pay period if found', async () => {
      payPeriodRepo.findOne.mockResolvedValue(mockPayPeriod);

      const result = await service.findOne('period-1');

      expect(result).toEqual(mockPayPeriod);
    });

    it('should throw NotFoundException if not found', async () => {
      payPeriodRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('validateStatusTransition (via update)', () => {
    it('should allow DRAFT -> ACTIVE', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.DRAFT,
      });

      await expect(
        service.update('period-1', { status: PayPeriodStatus.ACTIVE }),
      ).resolves.toBeDefined();
    });

    it('should allow PROCESSING -> COMPLETED', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.PROCESSING,
      });

      await expect(
        service.update('period-1', { status: PayPeriodStatus.COMPLETED }),
      ).resolves.toBeDefined();
    });

    it('should reject invalid transitions (DRAFT -> COMPLETED)', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.DRAFT,
      });

      await expect(
        service.update('period-1', { status: PayPeriodStatus.COMPLETED }),
      ).rejects.toThrow('Invalid status transition from DRAFT to COMPLETED');
    });

  });

  describe('remove', () => {
    it('should prevent deletion of COMPLETED periods', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.COMPLETED,
      });

      await expect(service.remove('period-1')).rejects.toThrow(
        'Cannot delete pay period that is processing, completed, or closed',
      );
    });

    it('should prevent deletion if payroll records exist', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.DRAFT,
      });
      payrollRecordRepo.count.mockResolvedValue(5); // Has records

      await expect(service.remove('period-1')).rejects.toThrow(
        'Cannot delete pay period with existing payroll records',
      );
    });

    it('should allow deletion of DRAFT period with no records', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.DRAFT,
      });
      payrollRecordRepo.count.mockResolvedValue(0);

      await expect(service.remove('period-1')).resolves.toBeUndefined();
      expect(payPeriodRepo.remove).toHaveBeenCalled();
    });
  });

  describe('process', () => {
    it('should require payroll records to process', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.ACTIVE,
      });
      payrollRecordRepo.find.mockResolvedValue([]); // No records

      await expect(service.process('period-1')).rejects.toThrow(
        'Cannot process payroll with no records. Please add workers first.',
      );
    });

    it('should calculate totals and update status when processing', async () => {
      payPeriodRepo.findOne.mockResolvedValue({
        ...mockPayPeriod,
        status: PayPeriodStatus.ACTIVE,
      });
      payrollRecordRepo.find.mockResolvedValue([
        { grossSalary: 50000, netSalary: 40000, taxAmount: 10000 },
        { grossSalary: 30000, netSalary: 25000, taxAmount: 5000 },
      ]);

      await service.process('period-1');

      expect(payPeriodRepo.update).toHaveBeenCalledWith(
        'period-1',
        expect.objectContaining({
          status: PayPeriodStatus.PROCESSING,
          totalGrossAmount: 80000,
          totalNetAmount: 65000,
          totalTaxAmount: 15000,
          processedWorkers: 2,
        }),
      );
    });
  });
});
