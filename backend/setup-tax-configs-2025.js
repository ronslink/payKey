const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  database: 'paykey',
  user: 'postgres',
  password: 'admin',
  port: 5432,
});

async function setupTaxConfigs() {
  try {
    await client.connect();
    console.log('📊 Setting up tax_configs table with 2025 Kenya tax data...\n');
    
    // 1. Create the tax_configs table
    console.log('🔨 Creating tax_configs table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS tax_configs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "taxType" VARCHAR(50) NOT NULL,
        "rateType" VARCHAR(50) NOT NULL,
        "effectiveFrom" DATE NOT NULL,
        "effectiveTo" DATE,
        configuration JSONB NOT NULL,
        "paymentDeadline" TEXT DEFAULT '9th of following month',
        "isActive" BOOLEAN DEFAULT true,
        notes TEXT,
        "createdAt" TIMESTAMP DEFAULT NOW(),
        "updatedAt" TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ tax_configs table created\n');
    
    // 2. Check if data already exists
    const existingCount = await client.query('SELECT COUNT(*) FROM tax_configs');
    if (parseInt(existingCount.rows[0].count) > 0) {
      console.log(`⚠️  Found ${existingCount.rows[0].count} existing tax configs. Clearing old data...`);
      await client.query('DELETE FROM tax_configs');
    }
    
    // 3. Seed with 2025 Kenya tax configurations
    console.log('📝 Seeding 2025 Kenya tax configurations...\n');
    
    const configs = [
      {
        taxType: 'PAYE',
        rateType: 'GRADUATED',
        effectiveFrom: '2023-07-01',
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
        notes: 'PAYE rates effective July 1, 2023 (current for 2025)',
      },
      {
        taxType: 'SHIF',
        rateType: 'PERCENTAGE',
        effectiveFrom: '2024-10-01',
        configuration: {
          percentage: 0.0275,
          minAmount: 300,
        },
        paymentDeadline: '9th of following month',
        notes: 'SHIF 2.75% of gross salary, min KES 300. Replaced NHIF Oct 1, 2024',
      },
      {
        taxType: 'NSSF_TIER1',
        rateType: 'TIERED',
        effectiveFrom: '2025-02-01',
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
        notes: 'NSSF Tier I: 6% of first KES 8,000 (KES 480 employee)',
      },
      {
        taxType: 'NSSF_TIER2',
        rateType: 'TIERED',
        effectiveFrom: '2025-02-01',
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
        notes: 'NSSF Tier II: 6% of KES 8,001-72,000 (max KES 3,840 employee)',
      },
      {
        taxType: 'HOUSING_LEVY',
        rateType: 'PERCENTAGE',
        effectiveFrom: '2024-03-19',
        configuration: {
          percentage: 0.015,
        },
        paymentDeadline: '9th working day after end of month',
        notes: 'Housing Levy: 1.5% employee + 1.5% employer',
      },
    ];
    
    for (const config of configs) {
      await client.query(`
        INSERT INTO tax_configs (
          "taxType", "rateType", "effectiveFrom", "effectiveTo",
          configuration, "paymentDeadline", "isActive", notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [
        config.taxType,
        config.rateType,
        config.effectiveFrom,
        config.effectiveTo || null,
        JSON.stringify(config.configuration),
        config.paymentDeadline,
        true,
        config.notes,
      ]);
      
      console.log(`✅ ${config.taxType}: ${config.notes}`);
    }
    
    // 4. Verify the data
    console.log('\n🔍 Verifying tax configurations...');
    const verifyResult = await client.query(`
      SELECT "taxType", "rateType", "effectiveFrom", "isActive"
      FROM tax_configs
      ORDER BY "effectiveFrom" DESC
    `);
    
    console.log('\n' + '='.repeat(80));
    console.log('🎉 TAX CONFIGURATIONS SUCCESSFULLY CREATED!');
    console.log('='.repeat(80));
    console.log(`📊 Total Configurations: ${verifyResult.rows.length}`);
    console.log(`\n🇰🇪 Kenya 2025 Tax Setup:`);
    verifyResult.rows.forEach(row => {
      console.log(`   ✅ ${row.taxType} (${row.rateType}) - Effective from ${row.effectiveFrom.toISOString().split('T')[0]}`);
    });
    console.log('\n✨ The payroll/calculate endpoint will now use these tax rates!');
    
  } catch (error) {
    console.error('❌ Error setting up tax configs:', error.message);
    console.error(error);
  } finally {
    await client.end();
    console.log('\n🔗 Database connection closed');
  }
}

setupTaxConfigs();