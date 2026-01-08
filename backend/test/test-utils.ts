// test/test-utils.ts
/**
 * Test utilities for E2E tests
 */

import { DataSource } from 'typeorm';
import { INestApplication } from '@nestjs/common';

/**
 * Generate a unique email for test users
 */
export function generateTestEmail(prefix: string): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `${prefix}.${timestamp}.${random}@paykey.com`;
}

/**
 * Generate a unique phone number for test users
 */
export function generateTestPhone(): string {
  // Use a fixed prefix valid for Kenya but randomize the rest clearly
  const random = Math.floor(Math.random() * 100000000);
  return `+254${String(random).padStart(9, '0')}`;
}

/**
 * Clean up test data by truncating all tables
 * Falls back to synchronize(true) if truncate fails
 */
export async function cleanupTestData(dataSource: DataSource): Promise<void> {
  if (!dataSource.isInitialized) {
    return;
  }

  try {
    const entities = dataSource.entityMetadatas;
    const tableNames = entities
      .map((entity) => `"${entity.tableName}"`)
      .join(', ');

    if (tableNames.length > 0) {
      await dataSource.query(
        `TRUNCATE TABLE ${tableNames} RESTART IDENTITY CASCADE;`,
      );
    }
  } catch (error: any) {
    console.warn(`TRUNCATE failed, falling back to synchronize: ${error.message}`);
    try {
      // Drop and recreate all tables - nuclear option
      await dataSource.synchronize(true);
    } catch (syncError: any) {
      console.error(`Synchronize also failed: ${syncError.message}`);
      throw syncError;
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
