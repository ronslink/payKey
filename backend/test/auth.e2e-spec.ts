import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

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
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Registration', () => {
    const uniqueEmail = `auth.test.${Date.now()}@paykey.com`;

    it('should register a new user successfully', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Password123!',
          firstName: 'Auth',
          lastName: 'TestUser',
          businessName: 'Auth Test Corp',
          phone: '+254700000099',
        })
        .expect(201);

      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(uniqueEmail);
    });

    it('should reject registration with duplicate email', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Password123!',
          firstName: 'Duplicate',
          lastName: 'User',
          businessName: 'Duplicate Corp',
          phone: '+254700000098',
        })
        .expect(409); // Conflict
    });

    it('should reject registration with missing required fields', async () => {
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'incomplete@paykey.com',
          // Missing password, firstName, lastName
        })
        .expect(400);
    });
  });

  describe('Login', () => {
    // Use fixed credentials that are set before any test runs
    const loginEmail = 'login.stable@paykey.com';
    const loginPassword = 'StablePassword123!';

    beforeAll(async () => {
      // Register user for login tests - use try/catch for idempotency
      try {
        await request(app.getHttpServer()).post('/auth/register').send({
          email: loginEmail,
          password: loginPassword,
          firstName: 'Login',
          lastName: 'Tester',
          businessName: 'Login Test Corp',
          phone: '+254700000097',
        });
      } catch (e) {
        // User might already exist from previous test run
      }
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app.getHttpServer()).post('/auth/login').send({
        email: loginEmail,
        password: loginPassword,
      });

      expect(res.body).toHaveProperty('access_token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(loginEmail);
    });

    it('should reject login with wrong password', async () => {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: loginEmail,
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
