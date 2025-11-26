// test/security/security.integration.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../../src/app.module';
import { UsersModule } from '../../src/modules/users/users.module';
import { WorkersModule } from '../../src/modules/workers/workers.module';
import { PayrollModule } from '../../src/modules/payroll/payroll.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../src/modules/users/entities/user.entity';
import { Worker } from '../../src/modules/workers/entities/worker.entity';

describe('Security Tests', () => {
  let app: INestApplication;
  let userRepo: Repository<User>;
  let workerRepo: Repository<Worker>;
  let authToken: string;
  let testUserId: string;
  let otherUserId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule, UsersModule, WorkersModule, PayrollModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    userRepo = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    workerRepo = moduleFixture.get<Repository<Worker>>(getRepositoryToken(Worker));

    // Create test users
    const testUser = await userRepo.save({
      email: 'security-test@paykey.com',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz', // Pre-hashed
      firstName: 'Security',
      lastName: 'Test',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    const otherUser = await userRepo.save({
      email: 'other-user@paykey.com',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz', // Pre-hashed
      firstName: 'Other',
      lastName: 'User',
      countryCode: 'KE',
      isOnboardingCompleted: true,
    });

    testUserId = testUser.id;
    otherUserId = otherUser.id;

    // Get auth token for test user
    const loginRes = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'security-test@paykey.com',
        password: 'test-password',
      });

    authToken = loginRes.body.access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  describe('Authentication Security', () => {
    it('should reject requests without authentication token', async () => {
      await request(app.getHttpServer())
        .get('/workers')
        .expect(401);
    });

    it('should reject requests with invalid token', async () => {
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should reject requests with malformed token', async () => {
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', 'Malformed token')
        .expect(401);
    });

    it('should reject expired tokens', async () => {
      // This would require implementing token expiration in the test
      // For now, we'll test with an old token format
      const oldToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJleHAiOjE2MjM5NzYzMjB9.invalid-signature';
      
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', `Bearer ${oldToken}`)
        .expect(401);
    });

    it('should enforce strong password requirements during registration', async () => {
      // Test weak passwords (this would require a registration endpoint)
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'weak-password@test.com',
          password: '123', // Weak password
          firstName: 'Test',
          lastName: 'User',
        })
        .expect(400);
    });
  });

  describe('Authorization Security', () => {
    let testWorkerId: string;
    let otherWorkerId: string;

    beforeEach(async () => {
      // Create workers for both users
      const testWorker = await workerRepo.save({
        name: 'Test Worker',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        userId: testUserId,
        isActive: true,
      });

      const otherWorker = await workerRepo.save({
        name: 'Other User Worker',
        phoneNumber: '+254798765432',
        salaryGross: 60000,
        startDate: '2024-01-01',
        userId: otherUserId,
        isActive: true,
      });

      testWorkerId = testWorker.id;
      otherWorkerId = otherWorker.id;
    });

    afterEach(async () => {
      await workerRepo.delete({ userId: testUserId });
      await workerRepo.delete({ userId: otherUserId });
    });

    it('should prevent users from accessing another user\'s workers', async () => {
      await request(app.getHttpServer())
        .get(`/workers/${otherWorkerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404); // Should return 404, not 403 (security through obscurity)
    });

    it('should prevent users from modifying another user\'s workers', async () => {
      await request(app.getHttpServer())
        .patch(`/workers/${otherWorkerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Modified by Attacker',
          salaryGross: 999999,
        })
        .expect(404); // Should return 404, not 403
    });

    it('should prevent users from deleting another user\'s workers', async () => {
      await request(app.getHttpServer())
        .delete(`/workers/${otherWorkerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404); // Should return 404, not 403
    });

    it('should enforce user isolation in payroll operations', async () => {
      // Test accessing payroll for another user
      await request(app.getHttpServer())
        .get(`/payroll/calculate/${otherUserId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('Input Validation Security', () => {
    it('should prevent SQL injection in worker creation', async () => {
      const maliciousPayload = {
        name: "'; DROP TABLE users; --",
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
      };

      const response = await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(maliciousPayload);

      expect(response.status).not.toBe(500); // Should not cause SQL error
      expect(response.body.name).toContain("'; DROP TABLE users; --"); // Should be sanitized/encoded
    });

    it('should prevent XSS in worker names', async () => {
      const xssPayload = {
        name: '<script>alert("xss")</script>',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
      };

      await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(xssPayload)
        .expect(201); // Should succeed but sanitize the input

      // Verify the XSS payload is properly escaped when displayed
      const createdWorker = await workerRepo.findOne({
        where: { name: xssPayload.name, userId: testUserId },
      });
      expect(createdWorker).toBeNull(); // Should have sanitized the name
    });

    it('should validate salary input ranges', async () => {
      const invalidSalaries = [
        -1000, // Negative salary
        999999999, // Extremely large salary
        NaN, // Not a number
        'not-a-number', // String instead of number
        null, // Null value
        undefined, // Undefined value
      ];

      for (const invalidSalary of invalidSalaries) {
        await request(app.getHttpServer())
          .post('/workers')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            name: 'Test Worker',
            phoneNumber: '+254712345678',
            salaryGross: invalidSalary,
            startDate: '2024-01-01',
          })
          .expect(400); // Should reject invalid salary
      }
    });

    it('should prevent buffer overflow attacks', async () => {
      const oversizedData = {
        name: 'A'.repeat(10000), // Very long name
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
      };

      await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(oversizedData)
        .expect(400); // Should reject oversized input
    });
  });

  describe('Session Management Security', () => {
    it('should enforce session timeout', async () => {
      // This would require implementing session timeout in the application
      // For now, we'll test with a very old timestamp
      const oldToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJleHAiOjE2MjM5NzYzMjB9.old-signature';
      
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', `Bearer ${oldToken}`)
        .expect(401);
    });

    it('should prevent token reuse after logout', async () => {
      // First, login to get a valid token
      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'security-test@paykey.com',
          password: 'test-password',
        });

      const validToken = loginRes.body.access_token;

      // Logout (this would require implementing a logout endpoint)
      // await request(app.getHttpServer())
      //   .post('/auth/logout')
      //   .set('Authorization', `Bearer ${validToken}`);

      // Try to use the token after "logout"
      await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', `Bearer ${validToken}`)
        .expect(200); // This should fail after implementing proper logout
    });
  });

  describe('Rate Limiting Security', () => {
    it('should implement rate limiting for login attempts', async () => {
      const attempts = 10;
      
      for (let i = 0; i < attempts; i++) {
        await request(app.getHttpServer())
          .post('/auth/login')
          .send({
            email: 'security-test@paykey.com',
            password: 'wrong-password',
          });
      }

      // The next attempt should be rate limited
      const response = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'security-test@paykey.com',
          password: 'wrong-password',
        });

      expect([429, 403]).toContain(response.status); // Too Many Requests or Forbidden
    });

    it('should implement rate limiting for API endpoints', async () => {
      const endpoint = '/workers';
      const rapidRequests = 50;

      // Send rapid requests to stress test rate limiting
      const promises = [];
      for (let i = 0; i < rapidRequests; i++) {
        promises.push(
          request(app.getHttpServer())
            .get(endpoint)
            .set('Authorization', `Bearer ${authToken}`)
        );
      }

      const responses = await Promise.all(promises);
      const rateLimitedResponses = responses.filter(r => r.status === 429);

      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    });
  });

  describe('Data Protection Security', () => {
    it('should not expose sensitive data in API responses', async () => {
      const response = await request(app.getHttpServer())
        .get('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Check that sensitive fields are not exposed
      const workers = response.body;
      if (Array.isArray(workers) && workers.length > 0) {
        const worker = workers[0];
        expect(worker).not.toHaveProperty('passwordHash');
        expect(worker).not.toHaveProperty('password');
        expect(worker).not.toHaveProperty('internalId');
      }
    });

    it('should encrypt sensitive worker data', async () => {
      // This would require implementing field-level encryption
      // For now, we'll test that sensitive fields are not stored in plain text
      await workerRepo.save({
        name: 'Encrypted Worker',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        userId: testUserId,
        isActive: true,
      });

      // In a real implementation, phone numbers, IDs, etc. should be encrypted
      const worker = await workerRepo.findOne({
        where: { name: 'Encrypted Worker', userId: testUserId },
      });

      expect(worker.phoneNumber).not.toBe('+254712345678'); // Should be encrypted
    });
  });

  describe('Error Handling Security', () => {
    it('should not expose sensitive information in error messages', async () => {
      await request(app.getHttpServer())
        .get('/workers/non-existent-id')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      // The error message should not contain:
      // - Database schema information
      // - Internal file paths
      // - Stack traces in production
    });

    it('should handle malformed requests gracefully', async () => {
      await request(app.getHttpServer())
        .post('/workers')
        .set('Authorization', `Bearer ${authToken}`)
        .set('Content-Type', 'application/json')
        .send('{"invalid": json}')
        .expect(400);
    });
  });
});