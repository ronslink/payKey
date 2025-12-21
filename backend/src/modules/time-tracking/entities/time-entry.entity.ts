import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { Worker } from '../../workers/entities/worker.entity';
import { Property } from '../../properties/entities/property.entity';

export enum TimeEntryStatus {
  ACTIVE = 'ACTIVE', // Currently clocked in
  COMPLETED = 'COMPLETED', // Clocked out normally
  ADJUSTED = 'ADJUSTED', // Employer adjusted the entry
  CANCELLED = 'CANCELLED', // Entry was cancelled
}

@Entity('time_entries')
@Index(['workerId', 'clockIn'])
@Index(['userId', 'clockIn'])
export class TimeEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  workerId: string;

  @ManyToOne(() => Worker)
  @JoinColumn({ name: 'workerId' })
  worker: Worker;

  @Column({ type: 'uuid' })
  userId: string; // Employer ID

  @ManyToOne(() => Property, { nullable: true })
  @JoinColumn({ name: 'propertyId' })
  property: Property;

  @Column({ type: 'uuid', nullable: true })
  propertyId: string;

  @Column({ type: 'uuid', nullable: true })
  recordedById: string; // Who logged it (worker's user ID or employer)

  // Clock times
  @Column({ type: 'timestamp' })
  clockIn: Date;

  @Column({ type: 'timestamp', nullable: true })
  clockOut: Date;

  // Duration
  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  totalHours: number; // Calculated on clock out

  @Column({ type: 'int', default: 0 })
  breakMinutes: number;

  // Location (optional)
  @Column({ type: 'decimal', precision: 10, scale: 8, nullable: true })
  clockInLat: number | null;

  @Column({ type: 'decimal', precision: 11, scale: 8, nullable: true })
  clockInLng: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 8, nullable: true })
  clockOutLat: number | null;

  @Column({ type: 'decimal', precision: 11, scale: 8, nullable: true })
  clockOutLng: number | null;

  // Status
  @Column({
    type: 'enum',
    enum: TimeEntryStatus,
    default: TimeEntryStatus.ACTIVE,
  })
  status: TimeEntryStatus;

  // Metadata
  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ type: 'text', nullable: true })
  adjustmentReason: string | null; // If employer adjusted

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Computed property for duration display
  get durationDisplay(): string {
    if (!this.totalHours) return '--';
    const hours = Math.floor(this.totalHours);
    const minutes = Math.round((this.totalHours - hours) * 60);
    return `${hours}h ${minutes}m`;
  }
}
