import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { TaxConfigService } from '../src/modules/tax-config/services/tax-config.service';

async function seedTaxConfigs() {
  console.log('📊 Seeding tax_configs with 2025 Kenya tax data...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const taxConfigService = app.get(TaxConfigService);

  try {
    await taxConfigService.seedInitialConfigs();
    console.log('✅ Tax configurations seeded successfully!');

    // Verify
    const configs = await taxConfigService.getAllActiveTaxConfigs(new Date('2025-01-01'));
    console.log(`\n🔍 Verified ${configs.length} active tax configurations for 2025:`);
    configs.forEach(config => {
      console.log(`   ✅ ${config.taxType} (${config.rateType})`);
    });

  } catch (error) {
    console.error('❌ Error seeding tax configs:', error.message);
  } finally {
    await app.close();
  }
}

seedTaxConfigs();
