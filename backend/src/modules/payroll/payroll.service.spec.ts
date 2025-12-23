import { Test, TestingModule } from '@nestjs/testing';
import { PayrollService } from './payroll.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Worker } from '../workers/entities/worker.entity';
import { PayrollRecord } from './entities/payroll-record.entity';
import { PayPeriod } from './entities/pay-period.entity';
import { TaxesService } from '../taxes/taxes.service';
import { PayrollPaymentService } from '../payments/payroll-payment.service';
import { ActivitiesService } from '../activities/activities.service';
import { PayslipService } from './payslip.service';
import { DataSource } from 'typeorm';

describe('PayrollService', () => {
  let service: PayrollService;
  let workersRepo: { find: jest.Mock; findOne: jest.Mock };
  let taxesService: {
    calculateTaxes: jest.Mock;
    generateTaxSubmission: jest.Mock;
  };

  const mockWorker = {
    id: 'worker-1',
    name: 'John Doe',
    salaryGross: 50000,
    phoneNumber: '+254712345678',
    userId: 'user-1',
    isActive: true,
  };

  const mockTaxBreakdown = {
    nssf: 1080,
    nhif: 1200,
    housingLevy: 750,
    paye: 8500,
    totalDeductions: 11530,
    taxableIncome: 48920,
    personalRelief: 2400,
  };

  beforeEach(async () => {
    workersRepo = {
      find: jest.fn(),
      findOne: jest.fn(),
    };

    taxesService = {
      calculateTaxes: jest.fn(),
      generateTaxSubmission: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PayrollService,
        {
          provide: getRepositoryToken(Worker),
          useValue: workersRepo,
        },
        {
          provide: getRepositoryToken(PayrollRecord),
          useValue: { find: jest.fn(), save: jest.fn(), create: jest.fn() },
        },
        {
          provide: getRepositoryToken(PayPeriod),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: TaxesService,
          useValue: taxesService,
        },
        {
          provide: PayrollPaymentService,
          useValue: { processPayouts: jest.fn() },
        },
        {
          provide: ActivitiesService,
          useValue: { logActivity: jest.fn() },
        },
        {
          provide: PayslipService,
          useValue: {
            generatePayslipsBatch: jest.fn(),
            generatePayslip: jest.fn(),
          },
        },
        {
          provide: DataSource,
          useValue: {
            transaction: jest.fn((cb) =>
              cb({ save: jest.fn(), findOne: jest.fn() }),
            ),
          },
        },
      ],
    }).compile();

    service = module.get<PayrollService>(PayrollService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('calculatePayrollForUser', () => {
    it('should calculate payroll for valid workers correctly', async () => {
      // Mock workers found
      workersRepo.find.mockResolvedValue([mockWorker]);

      // Mock tax calculation
      taxesService.calculateTaxes.mockResolvedValue(mockTaxBreakdown);

      const result = await service.calculatePayrollForUser('user-1');

      // Assertions
      expect(workersRepo.find).toHaveBeenCalledWith({
        where: { userId: 'user-1', isActive: true },
      });
      expect(taxesService.calculateTaxes).toHaveBeenCalledWith(50000);

      expect(result.summary.workerCount).toBe(1);
      expect(result.summary.totalGross).toBe(50000);
      expect(result.summary.totalDeductions).toBe(11530);

      // Net pay = 50000 - 11530 = 38470
      expect(result.summary.totalNetPay).toBe(38470);
      expect(result.payrollItems[0].netPay).toBe(38470);
    });

    it('should handle zero or invalid salary gracefully', async () => {
      const invalidWorker = { ...mockWorker, salaryGross: 0 };
      workersRepo.find.mockResolvedValue([invalidWorker]);

      const result = await service.calculatePayrollForUser('user-1');

      expect(taxesService.calculateTaxes).not.toHaveBeenCalled();

      expect(result.payrollItems[0].error).toBe('Invalid salary amount');
      expect(result.payrollItems[0].netPay).toBe(0);
      expect(result.summary.totalNetPay).toBe(0);
    });

    it('should handle tax calculation errors gracefully', async () => {
      workersRepo.find.mockResolvedValue([mockWorker]);
      taxesService.calculateTaxes.mockRejectedValue(
        new Error('Tax service down'),
      );

      const result = await service.calculatePayrollForUser('user-1');

      expect(result.payrollItems[0].error).toBe('Tax service down');
      expect(result.payrollItems[0].netPay).toBe(0);
      // Ensure it doesn't crash the whole batch
      expect(result.summary.workerCount).toBe(1);
    });

    it('should aggregate totals correctly for multiple workers', async () => {
      const workers = [
        { ...mockWorker, id: '1', salaryGross: 50000 },
        { ...mockWorker, id: '2', salaryGross: 30000 },
      ];
      workersRepo.find.mockResolvedValue(workers);

      taxesService.calculateTaxes
        .mockResolvedValueOnce(mockTaxBreakdown) // For 50k
        .mockResolvedValueOnce({ ...mockTaxBreakdown, totalDeductions: 5000 }); // For 30k (dummy)

      const result = await service.calculatePayrollForUser('user-1');

      expect(result.summary.workerCount).toBe(2);
      expect(result.summary.totalGross).toBe(80000); // 50k + 30k
      expect(result.summary.totalDeductions).toBe(16530); // 11530 + 5000

      // Net: (50k - 11530) + (30k - 5000) = 38470 + 25000 = 63470
      expect(result.summary.totalNetPay).toBe(63470);
    });
  });
});
