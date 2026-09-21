import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import {
  cleanupTestData,
  extractUserIdFromToken,
  upgradeUserToPlatinum,
} from './test-utils';
import { DataSource } from 'typeorm';

/**
 * Time tracking end to end: who may clock in, how geofencing behaves on the
 * employee's own device, how employer-entered hours reach payroll, and how the
 * payroll decision is recorded.
 */
describe('Time tracking (e2e)', () => {
  let app: INestApplication;

  let employerToken: string;
  let workerId: string;
  let employeeToken: string;
  let geofencedPropertyId: string;

  // Property coordinates (Nairobi CBD) with a 100m geofence.
  const propertyLat = -1.286389;
  const propertyLng = 36.817223;
  const locationWithin = { lat: -1.2864, lng: 36.8173 };
  const locationOutside = { lat: -1.295, lng: 36.82 };

  const workerPhone = '+254712345678';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    await cleanupTestData(app.get(DataSource));

    const email = `time.tracking.${Date.now()}@paykey.com`;
    const password = 'Password123!';

    await request(app.getHttpServer()).post('/auth/register').send({
      email,
      password,
      firstName: 'Time',
      lastName: 'Tester',
      businessName: 'Time Tracking Ltd',
      phone: '+254700000020',
    });

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });

    employerToken = login.body.access_token;
    expect(employerToken).toBeDefined();

    // Time tracking and geofencing are PLATINUM features.
    const userId = extractUserIdFromToken(employerToken);
    expect(userId).toBeTruthy();
    await upgradeUserToPlatinum(app, userId as string);

    const property = await request(app.getHttpServer())
      .post('/properties')
      .set('Authorization', `Bearer ${employerToken}`)
      .send({
        name: 'Geofenced Office',
        address: 'Nairobi CBD',
        latitude: propertyLat,
        longitude: propertyLng,
        geofenceRadius: 100,
        what3words: 'filled.count.soap',
      });

    expect(property.status).toBe(201);
    // The pin must survive the round trip: it is what the geofence measures from.
    expect(Number(property.body.latitude)).toBeCloseTo(propertyLat, 5);
    expect(Number(property.body.longitude)).toBeCloseTo(propertyLng, 5);
    expect(property.body.what3words).toBe('filled.count.soap');
    geofencedPropertyId = property.body.id;

    const worker = await request(app.getHttpServer())
      .post('/workers')
      .set('Authorization', `Bearer ${employerToken}`)
      .send({
        name: 'Geofence Worker',
        phoneNumber: workerPhone,
        employmentType: 'HOURLY',
        hourlyRate: 500,
        salaryGross: 0,
        startDate: '2024-01-01',
        paymentMethod: 'MPESA',
        propertyId: property.body.id,
      });

    expect(worker.status).toBe(201);
    workerId = worker.body.id;

    // Give the employee their own login: attendance must come from their device.
    const invite = await request(app.getHttpServer())
      .post(`/employee-portal/invite/${workerId}`)
      .set('Authorization', `Bearer ${employerToken}`)
      .send({});

    expect(invite.status).toBe(201);
    const inviteCode = invite.body.inviteCode;
    expect(inviteCode).toBeDefined();

    const claim = await request(app.getHttpServer())
      .post('/employee-portal/claim-account')
      .send({ phoneNumber: workerPhone, inviteCode, pin: '1234' });

    expect(claim.status).toBe(201);
    employeeToken = claim.body.accessToken;
    expect(employeeToken).toBeDefined();

    // Claiming must consume the invite. Clearing it with `undefined` left the
    // code and its expiry on the worker (TypeORM skips undefined), so the
    // employer kept seeing an invite pending for an account that already exists.
    const claimedWorker = await request(app.getHttpServer())
      .get(`/workers/${workerId}`)
      .set('Authorization', `Bearer ${employerToken}`);

    expect(claimedWorker.status).toBe(200);
    expect(claimedWorker.body.inviteCode ?? null).toBeNull();
    expect(claimedWorker.body.inviteCodeExpiry ?? null).toBeNull();
    expect(claimedWorker.body.linkedUserId).toBeTruthy();
  }, 60000);

  afterAll(async () => {
    if (app) {
      try {
        await cleanupTestData(app.get(DataSource));
      } catch (error) {
        console.error('Cleanup failed:', error);
      }
      await app.close();
    }
  });

  describe('who may clock in', () => {
    it('refuses an employer clocking a worker in', async () => {
      const res = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employerToken}`)
        .send({ lat: locationWithin.lat, lng: locationWithin.lng });

      expect(res.status).toBe(403);
      expect(String(res.body.message)).toMatch(
        /employee can clock themselves/i,
      );
    });

    it('refuses an employer clocking a worker out', async () => {
      const res = await request(app.getHttpServer())
        .post(`/time-tracking/clock-out/${workerId}`)
        .set('Authorization', `Bearer ${employerToken}`)
        .send({});

      expect(res.status).toBe(403);
    });

    it('refuses an employee recording a manual entry', async () => {
      const res = await request(app.getHttpServer())
        .post('/time-tracking/entries')
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({
          workerId,
          clockIn: new Date(Date.now() - 3600_000).toISOString(),
          clockOut: new Date().toISOString(),
        });

      expect(res.status).toBe(403);
    });

    it('lets the employee clock themselves in and out inside the geofence', async () => {
      const clockIn = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({ lat: locationWithin.lat, lng: locationWithin.lng });

      expect(clockIn.status).toBe(201);
      // Observed on the employee's own device, so it counts without a decision.
      expect(clockIn.body.source).toBe('CLOCK');
      expect(clockIn.body.payrollDecision).toBe('INCLUDED');

      const duplicate = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({ lat: locationWithin.lat, lng: locationWithin.lng });

      expect(duplicate.status).toBe(400);
      expect(String(duplicate.body.message)).toMatch(/already clocked in/i);

      const clockOut = await request(app.getHttpServer())
        .post(`/time-tracking/clock-out/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({ lat: locationWithin.lat, lng: locationWithin.lng });

      expect(clockOut.status).toBe(201);
      expect(clockOut.body.status).toBe('COMPLETED');
    });

    it('requires a location for a geofenced property', async () => {
      const res = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(String(res.body.message)).toMatch(/location is required/i);
    });

    it('rejects a clock-in outside the geofence', async () => {
      const res = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({ lat: locationOutside.lat, lng: locationOutside.lng });

      expect(res.status).toBe(400);
      expect(String(res.body.message)).toMatch(/Clock-in rejected/i);
    });

    it('accepts a clock-in at a site with no pin, without a location', async () => {
      // A site with no coordinates cannot be geofenced. That is the intended
      // remote/field path, so the API must not demand a location for it.
      const site = await request(app.getHttpServer())
        .post('/properties')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          name: 'Demo Field Site',
          address: 'No fixed site',
          geofenceRadius: 100,
        });

      expect(site.status).toBe(201);
      expect(site.body.latitude).toBeNull();

      const clockIn = await request(app.getHttpServer())
        .post(`/time-tracking/clock-in/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({ propertyId: site.body.id });

      expect(clockIn.status).toBe(201);
      expect(clockIn.body.propertyId).toBe(site.body.id);

      const clockOut = await request(app.getHttpServer())
        .post(`/time-tracking/clock-out/${workerId}`)
        .set('Authorization', `Bearer ${employeeToken}`)
        .send({});

      expect(clockOut.status).toBe(201);
    });

    it('reports the site the worker is assigned to, which the app pre-selects', async () => {
      const mine = await request(app.getHttpServer())
        .get('/employee-portal/my-property')
        .set('Authorization', `Bearer ${employeeToken}`);

      expect(mine.status).toBe(200);
      expect(mine.body.id).toBe(geofencedPropertyId);
      expect(Number(mine.body.latitude)).toBeCloseTo(propertyLat, 5);
    });
  });

  describe('employer-entered hours reach payroll as a decision', () => {
    let enteredEntryId: string;

    it('records time and starts it as PENDING', async () => {
      const clockIn = new Date(Date.now() - 3 * 3600_000);
      const clockOut = new Date(Date.now() - 3600_000);

      const res = await request(app.getHttpServer())
        .post('/time-tracking/entries')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          workerId,
          clockIn: clockIn.toISOString(),
          clockOut: clockOut.toISOString(),
          breakMinutes: 30,
          notes: 'Covered the late shift',
        });

      expect(res.status).toBe(201);
      enteredEntryId = res.body.id;
      expect(res.body.source).toBe('ENTERED');
      expect(res.body.payrollDecision).toBe('PENDING');
      expect(res.body.status).toBe('COMPLETED');
      // Two hours on the clock minus the 30 minute break.
      expect(Number(res.body.totalHours)).toBeCloseTo(1.5, 2);
    });

    it('rejects a clock-out before the clock-in', async () => {
      const res = await request(app.getHttpServer())
        .post('/time-tracking/entries')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          workerId,
          clockIn: new Date().toISOString(),
          clockOut: new Date(Date.now() - 3600_000).toISOString(),
        });

      expect(res.status).toBe(400);
    });

    it('rejects a break longer than the shift', async () => {
      const res = await request(app.getHttpServer())
        .post('/time-tracking/entries')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          workerId,
          clockIn: new Date(Date.now() - 3600_000).toISOString(),
          clockOut: new Date().toISOString(),
          breakMinutes: 120,
        });

      expect(res.status).toBe(400);
    });

    it('keeps pending hours out of the payable total until decided', async () => {
      const review = await request(app.getHttpServer())
        .get('/time-tracking/payroll-review')
        .query({
          startDate: new Date(Date.now() - 24 * 3600_000).toISOString(),
          endDate: new Date(Date.now() + 3600_000).toISOString(),
        })
        .set('Authorization', `Bearer ${employerToken}`);

      expect(review.status).toBe(200);
      const worker = review.body.workers.find(
        (w: any) => w.workerId === workerId,
      );
      expect(worker).toBeDefined();
      expect(worker.pendingHours).toBeCloseTo(1.5, 2);
      expect(worker.includedEnteredHours).toBe(0);
      expect(worker.pendingEntries.map((e: any) => e.id)).toContain(
        enteredEntryId,
      );
      // Payable hours are the clocked hours only, not the entered ones.
      expect(worker.includedHours).toBeCloseTo(worker.clockedHours, 2);
    });

    it('includes the hours once the employer decides', async () => {
      const decide = await request(app.getHttpServer())
        .post('/time-tracking/payroll-review/decision')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({ entryIds: [enteredEntryId], decision: 'INCLUDED' });

      expect(decide.status).toBe(201);
      expect(decide.body.updated).toBe(1);

      const review = await request(app.getHttpServer())
        .get('/time-tracking/payroll-review')
        .query({
          startDate: new Date(Date.now() - 24 * 3600_000).toISOString(),
          endDate: new Date(Date.now() + 3600_000).toISOString(),
        })
        .set('Authorization', `Bearer ${employerToken}`);

      const worker = review.body.workers.find(
        (w: any) => w.workerId === workerId,
      );
      expect(worker.pendingHours).toBeCloseTo(0, 2);
      expect(worker.includedEnteredHours).toBeCloseTo(1.5, 2);
      expect(worker.includedHours).toBeCloseTo(worker.clockedHours + 1.5, 2);
    });

    it('excludes the hours again on request', async () => {
      const decide = await request(app.getHttpServer())
        .post('/time-tracking/payroll-review/decision')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({ entryIds: [enteredEntryId], decision: 'EXCLUDED' });

      expect(decide.status).toBe(201);

      const review = await request(app.getHttpServer())
        .get('/time-tracking/payroll-review')
        .query({
          startDate: new Date(Date.now() - 24 * 3600_000).toISOString(),
          endDate: new Date(Date.now() + 3600_000).toISOString(),
        })
        .set('Authorization', `Bearer ${employerToken}`);

      const worker = review.body.workers.find(
        (w: any) => w.workerId === workerId,
      );
      expect(worker.excludedHours).toBeCloseTo(1.5, 2);
      expect(worker.includedEnteredHours).toBeCloseTo(0, 2);
    });

    it('requires the decision to be re-made after a correction', async () => {
      const adjust = await request(app.getHttpServer())
        .patch(`/time-tracking/adjust/${enteredEntryId}`)
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          clockOut: new Date(Date.now() - 1800_000).toISOString(),
          reason: 'Shift ended earlier than recorded',
        });

      expect(adjust.status).toBe(200);
      expect(adjust.body.payrollDecision).toBe('PENDING');
      expect(adjust.body.status).toBe('ADJUSTED');
    });

    it('refuses a decision on entries the employer does not own', async () => {
      const res = await request(app.getHttpServer())
        .post('/time-tracking/payroll-review/decision')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          entryIds: ['11111111-1111-1111-1111-111111111111'],
          decision: 'INCLUDED',
        });

      expect(res.status).toBe(404);
    });

    it('refuses an empty decision request', async () => {
      const res = await request(app.getHttpServer())
        .post('/time-tracking/payroll-review/decision')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({ entryIds: [], decision: 'INCLUDED' });

      expect(res.status).toBe(400);
    });
  });

  describe('property geofence input', () => {
    it('rejects a pin with only one coordinate', async () => {
      const res = await request(app.getHttpServer())
        .post('/properties')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          name: 'Half a pin',
          address: 'Nowhere',
          latitude: -1.3,
        });

      expect(res.status).toBe(400);
      expect(String(res.body.message)).toMatch(
        /both a latitude and a longitude/i,
      );
    });

    it('rejects an out-of-range radius', async () => {
      const res = await request(app.getHttpServer())
        .post('/properties')
        .set('Authorization', `Bearer ${employerToken}`)
        .send({
          name: 'Tiny fence',
          address: 'Nairobi',
          latitude: propertyLat,
          longitude: propertyLng,
          geofenceRadius: 2,
        });

      expect(res.status).toBe(400);
    });
  });

  describe('what3words lookup', () => {
    it('answers with an actionable message when no API key is configured', async () => {
      const res = await request(app.getHttpServer())
        .get('/property-location/what3words')
        .query({ words: 'filled.count.soap' })
        .set('Authorization', `Bearer ${employerToken}`);

      // CI and local runs have no key: the app must be told to fall back to GPS
      // or manual coordinates rather than hit an unexplained failure.
      expect([200, 503]).toContain(res.status);
      if (res.status === 503) {
        expect(String(res.body.message)).toMatch(/not configured/i);
      }
    });

    it('rejects a malformed what3words address', async () => {
      const res = await request(app.getHttpServer())
        .get('/property-location/what3words')
        .query({ words: 'not-three-words' })
        .set('Authorization', `Bearer ${employerToken}`);

      expect([400, 503]).toContain(res.status);
    });
  });
});
