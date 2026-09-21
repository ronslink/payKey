import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, IsNull, Not, LessThan, In } from 'typeorm';
import {
  TimeEntry,
  TimeEntryPayrollDecision,
  TimeEntrySource,
  TimeEntryStatus,
} from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';

/** One entry an employer has to decide on (or has already decided on). */
export interface PayrollReviewEntry {
  id: string;
  workerId: string;
  workerName: string | null;
  clockIn: Date;
  clockOut: Date | null;
  totalHours: number;
  source: TimeEntrySource;
  payrollDecision: TimeEntryPayrollDecision;
  notes: string | null;
  adjustmentReason: string | null;
}

@Injectable()
export class TimeTrackingService {
  private readonly logger = new Logger(TimeTrackingService.name);

  constructor(
    @InjectRepository(TimeEntry)
    private timeEntryRepository: Repository<TimeEntry>,
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
  ) {}

  /**
   * A shift longer than this cannot be trusted: the employee almost certainly
   * forgot to clock out. Stale entries are closed at the cap and flagged for
   * review instead of staying open forever.
   */
  private get maxShiftHours(): number {
    const configured = Number(process.env.TIME_TRACKING_MAX_SHIFT_HOURS ?? 12);
    return Number.isFinite(configured) && configured > 0 ? configured : 12;
  }

  /**
   * Clock in a worker
   */
  async clockIn(
    workerId: string,
    userId: string,
    recordedById: string,
    location?: { lat: number; lng: number },
    propertyId?: string,
  ): Promise<TimeEntry> {
    // Check if worker exists and belongs to employer
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
      relations: ['property', 'user'],
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    // Determine which property to use: explicit propertyId or worker's assigned property
    let activeProperty = worker.property;
    let activePropertyId = worker.propertyId;

    if (propertyId) {
      // Validate propertyId belongs to employer
      const selectedProperty = await this.workersRepository.manager.findOne(
        'properties',
        { where: { id: propertyId, userId } },
      );
      if (!selectedProperty) {
        throw new BadRequestException('Invalid property selected');
      }
      activeProperty = selectedProperty as any;
      activePropertyId = propertyId;
    }

    if (activeProperty && activeProperty.isActive === false) {
      throw new BadRequestException('Cannot clock into an inactive property');
    }

    // Geofencing Validation
    // Logic: If Employer is PLATINUM AND Property has Coordinates -> Validate
    if (
      worker.user?.tier === 'PLATINUM' &&
      activeProperty?.latitude != null &&
      activeProperty?.longitude != null
    ) {
      if (!location) {
        throw new BadRequestException(
          'Location is required for clock-in at this property',
        );
      }
      this.validateGeofenceForProperty(activeProperty, location);
    }

    // Check if already clocked in
    const activeEntry = await this.timeEntryRepository.findOne({
      where: {
        workerId,
        status: TimeEntryStatus.ACTIVE,
      },
    });

    if (activeEntry) {
      throw new BadRequestException('Worker is already clocked in');
    }

    const entry = this.timeEntryRepository.create({
      workerId,
      userId,
      recordedById,
      clockIn: new Date(),
      status: TimeEntryStatus.ACTIVE,
      clockInLat: location?.lat,
      clockInLng: location?.lng,
      // Observed on the employee's own device, so it is evidence and counts for
      // payroll without a separate decision.
      source: TimeEntrySource.CLOCK,
      payrollDecision: TimeEntryPayrollDecision.INCLUDED,
      payrollDecidedAt: new Date(),
      payrollDecidedBy: recordedById,
      ...(activePropertyId ? { propertyId: activePropertyId } : {}),
    });

    return this.timeEntryRepository.save(entry);
  }

  /**
   * Employer-recorded hours.
   *
   * Both bounds are required: a manual entry is a complete record, so it can
   * never leave a shift hanging open for the auto-close job to guess at. The
   * employer is stored as the recorder, which is how a manual entry stays
   * distinguishable from a geofenced clock-in.
   */
  async createEntry(
    userId: string,
    recordedById: string,
    input: {
      workerId: string;
      clockIn: Date;
      clockOut: Date;
      breakMinutes?: number;
      notes?: string;
      propertyId?: string;
    },
  ): Promise<TimeEntry> {
    const worker = await this.workersRepository.findOne({
      where: { id: input.workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    const { clockIn, clockOut } = input;
    if (
      !(clockIn instanceof Date) ||
      Number.isNaN(clockIn.getTime()) ||
      !(clockOut instanceof Date) ||
      Number.isNaN(clockOut.getTime())
    ) {
      throw new BadRequestException(
        'A valid clock-in and clock-out time are required',
      );
    }
    if (clockOut.getTime() <= clockIn.getTime()) {
      throw new BadRequestException('Clock-out must be after clock-in');
    }

    let propertyId = worker.propertyId;
    if (input.propertyId) {
      const property = await this.workersRepository.manager.findOne(
        'properties',
        { where: { id: input.propertyId, userId } },
      );
      if (!property) {
        throw new BadRequestException('Invalid property selected');
      }
      propertyId = input.propertyId;
    }

    const breakMinutes = Math.max(0, Math.floor(input.breakMinutes ?? 0));
    const workedMs =
      clockOut.getTime() - clockIn.getTime() - breakMinutes * 60_000;
    if (workedMs <= 0) {
      throw new BadRequestException(
        'Break time cannot be longer than the shift',
      );
    }

    const entry = this.timeEntryRepository.create({
      workerId: worker.id,
      userId,
      recordedById,
      clockIn,
      clockOut,
      breakMinutes,
      totalHours: Math.round((workedMs / 3_600_000) * 100) / 100,
      status: TimeEntryStatus.COMPLETED,
      notes: input.notes ?? null,
      // Typed in by the employer, so payroll must decide on it explicitly.
      source: TimeEntrySource.ENTERED,
      payrollDecision: TimeEntryPayrollDecision.PENDING,
      ...(propertyId ? { propertyId } : {}),
    });

    return this.timeEntryRepository.save(entry);
  }

  /**
   * Closes shifts that were never clocked out.
   *
   * A forgotten clock-out blocks the employee from clocking in again
   * ("Worker is already clocked in") for as long as the entry stays open, so
   * entries older than [maxShiftHours] are capped, completed and flagged for
   * the employer to review. They are not cancelled, because the employee did
   * start work and payroll should see the capped hours rather than nothing.
   */
  @Cron(CronExpression.EVERY_HOUR)
  async closeStaleEntriesOnSchedule(): Promise<void> {
    try {
      const { closed, maxShiftHours } = await this.autoCloseStaleEntries();
      if (closed > 0) {
        this.logger.warn(
          `Auto-closed ${closed} time ${closed === 1 ? 'entry' : 'entries'} left open longer than ${maxShiftHours}h`,
        );
      }
    } catch (error) {
      this.logger.error(
        'Failed to auto-close stale time entries',
        error as Error,
      );
    }
  }

  async autoCloseStaleEntries(
    reference: Date = new Date(),
  ): Promise<{ closed: number; maxShiftHours: number }> {
    const maxShiftHours = this.maxShiftHours;
    const cutoff = new Date(reference.getTime() - maxShiftHours * 3_600_000);

    const stale = await this.timeEntryRepository.find({
      where: {
        status: TimeEntryStatus.ACTIVE,
        clockIn: LessThan(cutoff),
      },
    });

    for (const entry of stale) {
      const clockIn = new Date(entry.clockIn);
      const capped = new Date(clockIn.getTime() + maxShiftHours * 3_600_000);
      const clockOut =
        capped.getTime() < reference.getTime() ? capped : reference;
      const workedMs =
        clockOut.getTime() -
        clockIn.getTime() -
        (entry.breakMinutes || 0) * 60_000;

      entry.clockOut = clockOut;
      entry.totalHours = Math.max(
        0,
        Math.round((workedMs / 3_600_000) * 100) / 100,
      );
      entry.status = TimeEntryStatus.COMPLETED;
      entry.adjustmentReason = `Auto-closed after ${maxShiftHours}h without a clock-out; review and correct if needed.`;
      // The clock-out time was never observed, so the hours are a guess: payroll
      // must not count them until the employer decides.
      entry.source = TimeEntrySource.CLOCK;
      entry.payrollDecision = TimeEntryPayrollDecision.PENDING;
      entry.payrollDecidedAt = null;
      entry.payrollDecidedBy = null;

      await this.timeEntryRepository.save(entry);
    }

    return { closed: stale.length, maxShiftHours };
  }

  private calculateDistanceMeters(
    origin: { latitude: number; longitude: number },
    location: { lat: number; lng: number },
  ): number {
    const R = 6371e3; // Earth radius in meters
    const lat1 = (Number(location.lat) * Math.PI) / 180;
    const lat2 = (Number(origin.latitude) * Math.PI) / 180;
    const deltaLat =
      ((Number(origin.latitude) - Number(location.lat)) * Math.PI) / 180;
    const deltaLng =
      ((Number(origin.longitude) - Number(location.lng)) * Math.PI) / 180;

    const a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) *
        Math.cos(lat2) *
        Math.sin(deltaLng / 2) *
        Math.sin(deltaLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private validateGeofence(
    worker: Worker,
    location: { lat: number; lng: number },
  ) {
    const { latitude, longitude, geofenceRadius } = worker.property;

    const distance = this.calculateDistanceMeters(
      { latitude: Number(latitude), longitude: Number(longitude) },
      location,
    );

    if (distance > (geofenceRadius || 100)) {
      throw new BadRequestException(
        `Clock-in rejected: You are ${Math.round(distance)}m away from the property location. Allowed radius: ${geofenceRadius || 100}m.`,
      );
    }
  }

  private validateGeofenceForProperty(
    property: {
      latitude: number | null;
      longitude: number | null;
      geofenceRadius?: number;
    },
    location: { lat: number; lng: number },
  ) {
    if (property.latitude == null || property.longitude == null) return;

    const distance = this.calculateDistanceMeters(
      {
        latitude: Number(property.latitude),
        longitude: Number(property.longitude),
      },
      location,
    );

    if (distance > (property.geofenceRadius || 100)) {
      throw new BadRequestException(
        `Clock-in rejected: You are ${Math.round(distance)}m away from the property location. Allowed radius: ${property.geofenceRadius || 100}m.`,
      );
    }
  }

  /**
   * Clock out a worker
   */
  async clockOut(
    workerId: string,
    userId: string,
    recordedById: string,
    options?: {
      breakMinutes?: number;
      notes?: string;
      location?: { lat: number; lng: number };
    },
  ): Promise<TimeEntry> {
    // Find active entry
    const entry = await this.timeEntryRepository.findOne({
      where: {
        workerId,
        userId,
        status: TimeEntryStatus.ACTIVE,
      },
    });

    if (!entry) {
      throw new BadRequestException('Worker is not clocked in');
    }

    const clockOut = new Date();
    const clockIn = new Date(entry.clockIn);

    // Calculate hours worked
    const diffMs = clockOut.getTime() - clockIn.getTime();
    const breakMs = (options?.breakMinutes || 0) * 60 * 1000;
    const workedMs = diffMs - breakMs;
    const totalHours = Math.round((workedMs / (1000 * 60 * 60)) * 100) / 100;

    entry.clockOut = clockOut;
    entry.totalHours = Math.max(0, totalHours);
    entry.breakMinutes = options?.breakMinutes || 0;
    entry.notes = options?.notes ?? null;
    entry.clockOutLat = options?.location?.lat ?? null;
    entry.clockOutLng = options?.location?.lng ?? null;
    entry.status = TimeEntryStatus.COMPLETED;

    return this.timeEntryRepository.save(entry);
  }

  /**
   * Auto clock-out when worker leaves geofence
   */
  async autoClockOut(
    workerId: string,
    userId: string,
    recordedById: string,
    location: { lat: number; lng: number },
  ): Promise<TimeEntry> {
    // Find active entry
    const entry = await this.timeEntryRepository.findOne({
      where: {
        workerId,
        userId,
        status: TimeEntryStatus.ACTIVE,
      },
      relations: ['property'],
    });

    if (!entry) {
      throw new BadRequestException('Worker is not clocked in');
    }

    if (entry.property?.latitude != null && entry.property?.longitude != null) {
      const distance = this.calculateDistanceMeters(
        {
          latitude: Number(entry.property.latitude),
          longitude: Number(entry.property.longitude),
        },
        location,
      );
      const radius = entry.property.geofenceRadius || 100;

      if (distance <= radius) {
        throw new BadRequestException(
          `Auto clock-out rejected: worker is still within the property geofence (${Math.round(distance)}m of ${radius}m allowed).`,
        );
      }
    }

    const clockOut = new Date();
    const clockIn = new Date(entry.clockIn);

    // Calculate hours worked (no break for auto clock-out)
    const diffMs = clockOut.getTime() - clockIn.getTime();
    const totalHours = Math.round((diffMs / (1000 * 60 * 60)) * 100) / 100;

    entry.clockOut = clockOut;
    entry.totalHours = Math.max(0, totalHours);
    entry.notes = 'Auto clock-out: left geofence area';
    entry.clockOutLat = location.lat;
    entry.clockOutLng = location.lng;
    entry.status = TimeEntryStatus.COMPLETED;

    return this.timeEntryRepository.save(entry);
  }

  /**
   * Get current clock-in status for a worker
   */
  async getStatus(
    workerId: string,
    userId: string,
  ): Promise<{
    isClockedIn: boolean;
    currentEntry: TimeEntry | null;
    todayTotal: number;
  }> {
    const activeEntry = await this.timeEntryRepository.findOne({
      where: {
        workerId,
        userId,
        status: TimeEntryStatus.ACTIVE,
      },
    });

    // Get today's completed entries
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayEntries = await this.timeEntryRepository.find({
      where: {
        workerId,
        userId,
        clockIn: Between(today, tomorrow),
        status: TimeEntryStatus.COMPLETED,
      },
    });

    const todayTotal = todayEntries.reduce(
      (sum, e) => sum + (Number(e.totalHours) || 0),
      0,
    );

    return {
      isClockedIn: !!activeEntry,
      currentEntry: activeEntry,
      todayTotal: Math.round(todayTotal * 100) / 100,
    };
  }

  /**
   * Get time entries for a worker within a date range
   */
  async getEntriesForWorker(
    workerId: string,
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<TimeEntry[]> {
    return this.timeEntryRepository.find({
      where: {
        workerId,
        userId,
        clockIn: Between(startDate, endDate),
        status: Not(TimeEntryStatus.CANCELLED),
      },
      order: { clockIn: 'DESC' },
    });
  }

  /**
   * Get all time entries for an employer within a date range
   */
  async getAllEntriesForEmployer(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<TimeEntry[]> {
    return this.timeEntryRepository.find({
      where: {
        userId,
        clockIn: Between(startDate, endDate),
        status: Not(TimeEntryStatus.CANCELLED),
      },
      relations: ['worker'],
      order: { clockIn: 'DESC' },
    });
  }

  /**
   * Get attendance summary for a pay period
   */
  async getAttendanceSummary(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<{
    workers: Array<{
      workerId: string;
      workerName: string;
      totalDays: number;
      totalHours: number;
      entries: number;
    }>;
    totals: {
      totalEntries: number;
      totalHours: number;
      averageHoursPerDay: number;
    };
  }> {
    const entries = await this.getAllEntriesForEmployer(
      userId,
      startDate,
      endDate,
    );

    // Group by worker
    const workerMap = new Map<
      string,
      {
        workerId: string;
        workerName: string;
        days: Set<string>;
        totalHours: number;
        entries: number;
      }
    >();

    for (const entry of entries) {
      if (!workerMap.has(entry.workerId)) {
        workerMap.set(entry.workerId, {
          workerId: entry.workerId,
          workerName: entry.worker?.name || 'Unknown',
          days: new Set(),
          totalHours: 0,
          entries: 0,
        });
      }

      const stats = workerMap.get(entry.workerId)!;
      stats.days.add(new Date(entry.clockIn).toISOString().split('T')[0]);
      stats.totalHours += Number(entry.totalHours) || 0;
      stats.entries += 1;
    }

    const workers = Array.from(workerMap.values()).map((w) => ({
      workerId: w.workerId,
      workerName: w.workerName,
      totalDays: w.days.size,
      totalHours: Math.round(w.totalHours * 100) / 100,
      entries: w.entries,
    }));

    const totalHours = workers.reduce((sum, w) => sum + w.totalHours, 0);
    const totalDays = workers.reduce((sum, w) => sum + w.totalDays, 0);

    return {
      workers,
      totals: {
        totalEntries: entries.length,
        totalHours: Math.round(totalHours * 100) / 100,
        averageHoursPerDay:
          totalDays > 0 ? Math.round((totalHours / totalDays) * 100) / 100 : 0,
      },
    };
  }

  /**
   * Employer can adjust a time entry
   */
  async adjustEntry(
    entryId: string,
    userId: string,
    adjustments: {
      clockIn?: Date;
      clockOut?: Date;
      breakMinutes?: number;
      reason: string;
    },
  ): Promise<TimeEntry> {
    const entry = await this.timeEntryRepository.findOne({
      where: { id: entryId, userId },
    });

    if (!entry) {
      throw new NotFoundException('Time entry not found');
    }

    if (adjustments.clockIn) {
      entry.clockIn = adjustments.clockIn;
    }
    if (adjustments.clockOut) {
      entry.clockOut = adjustments.clockOut;
    }
    if (adjustments.breakMinutes !== undefined) {
      entry.breakMinutes = adjustments.breakMinutes;
    }

    // Recalculate hours if both times exist
    if (entry.clockIn && entry.clockOut) {
      const diffMs =
        new Date(entry.clockOut).getTime() - new Date(entry.clockIn).getTime();
      const breakMs = (entry.breakMinutes || 0) * 60 * 1000;
      const workedMs = diffMs - breakMs;
      entry.totalHours = Math.max(
        0,
        Math.round((workedMs / (1000 * 60 * 60)) * 100) / 100,
      );
    }

    entry.status = TimeEntryStatus.ADJUSTED;
    entry.adjustmentReason = adjustments.reason;
    // The hours were changed by hand, so any earlier payroll decision was made
    // about different numbers and must be made again.
    entry.payrollDecision = TimeEntryPayrollDecision.PENDING;
    entry.payrollDecidedAt = null;
    entry.payrollDecidedBy = null;

    return this.timeEntryRepository.save(entry);
  }

  /**
   * What payroll would pay for a period, split by provenance, plus the entries
   * an employer still has to decide on.
   *
   * `includedHours` is the number payroll uses: observed clock-ins plus whatever
   * the employer has explicitly included.
   */
  async getPayrollReview(
    userId: string,
    startDate: Date,
    endDate: Date,
  ): Promise<{
    workers: Array<{
      workerId: string;
      workerName: string;
      clockedHours: number;
      includedEnteredHours: number;
      pendingHours: number;
      excludedHours: number;
      includedHours: number;
      pendingEntries: PayrollReviewEntry[];
      excludedEntries: PayrollReviewEntry[];
    }>;
    totals: {
      clockedHours: number;
      includedEnteredHours: number;
      pendingHours: number;
      excludedHours: number;
      includedHours: number;
      pendingEntries: number;
      workersWithPendingHours: number;
    };
  }> {
    const entries = await this.timeEntryRepository.find({
      where: {
        userId,
        clockIn: Between(startDate, endDate),
        status: Not(TimeEntryStatus.CANCELLED),
      },
      relations: ['worker'],
      order: { clockIn: 'DESC' },
    });

    const byWorker = new Map<
      string,
      {
        workerId: string;
        workerName: string;
        clockedHours: number;
        includedEnteredHours: number;
        pendingHours: number;
        excludedHours: number;
        pendingEntries: PayrollReviewEntry[];
        excludedEntries: PayrollReviewEntry[];
      }
    >();

    for (const entry of entries) {
      // An open shift has no hours yet; it is not a payroll decision.
      if (entry.status === TimeEntryStatus.ACTIVE) continue;

      const hours = Number(entry.totalHours) || 0;
      const worker = byWorker.get(entry.workerId) ?? {
        workerId: entry.workerId,
        workerName: entry.worker?.name || 'Unknown',
        clockedHours: 0,
        includedEnteredHours: 0,
        pendingHours: 0,
        excludedHours: 0,
        pendingEntries: [],
        excludedEntries: [],
      };

      if (entry.payrollDecision === TimeEntryPayrollDecision.EXCLUDED) {
        worker.excludedHours += hours;
        worker.excludedEntries.push(this.toPayrollReviewEntry(entry));
      } else if (entry.payrollDecision === TimeEntryPayrollDecision.PENDING) {
        worker.pendingHours += hours;
        worker.pendingEntries.push(this.toPayrollReviewEntry(entry));
      } else if (entry.source === TimeEntrySource.ENTERED) {
        worker.includedEnteredHours += hours;
      } else {
        worker.clockedHours += hours;
      }

      byWorker.set(entry.workerId, worker);
    }

    const round = (value: number) => Math.round(value * 100) / 100;
    const workers = Array.from(byWorker.values()).map((worker) => ({
      ...worker,
      clockedHours: round(worker.clockedHours),
      includedEnteredHours: round(worker.includedEnteredHours),
      pendingHours: round(worker.pendingHours),
      excludedHours: round(worker.excludedHours),
      includedHours: round(worker.clockedHours + worker.includedEnteredHours),
    }));

    const sum = (pick: (worker: (typeof workers)[number]) => number) =>
      round(workers.reduce((total, worker) => total + pick(worker), 0));

    return {
      workers,
      totals: {
        clockedHours: sum((w) => w.clockedHours),
        includedEnteredHours: sum((w) => w.includedEnteredHours),
        pendingHours: sum((w) => w.pendingHours),
        excludedHours: sum((w) => w.excludedHours),
        includedHours: sum((w) => w.includedHours),
        pendingEntries: workers.reduce(
          (total, worker) => total + worker.pendingEntries.length,
          0,
        ),
        workersWithPendingHours: workers.filter((w) => w.pendingHours > 0)
          .length,
      },
    };
  }

  /**
   * Records the employer's payroll decision for one or more entries. Entries
   * must belong to the employer; an open shift cannot be decided because it has
   * no hours yet.
   */
  async decideEntries(
    userId: string,
    entryIds: string[],
    decision: TimeEntryPayrollDecision,
  ): Promise<{ updated: number; decision: TimeEntryPayrollDecision }> {
    const uniqueIds = Array.from(new Set(entryIds ?? [])).filter(Boolean);
    if (uniqueIds.length === 0) {
      throw new BadRequestException('Select at least one time entry');
    }

    const entries = await this.timeEntryRepository.find({
      where: { id: In(uniqueIds), userId },
    });

    if (entries.length !== uniqueIds.length) {
      throw new NotFoundException('One or more time entries were not found');
    }

    const open = entries.filter(
      (entry) => entry.status === TimeEntryStatus.ACTIVE,
    );
    if (open.length > 0) {
      throw new BadRequestException(
        'A shift that is still running has no hours to decide on yet',
      );
    }

    const decidedAt = new Date();
    for (const entry of entries) {
      entry.payrollDecision = decision;
      entry.payrollDecidedAt =
        decision === TimeEntryPayrollDecision.PENDING ? null : decidedAt;
      entry.payrollDecidedBy =
        decision === TimeEntryPayrollDecision.PENDING ? null : userId;
    }

    await this.timeEntryRepository.save(entries);

    return { updated: entries.length, decision };
  }

  private toPayrollReviewEntry(entry: TimeEntry): PayrollReviewEntry {
    return {
      id: entry.id,
      workerId: entry.workerId,
      workerName: entry.worker?.name ?? null,
      clockIn: entry.clockIn,
      clockOut: entry.clockOut,
      totalHours: Number(entry.totalHours) || 0,
      source: entry.source,
      payrollDecision: entry.payrollDecision,
      notes: entry.notes,
      adjustmentReason: entry.adjustmentReason,
    };
  }

  /**
   * Get live status of all workers (who's clocked in now)
   */
  async getLiveStatus(userId: string): Promise<
    Array<{
      workerId: string;
      workerName: string;
      isClockedIn: boolean;
      clockInTime: Date | null;
      duration: string;
    }>
  > {
    // Get all workers for employer
    const workers = await this.workersRepository.find({
      where: { userId, isActive: true },
    });

    const result = [];

    for (const worker of workers) {
      const activeEntry = await this.timeEntryRepository.findOne({
        where: {
          workerId: worker.id,
          status: TimeEntryStatus.ACTIVE,
        },
      });

      let duration = '--';
      if (activeEntry) {
        const now = new Date();
        const diffMs = now.getTime() - new Date(activeEntry.clockIn).getTime();
        const hours = Math.floor(diffMs / (1000 * 60 * 60));
        const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
        duration = `${hours}h ${minutes}m`;
      }

      result.push({
        workerId: worker.id,
        workerName: worker.name,
        isClockedIn: !!activeEntry,
        clockInTime: activeEntry?.clockIn || null,
        duration,
      });
    }

    return result;
  }
}
