import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { cleanupTestData, generateTestEmail, generateTestPhone } from './test-utils';
import { DataSource } from 'typeorm';

/**
 * Authentication E2E Tests
 *
 * Tests user registration and login flows including:
 * - Successful registration
 * - Duplicate email handling
 * - Successful login
 * - Invalid credentials handling
 */
describe('Auth E2E', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Clean up DB before starting
    const dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);
  });

  afterAll(async () => {
    if (app) {
      try {
        const dataSource = app.get(DataSource);
        await cleanupTestData(dataSource);
      } catch (error) {
        console.error('Cleanup failed:', error);
      }
      await app.close();
    }
  });

  describe('Registration', () => {
    let uniqueEmail: string;

    beforeEach(() => {
      uniqueEmail = generateTestEmail('auth.test');
    });

    it('should register a new user successfully', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .post('/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Password123!',
          firstName: 'Auth',
          lastName: 'TestUser',
          businessName: 'Auth Test Corp',
          phone: generateTestPhone(),
        })
        .expect(201);

      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(uniqueEmail);
    });

    it('should reject registration with duplicate email', async () => {
      // Create user first
      await request(app.getHttpAdapter().getInstance())
        .post('/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Password123!',
          firstName: 'Original',
          lastName: 'User',
          businessName: 'Original Corp',
          phone: generateTestPhone(),
        });

      // Try to register duplicate
      await request(app.getHttpAdapter().getInstance())
        .post('/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Password123!',
          firstName: 'Duplicate',
          lastName: 'User',
          businessName: 'Duplicate Corp',
          phone: generateTestPhone(),
        })
        .expect(409); // Conflict
    });

    it('should reject registration with missing required fields', async () => {
      await request(app.getHttpAdapter().getInstance())
        .post('/auth/register')
        .send({
          email: 'incomplete@paykey.com',
          // Missing password, firstName, lastName
        })
        .expect(400);
    });
  });

  describe('Login', () => {
    // Use unique email with timestamp to avoid conflicts
    const loginEmail = generateTestEmail('login.stable');
    const loginPassword = 'StablePassword123!';

    beforeAll(async () => {
      // Register user for login tests
      const registerRes = await request(app.getHttpAdapter().getInstance())
        .post('/auth/register')
        .send({
          email: loginEmail,
          password: loginPassword,
          firstName: 'Login',
          lastName: 'Tester',
          businessName: 'Login Test Corp',
          phone: generateTestPhone(),
        });

      // If registration fails (409 conflict), user already exists which is OK
      if (registerRes.status !== 201 && registerRes.status !== 409) {
        console.warn(
          `Registration returned ${registerRes.status}: ${JSON.stringify(registerRes.body)}`,
        );
      }
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app.getHttpAdapter().getInstance()).post('/auth/login').send({
        email: loginEmail,
        password: loginPassword,
      });

      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(loginEmail);
    });

    it('should reject login with wrong password', async () => {
      await request(app.getHttpAdapter().getInstance())
        .post('/auth/login')
        .send({
          email: loginEmail,
          password: 'WrongPassword123!',
        })
        .expect(401);
    });

    it('should reject login with non-existent email', async () => {
      await request(app.getHttpAdapter().getInstance())
        .post('/auth/login')
        .send({
          email: 'nonexistent@paykey.com',
          password: 'Password123!',
        })
        .expect(401);
    });
  });
});

