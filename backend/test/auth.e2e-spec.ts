import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { DataSource } from 'typeorm';
import {
  cleanupTestData,
  generateTestEmail,
  generateTestPhone,
} from './test-utils';

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
  let helpers: TestHelpers;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Create test helpers
    helpers = createTestHelpers(app);

    // Clean up DB before starting
    const dataSource = app.get(DataSource);
    await cleanupTestData(dataSource);
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Registration', () => {
    it('should register a new user successfully', async () => {
      const email = generateTestEmail('auth.new');
      const phone = generateTestPhone();

      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email,
          password: 'Password123!',
          firstName: 'Auth',
          lastName: 'New',
          businessName: 'Auth New Corp',
          phone,
        })
        .expect(201);

      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(email);
      // Now that DTO has phone, we might expect it in response if User entity returns it
    });

    it('should reject registration with duplicate email', async () => {
      // 1. Create a user first using Helper (handles setup robustly)
      const { email, password } = await helpers.createTestUser({
        emailPrefix: 'auth.dup',
      });

      // 2. Try to register with same email
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email,
          password: 'AnotherPassword123!',
          firstName: 'Duplicate',
          lastName: 'Attempt',
          businessName: 'Copy Corp',
          phone: generateTestPhone(), // Different phone
        })
        .expect(409);
    });

    it('should reject registration with missing required fields', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'incomplete@paykey.com',
          // Missing password
        })
        .expect(400);
    });
  });

  describe('Login', () => {
    let testUser: { email: string; password: string };

    beforeAll(async () => {
      // Create a stable user for login tests
      testUser = await helpers.createTestUser({
        emailPrefix: 'auth.login',
      });
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app.getHttpServer()).post('/auth/login').send({
        email: testUser.email,
        password: testUser.password,
      });

      expect(res.status).toBeOneOf([200, 201]);
      expect(res.body).toHaveProperty('access_token');
      expect(res.body.user.email).toBe(testUser.email);
    });

    it('should reject login with wrong password', async () => {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: 'WrongPassword123!',
        })
        .expect(401);
    });

    it('should reject login with non-existent email', async () => {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'nonexistent@paykey.com',
          password: 'Password123!',
        })
        .expect(401);
    });
  });
});
