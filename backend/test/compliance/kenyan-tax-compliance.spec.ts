// test/compliance/kenyan-tax-compliance.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { TaxesService } from '../../src/modules/taxes/taxes.service';
import { TaxConfigService } from '../../src/modules/tax-config/services/tax-config.service';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { TaxSubmission } from '../../src/modules/taxes/entities/tax-submission.entity';
import { TaxPayment } from '../../src/modules/tax-payments/entities/tax-payment.entity';
import { TaxConfig } from '../../src/modules/tax-config/entities/tax-config.entity';

describe('Kenyan Tax Compliance Tests', () => {
  let service: TaxesService;
  let taxConfigService: TaxConfigService;
  let mockTaxSubmissionRepo: Partial<Repository<TaxSubmission>>;
  let mockTaxPaymentRepo: Partial<Repository<TaxPayment>>;
  let mockTaxConfigRepo: Partial<Repository<TaxConfig>>;

  beforeEach(async () => {
    mockTaxSubmissionRepo = {
      find: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
    };

    mockTaxPaymentRepo = {
      find: jest.fn(),
      save: jest.fn(),
    };

    mockTaxConfigRepo = {
      find: jest.fn(),
      save: jest.fn(),
    };

    // Set up mock tax config service with official 2024 Kenyan tax rates
    taxConfigService = {
      getNSSFRate: jest.fn().mockResolvedValue(0.06), // 6% as of 2024
      getSHIFRate: jest.fn().mockResolvedValue(0.0275), // 2.75% as of 2024
      getHousingLevyRate: jest.fn().mockResolvedValue(0.015), // 1.5% as of 2024
      getPersonalRelief: jest.fn().mockResolvedValue(2400), // KES 2,400 monthly
      getPAYEBrackets: jest.fn().mockResolvedValue([
        // 2024 KRA PAYE tax brackets
        { min: 0, max: 24000, rate: 0.1 }, // 10% on first 24,000
        { min: 24001, max: 32333, rate: 0.25 }, // 25% on next 8,333
        { min: 32334, max: 500000, rate: 0.3 }, // 30% on next 467,666
        { min: 500001, max: 800000, rate: 0.325 }, // 32.5% on next 300,000
        { min: 800001, max: Infinity, rate: 0.35 }, // 35% above 800,000
      ]),
      getNSSFMax: jest.fn().mockResolvedValue(420), // KES 420 maximum employee contribution
      getNHIFMax: jest.fn().mockResolvedValue(1700), // KES 1,700 maximum contribution
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TaxesService,
        {
          provide: TaxConfigService,
          useValue: taxConfigService,
        },
        {
          provide: getRepositoryToken(TaxSubmission),
          useValue: mockTaxSubmissionRepo,
        },
        {
          provide: getRepositoryToken(TaxPayment),
          useValue: mockTaxPaymentRepo,
        },
        {
          provide: getRepositoryToken(TaxConfig),
          useValue: mockTaxConfigRepo,
        },
      ],
    }).compile();

    service = module.get<TaxesService>(TaxesService);
  });

  describe('2024 KRA Tax Bracket Compliance', () => {
    const testCases = [
      // Salary, Expected PAYE, Expected Net (after basic deductions)
      { salary: 10000, expectedPAYE: 0, description: 'Below PAYE threshold' },
      { salary: 24000, expectedPAYE: 0, description: 'At first bracket limit' },
      {
        salary: 25000,
        expectedPAYE: 100,
        description: 'Just above first bracket',
      },
      {
        salary: 32333,
        expectedPAYE: 2083,
        description: 'At second bracket limit',
      },
      { salary: 50000, expectedPAYE: 8483, description: 'Mid third bracket' },
      {
        salary: 100000,
        expectedPAYE: 28483,
        description: 'Higher salary bracket',
      },
      { salary: 200000, expectedPAYE: 73483, description: 'Very high salary' },
      {
        salary: 500000,
        expectedPAYE: 163483,
        description: 'At fourth bracket limit',
      },
      {
        salary: 1000000,
        expectedPAYE: 338483,
        description: 'Above all brackets',
      },
    ];

    testCases.forEach(({ salary, expectedPAYE, description }) => {
      it(`should calculate PAYE correctly for ${description}: KES ${salary}`, async () => {
        const paye = await service.calculatePAYEFromConfig(
          salary,
          0,
          new Date('2024-01-01'),
        );
        expect(paye).toBeCloseTo(expectedPAYE, 0);
      });
    });
  });

  describe('NSSF Contribution Compliance', () => {
    const nssfTestCases = [
      // Salary, Expected Employee Contribution, Expected Employer Contribution
      { salary: 6000, employeeRate: 0.06, employerRate: 0.06, totalRate: 0.12 },
      {
        salary: 18000,
        employeeRate: 0.06,
        employerRate: 0.06,
        totalRate: 0.12,
      },
      {
        salary: 50000,
        employeeRate: 0.06,
        employerRate: 0.06,
        totalRate: 0.12,
      },
      {
        salary: 100000,
        employeeRate: 0.04,
        employerRate: 0.06,
        totalRate: 0.1,
      },
    ];

    nssfTestCases.forEach(
      ({ salary, employeeRate, employerRate, totalRate }) => {
        it(`should calculate NSSF correctly for salary KES ${salary}`, async () => {
          const nssf = await service.calculateNSSF(
            salary,
            new Date('2024-01-01'),
          );
          const expectedEmployeeContribution = Math.min(
            salary * employeeRate,
            420,
          );
          const expectedEmployerContribution = salary * employerRate;
          const expectedTotal =
            expectedEmployeeContribution + expectedEmployerContribution;

          expect(nssf.employeeContribution).toBeCloseTo(
            expectedEmployeeContribution,
            0,
          );
          expect(nssf.employerContribution).toBeCloseTo(
            expectedEmployerContribution,
            0,
          );
          expect(nssf.totalContribution).toBeCloseTo(expectedTotal, 0);
        });
      },
    );

    it('should cap NSSF contributions at maximum limits', async () => {
      const veryHighSalary = 1000000; // KES 1 million
      const nssf = await service.calculateNSSF(
        veryHighSalary,
        new Date('2024-01-01'),
      );

      expect(nssf.employeeContribution).toBeLessThanOrEqual(420);
      expect(nssf.employerContribution).toBeLessThanOrEqual(600);
    });
  });

  describe('SHIF Contribution Compliance', () => {
    it('should calculate SHIF correctly with 2024 rates', async () => {
      const testSalaries = [15000, 50000, 100000];

      for (const salary of testSalaries) {
        const shif = await service.calculateSHIF(
          salary,
          new Date('2024-01-01'),
        );
        const expectedContribution = salary * 0.0275; // 2.75%

        expect(shif).toBeCloseTo(expectedContribution, 0);
      }
    });

    it('should apply SHIF maximum contribution limit', async () => {
      const highSalary = 100000; // KES 100,000
      const shif = await service.calculateSHIF(
        highSalary,
        new Date('2024-01-01'),
      );

      expect(shif).toBeLessThanOrEqual(1700); // KES 1,700 max
    });
  });

  describe('Housing Levy Compliance', () => {
    it('should calculate Housing Levy at 1.5% as per 2024 regulations', async () => {
      const salary = 50000;
      const levy = await service.calculateHousingLevy(
        salary,
        new Date('2024-01-01'),
      );

      expect(levy).toBe(750); // 1.5% of 50,000
    });

    it('should apply Housing Levy without cap', async () => {
      const highSalary = 500000;
      const levy = await service.calculateHousingLevy(
        highSalary,
        new Date('2024-01-01'),
      );
      const expectedLevy = highSalary * 0.015; // 1.5%

      expect(levy).toBe(expectedLevy);
    });
  });

  describe('Personal Relief Compliance', () => {
    it('should apply KES 2,400 monthly personal relief', async () => {
      const grossSalary = 30000; // Low salary that would have PAYE
      const nssf = await service.calculateNSSF(
        grossSalary,
        new Date('2024-01-01'),
      );
      const taxableIncome = grossSalary - nssf.employeeContribution;
      const paye = await service.calculatePAYEFromConfig(
        grossSalary,
        nssf.employeeContribution,
        new Date('2024-01-01'),
      );

      // Should apply personal relief of KES 2,400
      expect(paye).toBeLessThan(taxableIncome * 0.1 - 2400);
    });

    it('should not apply personal relief if PAYE is zero', async () => {
      const grossSalary = 15000; // Below PAYE threshold
      const paye = await service.calculatePAYEFromConfig(
        grossSalary,
        0,
        new Date('2024-01-01'),
      );

      expect(paye).toBe(0);
    });
  });

  describe('Tax Filing Compliance', () => {
    it('should generate compliant tax submission data', async () => {
      const testUserId = 'test-user-123';
      const payPeriodId = 'test-period-123';
      const submissionDate = new Date('2024-01-31');

      const mockSubmission = {
        id: 'submission-123',
        userId: testUserId,
        payPeriodId,
        submissionDate,
        totalGross: 150000,
        totalNSSF: 9000,
        totalSHIF: 4125,
        totalHousingLevy: 2250,
        totalPAYE: 28483,
        status: 'SUBMITTED',
      };

      (mockTaxSubmissionRepo.create as jest.Mock).mockReturnValue(
        mockSubmission,
      );
      (mockTaxSubmissionRepo.save as jest.Mock).mockResolvedValue(
        mockSubmission,
      );

      const submission = await service.generateTaxSubmission(
        payPeriodId,
        testUserId,
      );

      expect(submission.totalGross).toBe(150000);
      expect(submission.totalNSSF).toBeGreaterThan(0);
      expect(submission.totalSHIF).toBeGreaterThan(0);
      expect(submission.totalHousingLevy).toBeGreaterThan(0);
      expect(submission.totalPAYE).toBeGreaterThan(0);
      expect(submission.status).toBe('SUBMITTED');
    });

    it('should validate tax submission completeness', async () => {
      const incompleteSubmission = {
        totalGross: 0, // Missing required data
        totalNSSF: null,
        totalSHIF: undefined,
      };

      await expect(
        service.validateTaxSubmission(incompleteSubmission as any),
      ).rejects.toThrow('Incomplete tax submission data');
    });
  });

  describe('Audit Trail Compliance', () => {
    it('should maintain audit logs for all tax calculations', async () => {
      const salary = 50000;
      const calculationDate = new Date('2024-01-15');

      await service.calculateTaxes(salary, calculationDate);

      // Verify that calculation was logged (in a real implementation)
      expect(mockTaxSubmissionRepo.save).toHaveBeenCalled();
    });

    it('should track tax calculation history', async () => {
      const userId = 'test-user-123';
      const salary = 50000;

      // Multiple calculations
      await service.calculateTaxes(salary, new Date('2024-01-15'));
      await service.calculateTaxes(salary, new Date('2024-02-15'));

      // Should have created audit records
      expect(mockTaxSubmissionRepo.save).toHaveBeenCalledTimes(2);
    });
  });

  describe('Data Retention Compliance', () => {
    it('should retain tax records for required 7-year period', async () => {
      const oldSubmission = {
        id: 'old-submission',
        submissionDate: new Date('2017-01-01'), // 7 years ago
        status: 'ARCHIVED',
      };

      (mockTaxSubmissionRepo.find as jest.Mock).mockResolvedValue([
        oldSubmission,
      ]);

      const oldRecords = await service.getTaxRecordsOlderThan(7);

      expect(oldRecords.length).toBeGreaterThan(0);
      expect(oldRecords[0].submissionDate.getFullYear()).toBeLessThan(2020);
    });

    it('should enforce data retention policies', async () => {
      const veryOldSubmission = {
        id: 'very-old-submission',
        submissionDate: new Date('2015-01-01'), // 9 years ago
        status: 'ARCHIVED',
      };

      (mockTaxSubmissionRepo.find as jest.Mock).mockResolvedValue([
        veryOldSubmission,
      ]);

      const recordsToArchive = await service.getRecordsForArchival();

      expect(recordsToArchive.length).toBeGreaterThan(0);
      // In a real implementation, these would be archived or deleted
    });
  });

  describe('Multi-currency and Exchange Rate Compliance', () => {
    it('should handle USD to KES conversion for compliance', async () => {
      const usdSalary = 1000; // USD
      const exchangeRate = 130; // KES per USD
      const expectedKesSalary = usdSalary * exchangeRate;

      const taxes = await service.calculateTaxes(
        expectedKesSalary,
        new Date('2024-01-01'),
      );

      expect(taxes.grossSalary).toBeCloseTo(expectedKesSalary, 0);
    });

    it('should validate exchange rate data sources', async () => {
      // In a real implementation, would validate against CBK rates
      const validExchangeRate = 130.5;
      const invalidExchangeRate = -1;

      await expect(
        service.validateExchangeRate(validExchangeRate),
      ).resolves.toBe(true);

      await expect(
        service.validateExchangeRate(invalidExchangeRate),
      ).rejects.toThrow('Invalid exchange rate');
    });
  });

  describe('Year-end Tax Reconciliation', () => {
    it('should reconcile annual tax totals', async () => {
      const userId = 'test-user-123';
      const year = 2024;

      const mockMonthlyData = [
        { month: 1, gross: 50000, paye: 8000, nssf: 3000 },
        { month: 2, gross: 50000, paye: 8000, nssf: 3000 },
        // ... more months
      ];

      (mockTaxSubmissionRepo.find as jest.Mock).mockResolvedValue(
        mockMonthlyData,
      );

      const annualReconciliation = await service.reconcileAnnualTaxes(
        userId,
        year,
      );

      expect(annualReconciliation.totalAnnualGross).toBe(100000); // 2 months * 50k
      expect(annualReconciliation.totalAnnualPAYE).toBe(16000); // 2 months * 8k
      expect(annualReconciliation.totalAnnualNSSF).toBe(6000); // 2 months * 3k
    });

    it('should detect tax calculation discrepancies', async () => {
      const userId = 'test-user-123';
      const year = 2024;

      // Mock inconsistent data
      const inconsistentData = [
        { month: 1, gross: 50000, paye: 8000, nssf: 5000 }, // Wrong NSSF
        { month: 2, gross: 50000, paye: 8000, nssf: 3000 },
      ];

      (mockTaxSubmissionRepo.find as jest.Mock).mockResolvedValue(
        inconsistentData,
      );

      const discrepancies = await service.detectTaxDiscrepancies(userId, year);

      expect(discrepancies.length).toBeGreaterThan(0);
      expect(discrepancies[0].type).toBe('NSSF_MISMATCH');
    });
  });

  describe('Regulatory Updates Compliance', () => {
    it('should handle KRA tax rate changes mid-year', async () => {
      const salary = 50000;
      const oldRateDate = new Date('2024-06-01'); // Before July change
      const newRateDate = new Date('2024-08-01'); // After July change

      // Mock that rates changed in July 2024
      jest
        .spyOn(taxConfigService, 'getPAYEBrackets')
        .mockImplementation((date: Date) => {
          if (date.getMonth() >= 6) {
            // July onwards
            return Promise.resolve([
              { min: 0, max: 24000, rate: 0.1 },
              { min: 24001, max: 32333, rate: 0.25 },
              { min: 32334, max: 500000, rate: 0.32 }, // Increased from 30%
              { min: 500001, max: 800000, rate: 0.35 },
              { min: 800001, max: Infinity, rate: 0.375 }, // Increased from 35%
            ]);
          } else {
            return Promise.resolve([
              { min: 0, max: 24000, rate: 0.1 },
              { min: 24001, max: 32333, rate: 0.25 },
              { min: 32334, max: 500000, rate: 0.3 },
              { min: 500001, max: 800000, rate: 0.325 },
              { min: 800001, max: Infinity, rate: 0.35 },
            ]);
          }
        });

      const oldRatePaye = await service.calculatePAYEFromConfig(
        salary,
        0,
        oldRateDate,
      );
      const newRatePaye = await service.calculatePAYEFromConfig(
        salary,
        0,
        newRateDate,
      );

      expect(newRatePaye).toBeGreaterThan(oldRatePaye); // Higher rates should result in higher PAYE
    });
  });

  describe('Integration with KRA Systems', () => {
    it('should format tax data for KRA submission', async () => {
      const taxSubmission = {
        totalGross: 600000,
        totalNSSF: 36000,
        totalSHIF: 16500,
        totalHousingLevy: 9000,
        totalPAYE: 120000,
        employeeCount: 10,
      };

      const kraFormat = await service.formatForKRASubmission(taxSubmission);

      expect(kraFormat).toHaveProperty('employerDetails');
      expect(kraFormat).toHaveProperty('employeeDetails');
      expect(kraFormat).toHaveProperty('taxSummary');
      expect(kraFormat.employerDetails.taxPayerID).toBeDefined();
      expect(kraFormat.employeeDetails).toHaveLength(10);
    });

    it('should validate KRA submission format', async () => {
      const invalidSubmission = {
        totalGross: -1000, // Invalid negative amount
        totalNSSF: 'invalid', // Wrong type
        employeeCount: 0, // Invalid employee count
      };

      await expect(
        service.validateKRASubmission(invalidSubmission as any),
      ).rejects.toThrow('Invalid KRA submission format');
    });
  });
});
