// test/test-utils.ts
/**
 * Test utilities for E2E tests
 */

import { DataSource } from 'typeorm';
import { INestApplication } from '@nestjs/common';
import { randomBytes } from 'crypto';

/**
 * Generate a cryptographically unique ID for test data
 */
function generateUniqueId(): string {
  return randomBytes(8).toString('hex');
}

/**
 * Generate a unique email for test users using crypto random
 */
export function generateTestEmail(prefix: string): string {
  const uniqueId = generateUniqueId();
  const timestamp = Date.now();
  return `${prefix}.${timestamp}.${uniqueId}@paykey.com`;
}

/**
 * Generate a unique phone number for test users
 */
export function generateTestPhone(): string {
  // Use crypto random for better uniqueness
  const randomPart = parseInt(randomBytes(4).toString('hex'), 16) % 100000000;
  return `+254${String(randomPart).padStart(9, '0').slice(0, 9)}`;
}

/**
 * Clean up test data using multiple strategies:
 * 1. Try TRUNCATE CASCADE
 * 2. Fall back to individual DELETE statements
 * 3. Last resort: synchronize(true)
 */
export async function cleanupTestData(dataSource: DataSource): Promise<void> {
  if (!dataSource.isInitialized) {
    console.warn('DataSource not initialized, skipping cleanup');
    return;
  }

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

  try {
    // Strategy 1: Try TRUNCATE CASCADE on all tables
    const entities = dataSource.entityMetadatas;
    const tableNames = entities
      .map((entity) => `"${entity.tableName}"`)
      .join(', ');

    if (tableNames.length > 0) {
      await dataSource.query(
        `TRUNCATE TABLE ${tableNames} RESTART IDENTITY CASCADE;`,
      );
      return; // Success!
    }
  } catch (truncateError: any) {
    console.warn(`TRUNCATE failed: ${truncateError.message}`);
  }

  try {
    // Strategy 2: Individual DELETE statements in order
    for (const table of tablesToDelete) {
      try {
        await dataSource.query(`DELETE FROM "${table}"`);
      } catch {
        // Table might not exist, continue
      }
    }
    return; // Success!
  } catch (deleteError: any) {
    console.warn(`DELETE failed: ${deleteError.message}`);
  }

  try {
    // Strategy 3: Nuclear option - drop and recreate all tables
    await dataSource.synchronize(true);
  } catch (syncError: any) {
    console.error(`All cleanup strategies failed: ${syncError.message}`);
    throw syncError;
  }
}

/**
 * Verify database connection and log connection details in CI
 */
export async function verifyDatabaseConnection(dataSource: DataSource): Promise<void> {
  if (!dataSource.isInitialized) {
    throw new Error('DataSource is not initialized');
  }

  try {
    const result = await dataSource.query('SELECT current_user, current_database()');

    // Log connection details in CI for debugging
    if (process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true') {
      console.log('✅ CI Database Connection Verified:', {
        host: (dataSource.options as any).host,
        port: (dataSource.options as any).port,
        username: (dataSource.options as any).username,
        database: (dataSource.options as any).database,
        currentUser: result[0]?.current_user,
        currentDatabase: result[0]?.current_database,
      });
    }
  } catch (error: any) {
    console.error('❌ Database connection verification failed:', error.message);
    throw error;
  }
}

/**
 * Start a database transaction for test isolation
 */
export async function startTestTransaction(dataSource: DataSource) {
  await dataSource.query('START TRANSACTION');
}

/**
 * Rollback database transaction for test cleanup
 */
export async function rollbackTestTransaction(dataSource: DataSource) {
  await dataSource.query('ROLLBACK');
}

/**
 * Create test database connection
 */
export async function createTestDataSource(): Promise<DataSource> {
  // This would typically use the test database configuration
  // For now, we'll rely on the existing TypeORM configuration
  throw new Error('Use existing AppModule configuration for tests');
}

/**
 * Generate unique invite code for testing
 */
export function generateTestInviteCode(): string {
  return `TEST-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
}

/**
 * Create test worker data
 */
export function createTestWorkerData(
  overrides: Partial<{
    name: string;
    phoneNumber: string;
    salaryGross: number;
    email: string;
  }> = {},
) {
  return {
    name: 'Test Worker',
    phoneNumber: generateTestPhone(),
    salaryGross: 50000,
    startDate: '2024-01-01',
    email: generateTestEmail('worker'),
    ...overrides,
  };
}

export function createTestUserData(
  overrides: Partial<{
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    businessName: string;
    phone: string;
  }> = {},
) {
  return {
    email: generateTestEmail('test'),
    password: 'Password123!',
    firstName: 'Test',
    lastName: 'User',
    businessName: 'Test Company',
    phone: generateTestPhone(),
    ...overrides,
  };
}

/**
 * Upgrade a user to PLATINUM tier for testing premium features
 * Use this in E2E tests to test Platinum-only features like geofencing
 */
export async function upgradeUserToPlatinum(
  app: INestApplication,
  userId: string,
): Promise<void> {
  const dataSource = app.get(DataSource);

  await dataSource.query(
    `UPDATE "users" SET "tier" = 'PLATINUM' WHERE "id" = $1`,
    [userId],
  );
}

/**
 * Get user ID from JWT token (for testing)
 */
export function extractUserIdFromToken(token: string): string | null {
  try {
    const payload = JSON.parse(
      Buffer.from(token.split('.')[1], 'base64').toString(),
    );
    return payload.userId || payload.sub || null;
  } catch {
    return null;
  }
}
