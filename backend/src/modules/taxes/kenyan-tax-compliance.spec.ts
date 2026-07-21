import { TaxesService } from './taxes.service';
import { TaxConfigService } from '../tax-config/services/tax-config.service';
import { TaxType } from '../tax-config/entities/tax-config.entity';

describe('Kenya payroll statutory compliance (2026)', () => {
  let service: TaxesService;

  beforeEach(() => {
    const taxConfigService = {
      getActiveTaxConfig: jest.fn().mockImplementation((type: TaxType) => {
        switch (type) {
          case TaxType.NSSF_TIER1:
            return Promise.resolve({
              configuration: {
                tiers: [{ rate: 0.06, salaryFrom: 0, salaryTo: 9000 }],
              },
            });
          case TaxType.NSSF_TIER2:
            return Promise.resolve({
              configuration: {
                tiers: [{ rate: 0.06, salaryFrom: 9000, salaryTo: 108000 }],
              },
            });
          case TaxType.SHIF:
            return Promise.resolve({
              configuration: { percentage: 2.75, minAmount: 300 },
            });
          case TaxType.HOUSING_LEVY:
            return Promise.resolve({
              configuration: { percentage: 1.5 },
            });
          case TaxType.PAYE:
            return Promise.resolve({
              configuration: {
                brackets: [
                  { from: 0, to: 24000, rate: 0.1 },
                  { from: 24000, to: 32333, rate: 0.25 },
                  { from: 32333, to: 500000, rate: 0.3 },
                  { from: 500000, to: 800000, rate: 0.325 },
                  { from: 800000, to: null, rate: 0.35 },
                ],
                personalRelief: 2400,
                insuranceRelief: 0.15,
                maxInsuranceRelief: 5000,
                maxAllowablePension: 30000,
                maxMortgageInterest: 30000,
                maxPostRetirementMedicalContribution: 15000,
                nonCashBenefitExemptionThreshold: 5000,
                disabilityExemptionAmount: 150000,
              },
            });
          default:
            return Promise.resolve(null);
        }
      }),
    } as Pick<TaxConfigService, 'getActiveTaxConfig'>;

    service = new TaxesService(
      {} as never,
      {} as never,
      {} as never,
      taxConfigService as TaxConfigService,
      {} as never,
      {} as never,
    );
  });

  describe('NSSF Year 4 from February 2026', () => {
    it.each([
      [0, 0],
      [5000, 300],
      [9000, 540],
      [20000, 1200],
      [108000, 6480],
      [150000, 6480],
    ])('gross KES %s produces employee NSSF KES %s', async (gross, nssf) => {
      const result = await service.calculateTaxes(
        gross,
        new Date('2026-02-01'),
      );
      expect(result.nssf).toBe(nssf);
    });
  });

  it.each([
    [10000, 300],
    [20000, 550],
    [100000, 2750],
  ])('calculates SHIF for gross KES %s as KES %s', async (gross, shif) => {
    const result = await service.calculateTaxes(gross, new Date('2026-02-01'));
    expect(result.nhif).toBe(shif);
  });

  it.each([
    [20000, 300],
    [50000, 750],
    [100000, 1500],
  ])(
    'calculates employee AHL for gross KES %s as KES %s',
    async (gross, ahl) => {
      const result = await service.calculateTaxes(
        gross,
        new Date('2026-02-01'),
      );
      expect(result.housingLevy).toBe(ahl);
    },
  );

  it('deducts NSSF, SHIF and employee AHL before applying PAYE bands', async () => {
    const result = await service.calculateTaxes(50000, new Date('2026-02-01'));

    expect(result.paye).toBeCloseTo(5845.85, 2);
    expect(result.totalDeductions).toBeCloseTo(10970.85, 2);
  });

  it('caps allowable pension deductions at KES 30,000 per month', async () => {
    const atLimit = await service.calculateTaxes(
      100000,
      new Date('2026-02-01'),
      {
        pensionContribution: 24000,
      },
    );
    const overLimit = await service.calculateTaxes(
      100000,
      new Date('2026-02-01'),
      { pensionContribution: 50000 },
    );

    expect(overLimit.paye).toBe(atLimit.paye);
  });

  it('caps post-retirement medical-fund deductions at KES 15,000 per month', async () => {
    const withoutContribution = await service.calculateTaxes(
      100000,
      new Date('2026-02-01'),
    );
    const atLimit = await service.calculateTaxes(
      100000,
      new Date('2026-02-01'),
      { postRetirementMedicalContribution: 15000 },
    );
    const overLimit = await service.calculateTaxes(
      100000,
      new Date('2026-02-01'),
      { postRetirementMedicalContribution: 40000 },
    );

    expect(atLimit.paye).toBeLessThan(withoutContribution.paye);
    expect(overLimit.paye).toBeCloseTo(atLimit.paye, 2);
  });

  it('does not treat SHIF as an insurance-relief premium', async () => {
    const noPremium = await service.calculateTaxes(
      50000,
      new Date('2026-02-01'),
    );
    const declaredPremium = await service.calculateTaxes(
      50000,
      new Date('2026-02-01'),
      { lifeInsurancePremium: 1000 },
    );

    expect(noPremium.paye).toBeCloseTo(5845.85, 2);
    expect(noPremium.paye - declaredPremium.paye).toBeCloseTo(150, 2);
  });

  it('applies the KES 5,000 monthly non-cash benefit threshold', async () => {
    const withoutBenefit = await service.calculateTaxes(
      50000,
      new Date('2026-02-01'),
    );
    const belowThreshold = await service.calculateTaxes(
      50000,
      new Date('2026-02-01'),
      { nonCashBenefits: 4999 },
    );
    const atThreshold = await service.calculateTaxes(
      50000,
      new Date('2026-02-01'),
      { nonCashBenefits: 5000 },
    );

    expect(belowThreshold.paye).toBe(withoutBenefit.paye);
    expect(atThreshold.paye).toBeGreaterThan(withoutBenefit.paye);
  });

  it('never creates deductions for a zero-pay payroll record', async () => {
    await expect(
      service.calculateTaxes(0, new Date('2026-02-01')),
    ).resolves.toEqual({
      nssf: 0,
      nhif: 0,
      housingLevy: 0,
      paye: 0,
      totalDeductions: 0,
      taxablePay: 0,
      taxCharged: 0,
      personalReliefApplied: 0,
      insuranceReliefApplied: 0,
      allowablePensionDeduction: 0,
      allowableMortgageInterest: 0,
      allowablePostRetirementMedicalContribution: 0,
    });
  });
});
