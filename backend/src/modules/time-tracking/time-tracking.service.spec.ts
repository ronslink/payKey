import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { TimeTrackingService } from './time-tracking.service';
import {
  TimeEntry,
  TimeEntryPayrollDecision,
  TimeEntrySource,
  TimeEntryStatus,
} from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';

describe('TimeTrackingService', () => {
  let service: TimeTrackingService;
  let entries: {
    find: jest.Mock;
    findOne: jest.Mock;
    create: jest.Mock;
    save: jest.Mock;
  };
  let workers: {
    findOne: jest.Mock;
    find: jest.Mock;
    manager: { findOne: jest.Mock };
  };

  beforeEach(async () => {
    entries = {
      find: jest.fn().mockResolvedValue([]),
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn((value: unknown) => value),
      save: jest.fn((value: unknown) => Promise.resolve(value)),
    };
    workers = {
      findOne: jest.fn(),
      find: jest.fn().mockResolvedValue([]),
      manager: { findOne: jest.fn() },
    };

    const module = await Test.createTestingModule({
      providers: [
        TimeTrackingService,
        { provide: getRepositoryToken(TimeEntry), useValue: entries },
        { provide: getRepositoryToken(Worker), useValue: workers },
      ],
    }).compile();

    service = module.get(TimeTrackingService);
  });

  afterEach(() => {
    delete process.env.TIME_TRACKING_MAX_SHIFT_HOURS;
  });

  describe('autoCloseStaleEntries', () => {
    const now = new Date('2026-09-21T12:00:00.000Z');

    it('caps a forgotten shift at the maximum length and asks payroll to review it', async () => {
      const clockIn = new Date(now.getTime() - 20 * 3_600_000);
      entries.find.mockResolvedValue([
        {
          id: 'stale',
          workerId: 'worker-1',
          clockIn,
          breakMinutes: 0,
          status: TimeEntryStatus.ACTIVE,
          payrollDecision: TimeEntryPayrollDecision.INCLUDED,
          payrollDecidedAt: new Date(),
          payrollDecidedBy: 'employee-user',
        },
      ]);

      const result = await service.autoCloseStaleEntries(now);

      expect(result).toEqual({ closed: 1, maxShiftHours: 12 });
      expect(entries.find.mock.calls[0][0].where.status).toBe(
        TimeEntryStatus.ACTIVE,
      );

      const saved = entries.save.mock.calls[0][0];
      expect(saved.status).toBe(TimeEntryStatus.COMPLETED);
      expect(saved.totalHours).toBe(12);
      expect(new Date(saved.clockOut).toISOString()).toBe(
        new Date(clockIn.getTime() + 12 * 3_600_000).toISOString(),
      );
      expect(saved.adjustmentReason).toMatch(/Auto-closed/);
      // The clock-out was never observed, so payroll must decide on the hours.
      expect(saved.payrollDecision).toBe(TimeEntryPayrollDecision.PENDING);
      expect(saved.payrollDecidedAt).toBeNull();
      expect(saved.payrollDecidedBy).toBeNull();
    });

    it('never closes a shift past the reference time', async () => {
      const clockIn = new Date(now.getTime() - 13 * 3_600_000);
      entries.find.mockResolvedValue([
        {
          id: 'edge',
          workerId: 'worker-1',
          clockIn,
          breakMinutes: 0,
          status: TimeEntryStatus.ACTIVE,
        },
      ]);

      await service.autoCloseStaleEntries(now);

      const saved = entries.save.mock.calls[0][0];
      expect(new Date(saved.clockOut).getTime()).toBeLessThanOrEqual(
        now.getTime(),
      );
      expect(saved.totalHours).toBe(12);
    });

    it('subtracts the recorded break when capping', async () => {
      const clockIn = new Date(now.getTime() - 20 * 3_600_000);
      entries.find.mockResolvedValue([
        {
          id: 'with-break',
          workerId: 'worker-1',
          clockIn,
          breakMinutes: 60,
          status: TimeEntryStatus.ACTIVE,
        },
      ]);

      await service.autoCloseStaleEntries(now);

      expect(entries.save.mock.calls[0][0].totalHours).toBe(11);
    });

    it('honours TIME_TRACKING_MAX_SHIFT_HOURS', async () => {
      process.env.TIME_TRACKING_MAX_SHIFT_HOURS = '8';
      const clockIn = new Date(now.getTime() - 20 * 3_600_000);
      entries.find.mockResolvedValue([
        { id: 'stale', workerId: 'w', clockIn, breakMinutes: 0 },
      ]);

      const result = await service.autoCloseStaleEntries(now);

      expect(result.maxShiftHours).toBe(8);
      expect(entries.save.mock.calls[0][0].totalHours).toBe(8);
    });

    it('does nothing when no shift is stale', async () => {
      const result = await service.autoCloseStaleEntries(now);

      expect(result.closed).toBe(0);
      expect(entries.save).not.toHaveBeenCalled();
    });
  });

  describe('createEntry', () => {
    const employerUserId = 'employer-user';

    beforeEach(() => {
      workers.findOne.mockResolvedValue({ id: 'worker-1', propertyId: null });
    });

    it('rejects a worker that does not belong to the employer', async () => {
      workers.findOne.mockResolvedValue(null);

      await expect(
        service.createEntry(employerUserId, employerUserId, {
          workerId: 'worker-1',
          clockIn: new Date('2026-09-21T08:00:00.000Z'),
          clockOut: new Date('2026-09-21T16:00:00.000Z'),
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects a clock-out before the clock-in', async () => {
      await expect(
        service.createEntry(employerUserId, employerUserId, {
          workerId: 'worker-1',
          clockIn: new Date('2026-09-21T16:00:00.000Z'),
          clockOut: new Date('2026-09-21T08:00:00.000Z'),
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a break longer than the shift', async () => {
      await expect(
        service.createEntry(employerUserId, employerUserId, {
          workerId: 'worker-1',
          clockIn: new Date('2026-09-21T08:00:00.000Z'),
          clockOut: new Date('2026-09-21T09:00:00.000Z'),
          breakMinutes: 120,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a property the employer does not own', async () => {
      workers.manager.findOne.mockResolvedValue(null);

      await expect(
        service.createEntry(employerUserId, employerUserId, {
          workerId: 'worker-1',
          clockIn: new Date('2026-09-21T08:00:00.000Z'),
          clockOut: new Date('2026-09-21T16:00:00.000Z'),
          propertyId: 'someone-elses-property',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('computes the hours and marks the entry as employer-entered and undecided', async () => {
      const saved = await service.createEntry(employerUserId, employerUserId, {
        workerId: 'worker-1',
        clockIn: new Date('2026-09-21T08:00:00.000Z'),
        clockOut: new Date('2026-09-21T16:30:00.000Z'),
        breakMinutes: 30,
        notes: 'Late shift',
      });

      expect(saved.totalHours).toBe(8);
      expect(saved.status).toBe(TimeEntryStatus.COMPLETED);
      expect(saved.source).toBe(TimeEntrySource.ENTERED);
      expect(saved.payrollDecision).toBe(TimeEntryPayrollDecision.PENDING);
      expect(saved.payrollDecidedAt).toBeUndefined();
      expect(saved.notes).toBe('Late shift');
    });
  });

  describe('decideEntries', () => {
    const employerUserId = 'employer-user';

    it('rejects an empty selection', async () => {
      await expect(
        service.decideEntries(
          employerUserId,
          [],
          TimeEntryPayrollDecision.INCLUDED,
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects entries the employer does not own', async () => {
      entries.find.mockResolvedValue([]);

      await expect(
        service.decideEntries(
          employerUserId,
          ['entry-1'],
          TimeEntryPayrollDecision.INCLUDED,
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects a shift that is still running', async () => {
      entries.find.mockResolvedValue([
        { id: 'entry-1', status: TimeEntryStatus.ACTIVE },
      ]);

      await expect(
        service.decideEntries(
          employerUserId,
          ['entry-1'],
          TimeEntryPayrollDecision.INCLUDED,
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('records who decided and when', async () => {
      const entry = { id: 'entry-1', status: TimeEntryStatus.COMPLETED };
      entries.find.mockResolvedValue([entry]);

      const result = await service.decideEntries(
        employerUserId,
        ['entry-1'],
        TimeEntryPayrollDecision.INCLUDED,
      );

      expect(result).toEqual({
        updated: 1,
        decision: TimeEntryPayrollDecision.INCLUDED,
      });
      expect(entry.payrollDecision).toBe(TimeEntryPayrollDecision.INCLUDED);
      expect(entry.payrollDecidedBy).toBe(employerUserId);
      expect(entry.payrollDecidedAt).toBeInstanceOf(Date);
    });

    it('clears the decision when it is returned to pending', async () => {
      const entry = {
        id: 'entry-1',
        status: TimeEntryStatus.COMPLETED,
        payrollDecision: TimeEntryPayrollDecision.INCLUDED,
        payrollDecidedAt: new Date(),
        payrollDecidedBy: employerUserId,
      };
      entries.find.mockResolvedValue([entry]);

      await service.decideEntries(
        employerUserId,
        ['entry-1'],
        TimeEntryPayrollDecision.PENDING,
      );

      expect(entry.payrollDecision).toBe(TimeEntryPayrollDecision.PENDING);
      expect(entry.payrollDecidedAt).toBeNull();
      expect(entry.payrollDecidedBy).toBeNull();
    });
  });

  describe('getPayrollReview', () => {
    const employerUserId = 'employer-user';
    const range = {
      startDate: new Date('2026-09-01T00:00:00.000Z'),
      endDate: new Date('2026-09-30T23:59:59.999Z'),
    };

    it('splits payable, pending and excluded hours and skips open shifts', async () => {
      entries.find.mockResolvedValue([
        {
          id: 'clocked',
          workerId: 'worker-1',
          worker: { name: 'Amina' },
          status: TimeEntryStatus.COMPLETED,
          source: TimeEntrySource.CLOCK,
          payrollDecision: TimeEntryPayrollDecision.INCLUDED,
          totalHours: '8.00',
          clockIn: new Date('2026-09-02T08:00:00.000Z'),
          clockOut: new Date('2026-09-02T16:00:00.000Z'),
        },
        {
          id: 'entered',
          workerId: 'worker-1',
          worker: { name: 'Amina' },
          status: TimeEntryStatus.COMPLETED,
          source: TimeEntrySource.ENTERED,
          payrollDecision: TimeEntryPayrollDecision.PENDING,
          totalHours: 3,
          adjustmentReason: null,
        },
        {
          id: 'excluded',
          workerId: 'worker-1',
          worker: { name: 'Amina' },
          status: TimeEntryStatus.COMPLETED,
          source: TimeEntrySource.ENTERED,
          payrollDecision: TimeEntryPayrollDecision.EXCLUDED,
          totalHours: 2,
        },
        {
          id: 'still-working',
          workerId: 'worker-1',
          worker: { name: 'Amina' },
          status: TimeEntryStatus.ACTIVE,
          source: TimeEntrySource.CLOCK,
          payrollDecision: TimeEntryPayrollDecision.INCLUDED,
          totalHours: null,
        },
      ]);

      const review = await service.getPayrollReview(
        employerUserId,
        range.startDate,
        range.endDate,
      );

      const worker = review.workers[0];
      expect(worker.clockedHours).toBe(8);
      expect(worker.pendingHours).toBe(3);
      expect(worker.excludedHours).toBe(2);
      expect(worker.includedHours).toBe(8);
      expect(worker.pendingEntries.map((entry) => entry.id)).toEqual([
        'entered',
      ]);
      expect(worker.pendingEntries[0].workerName).toBe('Amina');

      expect(review.totals).toMatchObject({
        clockedHours: 8,
        pendingHours: 3,
        excludedHours: 2,
        includedHours: 8,
        pendingEntries: 1,
        workersWithPendingHours: 1,
      });
    });
  });
});
