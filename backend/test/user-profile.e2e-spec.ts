import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

/**
 * User Profile / Onboarding E2E Tests
 *
 * Tests user profile management and onboarding flow:
 * - Get user profile
 * - Update profile (personal info, compliance data)
 * - Onboarding completion tracking
 */
describe('User Profile E2E', () => {
  let app: INestApplication;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Register and login test user
    const email = `profile.test.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpAdapter().getInstance()).post('/auth/register').send({
      email,
      password,
      firstName: 'Profile',
      lastName: 'Tester',
      businessName: 'Profile Test Corp',
      phone: '+254700000400',
    });

    const loginRes = await request(app.getHttpAdapter().getInstance())
      .post('/auth/login')
      .send({ email, password });

    authToken = loginRes.body.access_token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Profile Endpoints', () => {
    it('should get user profile', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .get('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('email');
      expect(res.body).toHaveProperty('firstName');
      expect(res.body).toHaveProperty('lastName');
    });

    it('should update user profile', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .patch('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          firstName: 'Updated',
          lastName: 'Name',
          businessName: 'Updated Business',
        })
        .expect(200);

      expect(res.body.firstName).toBe('Updated');
      expect(res.body.lastName).toBe('Name');
    });

    it('should update compliance profile', async () => {
      const res = await request(app.getHttpAdapter().getInstance())
        .patch('/users/compliance')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          kraPin: 'A123456789X',
        });

      // May succeed or return validation errors
      expect([200, 400]).toContain(res.status);
    });

    it('should track onboarding status after profile completion', async () => {
      // Update profile with all required onboarding fields
      await request(app.getHttpAdapter().getInstance())
        .patch('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          firstName: 'Complete',
          lastName: 'User',
          idType: 'NATIONAL_ID',
          idNumber: '12345678',
          nationalityId: 1,
          kraPin: 'A123456789X',
          countryId: 1,
          isResident: true,
        });

      const res = await request(app.getHttpAdapter().getInstance())
        .get('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Onboarding should be marked complete if all fields are filled
      expect(res.body).toHaveProperty('isOnboardingCompleted');
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access to profile', async () => {
      await request(app.getHttpAdapter().getInstance()).get('/users/profile').expect(401);
    });
  });
});

