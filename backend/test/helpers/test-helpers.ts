/**
 * Test Helpers for E2E Tests
 *
 * Centralized helper class providing type-safe utilities for common
 * test operations with retry logic and proper error handling.
 */

import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import {
  generateTestEmail,
  generateTestPhone,
  createTestWorkerData,
} from '../test-utils';
import {
  LoginResponse,
  WorkerResponse,
  PayPeriodResponse,
} from '../types/test-types';

export interface TestUserOptions {
  emailPrefix?: string;
  password?: string;
  firstName?: string;
  lastName?: string;
  businessName?: string;
}

export interface TestUserResult {
  token: string;
  userId: string;
  email: string;
  password: string;
}

export interface TestWorkerOptions {
  name?: string;
  phoneNumber?: string;
  email?: string;
  salaryGross?: number;
  startDate?: string;
  jobTitle?: string;
  paymentMethod?: 'MPESA' | 'BANK' | 'CASH';
  mpesaNumber?: string;
}

/**
 * TestHelpers - Centralized utilities for E2E tests
 *
 * Usage:
 * ```typescript
 * const helpers = new TestHelpers(app);
 * const { token, email } = await helpers.createTestUser();
 * const worker = await helpers.createTestWorker(token);
 * ```
 */
export class TestHelpers {
  constructor(private app: INestApplication) {}

  /**
   * Create a test user with registration and login, includes retry logic
   * for handling race conditions in parallel test execution.
   */
  async createTestUser(options: TestUserOptions = {}): Promise<TestUserResult> {
    const email = generateTestEmail(options.emailPrefix || 'test.user');
    const password = options.password || 'Password123!';
    const phone = generateTestPhone();

    // Attempt registration
    const registerRes = await request(this.app.getHttpServer())
      .post('/auth/register')
      .send({
        email,
        password,
        firstName: options.firstName || 'Test',
        lastName: options.lastName || 'User',
        businessName: options.businessName || 'Test Company',
        phone,
      });

    // Handle registration result
    if (
      registerRes.status === 409 ||
      (registerRes.status === 400 &&
        typeof registerRes.body?.message === 'string' &&
        registerRes.body.message.includes('already exists'))
    ) {
      // User exists, proceed to login
      console.log(`User ${email} already exists, proceeding to login`);
    } else if (registerRes.status !== 201) {
      throw new Error(
        `Registration failed with status ${registerRes.status}: ${JSON.stringify(registerRes.body)}`,
      );
    }

    // Login to get auth token
    const loginRes = await request(this.app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });

    if (loginRes.status !== 200 && loginRes.status !== 201) {
      throw new Error(
        `Login failed with status ${loginRes.status}: ${JSON.stringify(loginRes.body)}`,
      );
    }

    const loginResponse = loginRes.body as LoginResponse;

    if (!loginResponse.access_token) {
      throw new Error('Failed to obtain auth token from login response');
    }

    return {
      token: loginResponse.access_token,
      userId: loginResponse.user.id,
      email,
      password,
    };
  }

  /**
   * Create a test worker with unique data
   */
  async createTestWorker(
    authToken: string,
    options: TestWorkerOptions = {},
  ): Promise<WorkerResponse> {
    const workerData = createTestWorkerData({
      name: options.name,
      phoneNumber: options.phoneNumber,
      salaryGross: options.salaryGross,
      email: options.email,
    });

    // Merge additional options
    const fullWorkerData = {
      ...workerData,
      jobTitle: options.jobTitle || 'Test Worker',
      paymentMethod: options.paymentMethod,
      mpesaNumber: options.mpesaNumber,
    };

    const res = await request(this.app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${authToken}`)
      .send(fullWorkerData);

    if (res.status !== 201) {
      throw new Error(
        `Worker creation failed with status ${res.status}: ${JSON.stringify(res.body)}`,
      );
    }

    return res.body as WorkerResponse;
  }

  /**
   * Generate pay periods for a given year
   */
  async generatePayPeriods(
    authToken: string,
    year?: number,
  ): Promise<PayPeriodResponse[]> {
    const targetYear = year || new Date().getFullYear();

    const res = await request(this.app.getHttpServer())
      .post('/pay-periods/generate')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        frequency: 'MONTHLY',
        startDate: `${targetYear}-01-01`,
        endDate: `${targetYear}-12-31`,
      });

    if (res.status !== 201) {
      throw new Error(
        `Pay period generation failed with status ${res.status}: ${JSON.stringify(res.body)}`,
      );
    }

    return res.body as PayPeriodResponse[];
  }

  /**
   * Get the HTTP server for direct request usage
   */
  getHttpServer() {
    return this.app.getHttpServer();
  }

  /**
   * Make an authenticated GET request
   */
  async authGet<T>(path: string, authToken: string): Promise<T> {
    const res = await request(this.app.getHttpServer())
      .get(path)
      .set('Authorization', `Bearer ${authToken}`);

    if (res.status >= 400) {
      throw new Error(
        `GET ${path} failed with status ${res.status}: ${JSON.stringify(res.body)}`,
      );
    }

    return res.body as T;
  }

  /**
   * Make an authenticated POST request
   */
  async authPost<T>(
    path: string,
    authToken: string,
    body: Record<string, unknown>,
  ): Promise<T> {
    const res = await request(this.app.getHttpServer())
      .post(path)
      .set('Authorization', `Bearer ${authToken}`)
      .send(body);

    if (res.status >= 400) {
      throw new Error(
        `POST ${path} failed with status ${res.status}: ${JSON.stringify(res.body)}`,
      );
    }

    return res.body as T;
  }
}

/**
 * Factory function for creating TestHelpers instance
 */
export function createTestHelpers(app: INestApplication): TestHelpers {
  return new TestHelpers(app);
}
