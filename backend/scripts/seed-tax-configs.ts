import { createConnection } from 'typeorm';
import { config } from 'dotenv';
import {
  TaxConfig,
  TaxType,
  RateType,
} from '../src/modules/tax-config/entities/tax-config.entity';

// Load environment variables
config();

async function seedTaxConfigs() {
  try {
    console.log('Connecting to database...');

    // Create connection
    const connection = await createConnection({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT || '5432', 10),
      username: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      entities: [TaxConfig],
      synchronize: false,
      logging: true,
    });

    console.log('Connected successfully!');

    // Get repository
    const taxConfigRepository = connection.getRepository(TaxConfig);

    // Check if already seeded
    const existingConfigs = await taxConfigRepository.count();
    if (existingConfigs > 0) {
      console.log('Tax configurations already exist in database.');
      await connection.close();
      return;
    }

    console.log('Seeding tax configurations...');

    // Kenya tax configurations for 2024/2025
    const configs: Partial<TaxConfig>[] = [
      // PAYE - Graduated rates
      {
        taxType: TaxType.PAYE,
        rateType: RateType.GRADUATED,
        effectiveFrom: new Date('2023-07-01'),
        effectiveTo: undefined,
        configuration: {
          brackets: [
            { from: 0, to: 24000, rate: 0.1 },
            { from: 24001, to: 32333, rate: 0.25 },
            { from: 32334, to: 500000, rate: 0.3 },
            { from: 500001, to: 800000, rate: 0.325 },
            { from: 800001, to: null, rate: 0.35 },
          ],
          personalRelief: 2400,
          insuranceRelief: 0.15,
          maxInsuranceRelief: 5000,
        },
        paymentDeadline: '9th of following month',
        notes: 'PAYE rates effective July 1, 2023',
      },

      // SHIF - Replaced NHIF October 1, 2024
      {
        taxType: TaxType.SHIF,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-10-01'),
        effectiveTo: undefined,
        configuration: {
          percentage: 0.0275,
          minAmount: 300,
          maxAmount: undefined,
        },
        paymentDeadline: '9th of following month',
        notes:
          'SHIF 2.75% of gross salary, min KES 300, no cap. Replaced NHIF Oct 1, 2024',
      },

      // NSSF Tier 1 - February 2025 rates
      {
        taxType: TaxType.NSSF_TIER1,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2025-02-01'),
        effectiveTo: undefined,
        configuration: {
          tiers: [
            {
              name: 'Tier I',
              salaryFrom: 0,
              salaryTo: 8000,
              rate: 0.06,
            },
          ],
        },
        paymentDeadline: '9th of following month',
        notes: 'NSSF Tier I: 6% of first KES 8,000 (KES 480 each party)',
      },

      // NSSF Tier 2 - February 2025 rates
      {
        taxType: TaxType.NSSF_TIER2,
        rateType: RateType.TIERED,
        effectiveFrom: new Date('2025-02-01'),
        effectiveTo: undefined,
        configuration: {
          tiers: [
            {
              name: 'Tier II',
              salaryFrom: 8001,
              salaryTo: 72000,
              rate: 0.06,
            },
          ],
        },
        paymentDeadline: '9th of following month',
        notes:
          'NSSF Tier II: 6% of KES 8,001-72,000 (max KES 3,840 each party)',
      },

      // Housing Levy
      {
        taxType: TaxType.HOUSING_LEVY,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-03-19'),
        effectiveTo: undefined,
        configuration: {
          percentage: 0.015,
          minAmount: undefined,
          maxAmount: undefined,
        },
        paymentDeadline: '9th working day after end of month',
        notes:
          'Housing Levy: 1.5% employee + 1.5% employer. Fully tax-deductible from Dec 27, 2024',
      },
    ];

    // Insert configurations
    for (const configData of configs) {
      const config = taxConfigRepository.create(configData);
      await taxConfigRepository.save(config);
      console.log(`✅ Created ${configData.taxType} tax configuration`);
    }

    console.log('✅ All tax configurations seeded successfully!');

    // Verify data
    const seededConfigs = await taxConfigRepository.find();
    console.log(
      `\n📊 Total tax configurations in database: ${seededConfigs.length}`,
    );

    for (const config of seededConfigs) {
      console.log(`- ${config.taxType}: ${config.notes}`);
    }

    await connection.close();
    console.log('Database connection closed.');
  } catch (error) {
    console.error('Error seeding tax configurations:', error);
    process.exit(1);
  }
}

seedTaxConfigs();
