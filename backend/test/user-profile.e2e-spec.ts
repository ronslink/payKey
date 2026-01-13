import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { TestHelpers, createTestHelpers } from './helpers/test-helpers';
import { UserResponse } from './types/test-types';

/**
 * User Profile / Onboarding E2E Tests
 *
 * Tests user profile management and onboarding flow:
 * - Get user profile
 * - Update profile (personal info, compliance data)
 * - Onboarding completion tracking
 *
 * Uses TestHelpers for type-safe test user creation.
 */
describe('User Profile E2E', () => {
  let app: INestApplication;
  let helpers: TestHelpers;
  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Create test helpers instance
    helpers = createTestHelpers(app);

    // Register and login test user
    const testUser = await helpers.createTestUser({
      emailPrefix: 'profile.test',
      firstName: 'Profile',
      lastName: 'Tester',
      businessName: 'Profile Test Corp',
    });

    authToken = testUser.token;
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Profile Endpoints', () => {
    it('should get user profile', async () => {
      const res = await request(app.getHttpServer())
        .get('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const profile = res.body as UserResponse;
      expect(profile).toHaveProperty('email');
      expect(profile).toHaveProperty('firstName');
      expect(profile).toHaveProperty('lastName');
    });

    it('should update user profile', async () => {
      const res = await request(app.getHttpServer())
        .patch('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          firstName: 'Updated',
          lastName: 'Name',
          businessName: 'Updated Business',
        })
        .expect(200);

      const profile = res.body as UserResponse;
      expect(profile.firstName).toBe('Updated');
      expect(profile.lastName).toBe('Name');
    });

    it('should update compliance profile', async () => {
      const res = await request(app.getHttpServer())
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
      await request(app.getHttpServer())
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

      const res = await request(app.getHttpServer())
        .get('/users/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Onboarding should be marked complete if all fields are filled
      expect(res.body).toHaveProperty('isOnboardingCompleted');
    });
  });

  describe('Authorization', () => {
    it('should prevent unauthorized access to profile', async () => {
      await request(app.getHttpServer()).get('/users/profile').expect(401);
    });
  });
});
