import { Test, TestingModule } from '@nestjs/testing';
import { TaxesService } from './taxes.service';
import { TaxConfigService } from './tax-config.service';
import { Repository } from 'typeorm';
import { TaxSubmission } from './entities/tax-submission.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

describe('TaxesService', () => {
    let service: TaxesService;
    let mockTaxConfigService: Partial<TaxConfigService>;
    let mockTaxSubmissionRepo: Partial<Repository<TaxSubmission>>;

    beforeEach(async () => {
        // Mock TaxConfigService
        mockTaxConfigService = {
            getNSSFRate: jest.fn().mockResolvedValue(0.06),
            getSHIFRate: jest.fn().mockResolvedValue(0.0275),
            getHousingLevyRate: jest.fn().mockResolvedValue(0.015),
            getPAYEBrackets: jest.fn().mockResolvedValue([
                { min: 0, max: 24000, rate: 0.1 },
                { min: 24001, max: 32333, rate: 0.25 },
                { min: 32334, max: 500000, rate: 0.3 },
                { min: 500001, max: 800000, rate: 0.325 },
                { min: 800001, max: Infinity, rate: 0.35 },
            ]),
            getPersonalRelief: jest.fn().mockResolvedValue(2400),
        };

        mockTaxSubmissionRepo = {
            find: jest.fn().mockResolvedValue([]),
            save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
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
            ],
        }).compile();

        service = module.get<TaxesService>(TaxesService);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('calculateNSSF', () => {
        it('should calculate NSSF correctly for salary of 50000', async () => {
            const nssf = await service.calculateNSSF(50000, new Date());
            expect(nssf).toBe(3000); // 6% of 50000
        });

        it('should calculate NSSF correctly for salary of 10000', async () => {
            const nssf = await service.calculateNSSF(10000, new Date());
            expect(nssf).toBe(600); // 6% of 10000
        });
    });

    describe('calculateSHIF', () => {
        it('should calculate SHIF correctly for salary of 50000', async () => {
            const shif = await service.calculateSHIF(50000, new Date());
            expect(shif).toBe(1375); // 2.75% of 50000
        });
    });

    describe('calculateHousingLevy', () => {
        it('should calculate Housing Levy correctly for salary of 50000', async () => {
            const levy = await service.calculateHousingLevy(50000, new Date());
            expect(levy).toBe(750); // 1.5% of 50000
        });
    });

    describe('calculatePAYEFromConfig', () => {
        it('should calculate PAYE correctly for taxable income in first bracket', async () => {
            const grossSalary = 20000;
            const nssf = 1200;
            const paye = await service.calculatePAYEFromConfig(grossSalary, nssf, new Date());

            // Taxable = 20000 - 1200 = 18800
            // PAYE = 18800 * 0.1 = 1880
            // After personal relief: 1880 - 2400 = 0 (minimum 0)
            expect(paye).toBe(0);
        });

        it('should calculate PAYE correctly for taxable income in multiple brackets', async () => {
            const grossSalary = 50000;
            const nssf = 3000;
            const paye = await service.calculatePAYEFromConfig(grossSalary, nssf, new Date());

            // Taxable = 50000 - 3000 = 47000
            // PAYE = (24000 * 0.1) + (8333 * 0.25) + (14667 * 0.3)
            //      = 2400 + 2083.25 + 4400.1 = 8883.35
            // After personal relief: 8883.35 - 2400 = 6483.35
            expect(paye).toBeCloseTo(6483, 0);
        });
    });

    describe('calculateTaxes', () => {
        it('should calculate all taxes correctly for salary of 50000', async () => {
            const result = await service.calculateTaxes(50000, new Date());

            expect(result.nssf).toBe(3000);
            expect(result.nhif).toBe(1375); // SHIF
            expect(result.housingLevy).toBe(750);
            expect(result.paye).toBeGreaterThan(0);
            expect(result.totalDeductions).toBeGreaterThan(0);
            expect(result.totalDeductions).toBe(
                result.nssf + result.nhif + result.housingLevy + result.paye
            );
        });
    });
});
