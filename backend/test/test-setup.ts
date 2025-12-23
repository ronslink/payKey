// test/test-setup.ts
/**
 * Global test setup for E2E tests
 */

import { cleanupTestData } from './test-utils';

const testDataSource: any = null;

/**
 * Global setup - runs once before all tests
 */
beforeAll(async () => {
  // Set up test environment variables
  process.env.NODE_ENV = 'test';
  process.env.DB_DATABASE = 'paykey_test';

  console.log('🚀 Starting E2E test suite...');
});

/**
 * Global teardown - runs once after all tests
 */
afterAll(async () => {
  console.log('🧹 Cleaning up E2E test suite...');

  // Clean up any remaining test data
  if (testDataSource) {
    try {
      await cleanupTestData(testDataSource);
    } catch (error) {
      console.warn('⚠️ Error during cleanup:', error.message);
    }
  }

  // Close database connections
  if (testDataSource && testDataSource.isInitialized) {
    await testDataSource.destroy();
  }
});

/**
 * Setup before each test
 */
beforeEach(async () => {
  // Reset any global state if needed
});

/**
 * Cleanup after each test
 */
afterEach(async () => {
  // Clean up test data after each test
  // This will help prevent data pollution between tests
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
