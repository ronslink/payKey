import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, IsNull, Not } from 'typeorm';
import { TimeEntry, TimeEntryStatus } from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';

@Injectable()
export class TimeTrackingService {
  constructor(
    @InjectRepository(TimeEntry)
    private timeEntryRepository: Repository<TimeEntry>,
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
  ) {}

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

    // Geofencing Validation
    // Logic: If Employer is PLATINUM AND Property has Coordinates -> Validate
    if (
      worker.user?.tier === 'PLATINUM' &&
      activeProperty?.latitude &&
      activeProperty?.longitude
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
      propertyId: activePropertyId,
      clockIn: new Date(),
      status: TimeEntryStatus.ACTIVE,
      clockInLat: location?.lat,
      clockInLng: location?.lng,
    });

    return this.timeEntryRepository.save(entry);
  }

  private validateGeofence(
    worker: Worker,
    location: { lat: number; lng: number },
  ) {
    const { latitude, longitude, geofenceRadius } = worker.property;

    // Haversine Formula
    const R = 6371e3; // Earth radius in meters
    const lat1 = (Number(location.lat) * Math.PI) / 180;
    const lat2 = (Number(latitude) * Math.PI) / 180;
    const deltaLat =
      ((Number(latitude) - Number(location.lat)) * Math.PI) / 180;
    const deltaLng =
      ((Number(longitude) - Number(location.lng)) * Math.PI) / 180;

    const a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) *
        Math.cos(lat2) *
        Math.sin(deltaLng / 2) *
        Math.sin(deltaLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // in meters

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
    if (!property.latitude || !property.longitude) return;

    // Haversine Formula
    const R = 6371e3; // Earth radius in meters
    const lat1 = (Number(location.lat) * Math.PI) / 180;
    const lat2 = (Number(property.latitude) * Math.PI) / 180;
    const deltaLat =
      ((Number(property.latitude) - Number(location.lat)) * Math.PI) / 180;
    const deltaLng =
      ((Number(property.longitude) - Number(location.lng)) * Math.PI) / 180;

    const a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) *
        Math.cos(lat2) *
        Math.sin(deltaLng / 2) *
        Math.sin(deltaLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // in meters

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

    return this.timeEntryRepository.save(entry);
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
