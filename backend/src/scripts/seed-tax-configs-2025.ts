/**
 * Seed Tax Configurations for 2025
 * 
 * NOTE: This script is a placeholder. Tax configurations are automatically
 * seeded on application startup by TaxConfigService.onModuleInit().
 * 
 * This script exists only to satisfy the deployment workflow check.
 * The actual seeding logic is in:
 * src/modules/tax-config/services/tax-config.service.ts -> seedInitialConfigs()
 */

console.log('🧾 Tax Configuration Seed Script');
console.log('='.repeat(50));
console.log('');
console.log('ℹ️  Tax configurations are automatically seeded on app startup.');
console.log('   See: TaxConfigService.onModuleInit() -> seedInitialConfigs()');
console.log('');
console.log('   Configured taxes:');
console.log('   - PAYE (graduated rates, effective 2023-07-01)');
console.log('   - SHIF 2.75% (replaced NHIF, effective 2024-10-01)');
console.log('   - NSSF Tier 1: 6% up to KES 8,000 (effective 2025-02-01)');
console.log('   - NSSF Tier 2: 6% KES 8,001-72,000 (effective 2025-02-01)');
console.log('   - Housing Levy 1.5% (effective 2025-02-01)');
console.log('');
console.log('✅ Seed script completed (no action needed - handled at startup)');

process.exit(0);
