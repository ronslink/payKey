/**
 * env-setup.ts - MUST BE LOADED FIRST
 * 
 * This file sets environment variables BEFORE any other code runs.
 * It must be the first file in jest setupFilesAfterEnv to ensure
 * database credentials are set before TypeORM imports.
 */

// Force test environment
process.env.NODE_ENV = 'test';

// Force database credentials - these MUST be set before any DB imports
// This fixes the "role 'root' does not exist" error in CI
process.env.DB_HOST = process.env.DB_HOST || 'localhost';
process.env.DB_PORT = process.env.DB_PORT || '5432';
process.env.DB_USER = process.env.DB_USER || 'postgres';
process.env.DB_USERNAME = process.env.DB_USERNAME || 'postgres';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || 'password';
process.env.DB_NAME = process.env.DB_NAME || 'paykey_test';
process.env.DB_DATABASE = process.env.DB_NAME || 'paykey_test';

// Force JWT secret for tests
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_key_for_ci_cd_pipeline_12345';

// Detect CI environment
const isCI = !!(process.env.CI || process.env.GITHUB_ACTIONS);

console.log('🔧 Environment Setup:');
console.log(`   CI: ${isCI ? 'Yes' : 'No'}`);
console.log(`   DB: ${process.env.DB_USER}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`);
