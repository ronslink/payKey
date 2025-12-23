// test/test-utils.ts
/**
 * Test utilities for E2E tests
 */

import { DataSource } from 'typeorm';

/**
 * Generate a unique email for test users
 */
export function generateTestEmail(testName: string): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000);
  return `${testName}.${timestamp}.${random}@paykey.com`;
}

/**
 * Generate a unique phone number for test users
 */
export function generateTestPhone(): string {
  const timestamp = Date.now().toString().slice(-6);
  const random = Math.floor(Math.random() * 1000)
    .toString()
    .padStart(3, '0');
  return `+25471${timestamp.slice(-3)}${random}`;
}

/**
 * Clean up test data by truncating specific tables
 */
export async function cleanupTestData(dataSource: DataSource): Promise<void> {
  const entities = [
    'tax_submissions',
    'payroll_records',
    'pay_periods',
    'workers',
    'users',
    'tax_configs',
    'tax_tables',
    'countries',
  ];

  for (const entity of entities) {
    try {
      await dataSource.query(
        `DELETE FROM "${entity}" WHERE email LIKE '%@paykey.com' OR email LIKE '%@example.com'`,
      );
    } catch (error) {
      // Table might not exist or be empty, ignore
      console.log(`Cleanup warning for ${entity}:`, error.message);
    }
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
  app: { get: (token: any) => any },
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

