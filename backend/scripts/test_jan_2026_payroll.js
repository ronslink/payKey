const { DataSource } = require('typeorm');
require('dotenv').config();

const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'paykey',
  entities: [
    require('./src/modules/tax-config/entities/tax-config.entity').TaxConfig,
  ],
  synchronize: false,
  logging: true,
});

async function testJanuary2026Payroll() {
  try {
    await dataSource.initialize();
    console.log('✅ Database connected');

    // Test tax config lookup for January 2026
    const taxConfigRepository = dataSource.getRepository(require('./src/modules/tax-config/entities/tax-config.entity').TaxConfig);
    
    const jan2026Date = new Date('2026-01-15');
    console.log('🗓️ Testing tax config lookup for:', jan2026Date.toISOString());

    // Get PAYE config for Jan 2026
    const payeConfig = await taxConfigRepository
      .createQueryBuilder('config')
      .where('config.taxType = :taxType', { taxType: 'PAYE' })
      .andWhere('config.effectiveFrom <= :date', { date: jan2026Date })
      .andWhere('(config.effectiveTo IS NULL OR config.effectiveTo >= :date)', { date: jan2026Date })
      .andWhere('config.isActive = true')
      .orderBy('config.effectiveFrom', 'DESC')
      .getOne();

    console.log('✅ PAYE config found:', !!payeConfig);
    if (payeConfig) {
      console.log('   - Effective from:', payeConfig.effectiveFrom);
      console.log('   - Brackets:', payeConfig.configuration.brackets?.length || 0);
    }

    // Get NSSF Tier 1 config for Jan 2026
    const nssfTier1Config = await taxConfigRepository
      .createQueryBuilder('config')
      .where('config.taxType = :taxType', { taxType: 'NSSF_TIER1' })
      .andWhere('config.effectiveFrom <= :date', { date: jan2026Date })
      .andWhere('(config.effectiveTo IS NULL OR config.effectiveTo >= :date)', { date: jan2026Date })
      .andWhere('config.isActive = true')
      .orderBy('config.effectiveFrom', 'DESC')
      .getOne();

    console.log('✅ NSSF Tier 1 config found:', !!nssfTier1Config);
    if (nssfTier1Config) {
      console.log('   - Effective from:', nssfTier1Config.effectiveFrom);
      console.log('   - Tiers:', nssfTier1Config.configuration.tiers?.length || 0);
    }

    // Get NSSF Tier 2 config for Jan 2026
    const nssfTier2Config = await taxConfigRepository
      .createQueryBuilder('config')
      .where('config.taxType = :taxType', { taxType: 'NSSF_TIER2' })
      .andWhere('config.effectiveFrom <= :date', { date: jan2026Date })
      .andWhere('(config.effectiveTo IS NULL OR config.effectiveTo >= :date)', { date: jan2026Date })
      .andWhere('config.isActive = true')
      .orderBy('config.effectiveFrom', 'DESC')
      .getOne();

    console.log('✅ NSSF Tier 2 config found:', !!nssfTier2Config);
    if (nssfTier2Config) {
      console.log('   - Effective from:', nssfTier2Config.effectiveFrom);
      console.log('   - Tiers:', nssfTier2Config.configuration.tiers?.length || 0);
    }

    // Get SHIF config for Jan 2026
    const shifConfig = await taxConfigRepository
      .createQueryBuilder('config')
      .where('config.taxType = :taxType', { taxType: 'SHIF' })
      .andWhere('config.effectiveFrom <= :date', { date: jan2026Date })
      .andWhere('(config.effectiveTo IS NULL OR config.effectiveTo >= :date)', { date: jan2026Date })
      .andWhere('config.isActive = true')
      .orderBy('config.effectiveFrom', 'DESC')
      .getOne();

    console.log('✅ SHIF config found:', !!shifConfig);
    if (shifConfig) {
      console.log('   - Effective from:', shifConfig.effectiveFrom);
      console.log('   - Percentage:', shifConfig.configuration.percentage);
    }

    // Get Housing Levy config for Jan 2026
    const housingLevyConfig = await taxConfigRepository
      .createQueryBuilder('config')
      .where('config.taxType = :taxType', { taxType: 'HOUSING_LEVY' })
      .andWhere('config.effectiveFrom <= :date', { date: jan2026Date })
      .andWhere('(config.effectiveTo IS NULL OR config.effectiveTo >= :date)', { date: jan2026Date })
      .andWhere('config.isActive = true')
      .orderBy('config.effectiveFrom', 'DESC')
      .getOne();

    console.log('✅ Housing Levy config found:', !!housingLevyConfig);
    if (housingLevyConfig) {
      console.log('   - Effective from:', housingLevyConfig.effectiveFrom);
      console.log('   - Percentage:', housingLevyConfig.configuration.percentage);
    }

    // Test payroll calculation for a sample salary
    const testSalary = 50000;
    console.log('\n💰 Testing payroll calculation for salary: KES', testSalary);

    if (payeConfig && nssfTier1Config && nssfTier2Config && shifConfig && housingLevyConfig) {
      // Simulate tax calculation
      let totalDeductions = 0;

      // NSSF Tier 1 calculation
      if (nssfTier1Config.configuration.tiers) {
        const tier1 = nssfTier1Config.configuration.tiers[0];
        const tier1Amount = Math.min(testSalary, tier1.salaryTo) * tier1.rate;
        totalDeductions += tier1Amount;
        console.log('   - NSSF Tier 1:', tier1Amount.toFixed(2));
      }

      // NSSF Tier 2 calculation
      if (nssfTier2Config.configuration.tiers) {
        const tier2 = nssfTier2Config.configuration.tiers[0];
        if (testSalary > 8000) {
          const tier2Amount = Math.min(testSalary - 8000, (tier2.salaryTo || 72000) - (tier2.salaryFrom || 8001)) * tier2.rate;
          totalDeductions += tier2Amount;
          console.log('   - NSSF Tier 2:', tier2Amount.toFixed(2));
        }
      }

      // SHIF calculation
      const shifAmount = testSalary * (shifConfig.configuration.percentage / 100);
      totalDeductions += Math.max(shifAmount, shifConfig.configuration.minAmount || 0);
      console.log('   - SHIF:', Math.max(shifAmount, shifConfig.configuration.minAmount || 0).toFixed(2));

      // Housing Levy calculation
      const housingAmount = testSalary * (housingLevyConfig.configuration.percentage / 100);
      totalDeductions += housingAmount;
      console.log('   - Housing Levy:', housingAmount.toFixed(2));

      // PAYE calculation (simplified)
      const taxableIncome = testSalary - (totalDeductions - shifAmount - housingAmount); // Exclude PAYE from taxable income
      let payeAmount = 0;
      let remainingIncome = taxableIncome;
      let previousLimit = 0;

      if (payeConfig.configuration.brackets) {
        for (const bracket of payeConfig.configuration.brackets) {
          if (remainingIncome <= 0) break;

          const bracketAmount = bracket.to === null 
            ? remainingIncome
            : Math.min(remainingIncome, bracket.to - previousLimit);

          payeAmount += bracketAmount * bracket.rate;
          remainingIncome -= bracketAmount;
          previousLimit = bracket.to || previousLimit;
        }

        const personalRelief = payeConfig.configuration.personalRelief || 2400;
        payeAmount = Math.max(0, payeAmount - personalRelief);
        totalDeductions += payeAmount;
        console.log('   - PAYE:', payeAmount.toFixed(2));
      }

      const netPay = testSalary - totalDeductions;
      console.log('\n✅ PAYROLL CALCULATION RESULTS:');
      console.log('   - Gross Salary: KES', testSalary.toFixed(2));
      console.log('   - Total Deductions: KES', totalDeductions.toFixed(2));
      console.log('   - Net Pay: KES', netPay.toFixed(2));
      console.log('   - Success: All tax configurations loaded successfully for Jan 2026!');

    } else {
      console.log('❌ Missing tax configurations - payroll calculation would fail');
    }

  } catch (error) {
    console.error('❌ Error testing January 2026 payroll:', error);
  } finally {
    await dataSource.destroy();
  }
}

testJanuary2026Payroll();
