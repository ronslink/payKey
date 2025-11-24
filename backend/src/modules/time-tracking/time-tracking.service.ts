import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { TimeEntry, TimeEntryStatus } from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';
import { ClockInDto, ClockOutDto } from './dto/time-tracking.dto';

@Injectable()
export class TimeTrackingService {
  constructor(
    @InjectRepository(TimeEntry)
    private timeEntryRepository: Repository<TimeEntry>,
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
  ) {}

  /**
   * Calculate distance between two GPS coordinates in meters
   * Using Haversine formula
   */
  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in meters
  }

  /**
   * Validate if location is within geofence
   * For now, we'll use a default radius of 100 meters
   * In future, this can be property-specific
   */
  private validateGeofence(
    currentLat: number,
    currentLon: number,
    allowedLat?: number,
    allowedLon?: number,
    radiusMeters: number = 100,
  ): boolean {
    // If no geofence is set, allow any location
    if (!allowedLat || !allowedLon) {
      return true;
    }

    const distance = this.calculateDistance(
      currentLat,
      currentLon,
      allowedLat,
      allowedLon,
    );

    return distance <= radiusMeters;
  }

  /**
   * Clock in a worker
   */
  async clockIn(userId: string, dto: ClockInDto): Promise<TimeEntry> {
    // Verify worker belongs to user and load property
    const worker = await this.workerRepository.findOne({
      where: { id: dto.workerId, userId },
      relations: ['property'],
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    // Check if worker already has an active time entry
    const activeEntry = await this.timeEntryRepository.findOne({
      where: {
        workerId: dto.workerId,
        status: TimeEntryStatus.IN_PROGRESS,
      },
    });

    if (activeEntry) {
      throw new BadRequestException('Worker is already clocked in');
    }

    // Validate geofence if worker is assigned to a property
    if (
      worker.property &&
      worker.property.latitude &&
      worker.property.longitude
    ) {
      const isValid = this.validateGeofence(
        dto.latitude,
        dto.longitude,
        worker.property.latitude,
        worker.property.longitude,
        worker.property.geofenceRadius || 100, // Default to 100m if not set
      );

      if (!isValid) {
        throw new BadRequestException(
          `You are not within the allowed area for ${worker.property.name}. Please move closer to the property.`,
        );
      }
    }

    const timeEntry = this.timeEntryRepository.create({
      userId,
      workerId: dto.workerId,
      propertyId: worker.property?.id, // Save propertyId
      clockInTime: new Date(),
      clockInLatitude: dto.latitude,
      clockInLongitude: dto.longitude,
      notes: dto.notes,
      status: TimeEntryStatus.IN_PROGRESS,
    });

    return this.timeEntryRepository.save(timeEntry);
  }

  /**
   * Clock out a worker
   */
  async clockOut(userId: string, dto: ClockOutDto): Promise<TimeEntry> {
    const timeEntry = await this.timeEntryRepository.findOne({
      where: { id: dto.timeEntryId, userId },
    });

    if (!timeEntry) {
      throw new NotFoundException('Time entry not found');
    }

    if (timeEntry.status === TimeEntryStatus.COMPLETED) {
      throw new BadRequestException('Time entry already completed');
    }

    const clockOutTime = new Date();
    const totalHours =
      (clockOutTime.getTime() - timeEntry.clockInTime.getTime()) /
      (1000 * 60 * 60);

    timeEntry.clockOutTime = clockOutTime;
    timeEntry.clockOutLatitude = dto.latitude;
    timeEntry.clockOutLongitude = dto.longitude;
    timeEntry.totalHours = Math.round(totalHours * 100) / 100;
    timeEntry.status = TimeEntryStatus.COMPLETED;
    if (dto.notes) {
      timeEntry.notes = dto.notes;
    }

    return this.timeEntryRepository.save(timeEntry);
  }

  /**
   * Get active time entry for a worker
   */
  async getActiveEntry(
    userId: string,
    workerId: string,
  ): Promise<TimeEntry | null> {
    return this.timeEntryRepository.findOne({
      where: {
        userId,
        workerId,
        status: TimeEntryStatus.IN_PROGRESS,
      },
    });
  }

  /**
   * Get time entries for a user with optional filters
   */
  async getTimeEntries(
    userId: string,
    workerId?: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<TimeEntry[]> {
    const where: any = { userId };

    if (workerId) {
      where.workerId = workerId;
    }

    if (startDate && endDate) {
      where.clockInTime = Between(startDate, endDate);
    }

    return this.timeEntryRepository.find({
      where,
      order: { clockInTime: 'DESC' },
    });
  }

  /**
   * Get time entries for a specific worker
   */
  async getWorkerTimeEntries(
    userId: string,
    workerId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<TimeEntry[]> {
    return this.getTimeEntries(userId, workerId, startDate, endDate);
  }
}
