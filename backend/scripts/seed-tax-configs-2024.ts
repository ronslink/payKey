import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { TaxConfigService } from '../src/modules/tax-config/services/tax-config.service';
import {
  TaxType,
  RateType,
} from '../src/modules/tax-config/entities/tax-config.entity';

async function seed2024TaxConfigs() {
  console.log('📊 Seeding 2024 Kenya tax configurations...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const taxConfigService = app.get(TaxConfigService);

  try {
    // NHIF - Banded rates (Jan 2024 - Sep 2024)
    const nhifConfig = {
      taxType: TaxType.NHIF,
      rateType: RateType.BANDED,
      effectiveFrom: new Date('2024-01-01'),
      effectiveTo: new Date('2024-09-30'),
      configuration: {
        bands: [
          { from: 0, to: 5999, amount: 150 },
          { from: 6000, to: 7999, amount: 300 },
          { from: 8000, to: 11999, amount: 400 },
          { from: 12000, to: 14999, amount: 500 },
          { from: 15000, to: 19999, amount: 600 },
          { from: 20000, to: 24999, amount: 750 },
          { from: 25000, to: 29999, amount: 850 },
          { from: 30000, to: 34999, amount: 900 },
          { from: 35000, to: 39999, amount: 950 },
          { from: 40000, to: 44999, amount: 1000 },
          { from: 45000, to: 49999, amount: 1100 },
          { from: 50000, to: 59999, amount: 1200 },
          { from: 60000, to: 69999, amount: 1300 },
          { from: 70000, to: 79999, amount: 1400 },
          { from: 80000, to: 89999, amount: 1500 },
          { from: 90000, to: 99999, amount: 1600 },
          { from: 100000, to: null, amount: 1700 },
        ],
      },
      paymentDeadline: '9th of following month',
      notes: 'NHIF banded rates for 2024 (replaced by SHIF Oct 1, 2024)',
    };

    // NSSF Tier 1 - 2024 rates
    const nssfTier1Config = {
      taxType: TaxType.NSSF_TIER1,
      rateType: RateType.TIERED,
      effectiveFrom: new Date('2024-01-01'),
      effectiveTo: new Date('2025-01-31'),
      configuration: {
        tiers: [
          {
            name: 'Tier I',
            salaryFrom: 0,
            salaryTo: 7000,
            rate: 0.06,
          },
        ],
      },
      paymentDeadline: '9th of following month',
      notes: 'NSSF Tier I 2024: 6% of first KES 7,000 (KES 420 each party)',
    };

    // NSSF Tier 2 - 2024 rates
    const nssfTier2Config = {
      taxType: TaxType.NSSF_TIER2,
      rateType: RateType.TIERED,
      effectiveFrom: new Date('2024-01-01'),
      effectiveTo: new Date('2025-01-31'),
      configuration: {
        tiers: [
          {
            name: 'Tier II',
            salaryFrom: 7001,
            salaryTo: 36000,
            rate: 0.06,
          },
        ],
      },
      paymentDeadline: '9th of following month',
      notes:
        'NSSF Tier II 2024: 6% of KES 7,001-36,000 (max KES 1,740 each party)',
    };

    await taxConfigService.createTaxConfig(nhifConfig);
    console.log('✅ NHIF 2024 configuration created');

    await taxConfigService.createTaxConfig(nssfTier1Config);
    console.log('✅ NSSF Tier 1 2024 configuration created');

    await taxConfigService.createTaxConfig(nssfTier2Config);
    console.log('✅ NSSF Tier 2 2024 configuration created');

    console.log('\n🎉 2024 tax configurations seeded successfully!');
  } catch (error) {
    console.error('❌ Error seeding 2024 tax configs:', (error as any).message);
  } finally {
    await app.close();
  }
}

seed2024TaxConfigs();
