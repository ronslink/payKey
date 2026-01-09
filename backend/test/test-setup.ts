// test/test-setup.ts
/**
 * Global test setup for E2E tests
 */

import { DataSource } from 'typeorm';

// Set up test environment variables before any tests run
process.env.NODE_ENV = 'test';
process.env.DB_HOST = process.env.DB_HOST || 'localhost';
process.env.DB_PORT = process.env.DB_PORT || '5432';
process.env.DB_USER = process.env.DB_USER || 'paykey';
process.env.DB_USERNAME = process.env.DB_USERNAME || 'paykey';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || 'password';
process.env.DB_NAME = process.env.DB_NAME || 'paykey_test';
process.env.DB_DATABASE = 'paykey_test';

// Validate required environment variables
const requiredEnvVars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
const missingEnvVars = requiredEnvVars.filter((envVar) => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.warn(
    `⚠️  Warning: Missing environment variables: ${missingEnvVars.join(', ')}`,
  );
  console.warn('Using default values for testing.');
}

console.log('🚀 Starting E2E test suite...');
console.log(
  `📊 Database: ${process.env.DB_USER}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`,
);

/**
 * Global database cleanup before ALL tests
 * This runs once at the very start of the test suite
 */
let globalDataSource: DataSource | null = null;

beforeAll(async () => {
  console.log('🧹 Running global database cleanup...');

  try {
    globalDataSource = new DataSource({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      username: process.env.DB_USER || process.env.DB_USERNAME || 'paykey',
      password: process.env.DB_PASSWORD || 'password',
      database: process.env.DB_NAME || 'paykey_test',
      synchronize: false,
      logging: false,
    });

    await globalDataSource.initialize();

    // Tables to delete in order (CHILDREN FIRST, then PARENTS)
    // This respects foreign key constraints
    const tablesToDelete = [
      // Payroll-related (deepest children first)
      'payroll_records',        // References: pay_periods, workers
      'tax_submissions',        // References: pay_periods
      'tax_payments',           // References: pay_periods
      'pay_periods',            // References: users

      // Worker-related (children before workers)
      'time_entries',           // References: workers
      'leave_requests',         // References: workers
      'terminations',           // References: workers
      'transactions',           // References: workers
      'workers',                // References: users

      // Subscription-related
      'subscription_payments',  // References: subscriptions
      'subscriptions',          // References: users

      // Other tables
      'account_mappings',       // References: users
      'accounting_exports',     // References: users
      'activities',             // References: users
      'exports',                // References: users
      'holidays',               // No FK to users
      'deletion_requests',      // References: users
      'properties',             // References: users

      // Users table LAST (parent of many tables)
      'users',
    ];

    for (const table of tablesToDelete) {
      try {
        await globalDataSource.query(`DELETE FROM "${table}"`);
      } catch {
        // Table might not exist, continue
      }
    }

    console.log('✅ Global database cleanup complete');
  } catch (error: any) {
    console.warn(`⚠️ Global cleanup warning: ${error.message}`);
    // Don't fail the test suite if cleanup fails - individual tests will handle their own cleanup
  }
});

afterAll(async () => {
  if (globalDataSource && globalDataSource.isInitialized) {
    await globalDataSource.destroy();
    console.log('🔌 Global database connection closed');
  }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

/**
 * Custom matchers for common test patterns
 */
expect.extend({
  toBeValidEmail(received: string) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const pass = emailRegex.test(received);

    if (pass) {
      return {
        message: () => `expected ${received} not to be a valid email`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be a valid email`,
        pass: false,
      };
    }
  },

  toBeValidPhone(received: string) {
    const phoneRegex = /^\+254\d{9}$/;
    const pass = phoneRegex.test(received);

    if (pass) {
      return {
        message: () => `expected ${received} not to be a valid phone number`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be a valid phone number`,
        pass: false,
      };
    }
  },

  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;

    if (pass) {
      return {
        message: () =>
          `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () =>
          `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
});

// Export empty object to make this a valid module
export { };
