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

/** Where the hours came from. */
export enum TimeEntrySource {
  /** The employee's own geofenced clock-in/out. */
  CLOCK = 'CLOCK',
  /** Typed in by the employer, or closed by the stale-shift job. */
  ENTERED = 'ENTERED',
}

/**
 * Whether payroll may count these hours.
 *
 * Only INCLUDED hours are paid. Clocked hours are included on creation because
 * the device on site is the evidence; anything typed in or guessed starts as
 * PENDING so the employer decides before it becomes pay.
 */
export enum TimeEntryPayrollDecision {
  PENDING = 'PENDING',
  INCLUDED = 'INCLUDED',
  EXCLUDED = 'EXCLUDED',
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

  // Provenance and payroll inclusion
  @Column({
    type: 'enum',
    enum: TimeEntrySource,
    default: TimeEntrySource.CLOCK,
  })
  source: TimeEntrySource;

  /**
   * Only INCLUDED hours are paid. A geofenced clock-in is included on creation
   * because the device on site is the evidence; hours typed in by the employer,
   * or guessed by the stale-shift job, stay PENDING so they cannot become pay
   * without a decision.
   */
  @Column({
    type: 'enum',
    enum: TimeEntryPayrollDecision,
    default: TimeEntryPayrollDecision.PENDING,
  })
  payrollDecision: TimeEntryPayrollDecision;

  @Column({ type: 'timestamp', nullable: true })
  payrollDecidedAt: Date | null;

  @Column({ type: 'uuid', nullable: true })
  payrollDecidedBy: string | null;

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
