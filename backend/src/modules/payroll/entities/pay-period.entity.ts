import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  BeforeInsert,
  BeforeUpdate,
  Index,
} from 'typeorm';
import { TaxSubmission } from '../../taxes/entities/tax-submission.entity';
import { Transaction } from '../../payments/entities/transaction.entity';
import { PayrollRecord } from './payroll-record.entity';

// =============================================================================
// ENUMS
// =============================================================================

/**
 * Frequency at which pay periods occur.
 */
export enum PayPeriodFrequency {
  WEEKLY = 'WEEKLY',
  BIWEEKLY = 'BIWEEKLY',
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
}

/**
 * Status of a pay period in the payroll workflow.
 *
 * Lifecycle: DRAFT -> ACTIVE -> PROCESSING -> COMPLETED -> CLOSED
 */
export enum PayPeriodStatus {
  /** Initial state, payroll is being prepared */
  DRAFT = 'DRAFT',
  /** Pay period is active, time entries can be recorded */
  ACTIVE = 'ACTIVE',
  /** Payroll calculations are being processed */
  PROCESSING = 'PROCESSING',
  /** Payroll has been calculated and approved */
  COMPLETED = 'COMPLETED',
  /** Pay period is finalized and locked */
  CLOSED = 'CLOSED',
}

// =============================================================================
// TYPES
// =============================================================================

/**
 * Valid status transitions for pay periods.
 */
export const PAY_PERIOD_TRANSITIONS: Record<
  PayPeriodStatus,
  PayPeriodStatus[]
> = {
  [PayPeriodStatus.DRAFT]: [PayPeriodStatus.ACTIVE],
  [PayPeriodStatus.ACTIVE]: [PayPeriodStatus.PROCESSING, PayPeriodStatus.DRAFT],
  [PayPeriodStatus.PROCESSING]: [
    PayPeriodStatus.COMPLETED,
    PayPeriodStatus.ACTIVE,
  ],
  [PayPeriodStatus.COMPLETED]: [
    PayPeriodStatus.CLOSED,
    PayPeriodStatus.PROCESSING,
  ],
  [PayPeriodStatus.CLOSED]: [], // Terminal state
};

/**
 * Structure for pay period notes/metadata.
 */
export interface PayPeriodNotes {
  /** General comments about this pay period */
  comments?: string;
  /** Reason for any adjustments made */
  adjustmentReason?: string;
  /** IDs of workers excluded from this period */
  excludedWorkers?: string[];
  /** Custom fields for extensibility */
  custom?: Record<string, unknown>;
}

/**
 * Summary statistics for a pay period.
 */
export interface PayPeriodSummary {
  totalGrossAmount: number;
  totalNetAmount: number;
  totalTaxAmount: number;
  totalWorkers: number;
  processedWorkers: number;
  pendingWorkers: number;
  completionPercentage: number;
}

// =============================================================================
// ENTITY
// =============================================================================

/**
 * Represents a pay period for payroll processing.
 *
 * A pay period defines a date range for which workers are paid,
 * tracks the status of payroll processing, and aggregates totals.
 */
@Entity('pay_periods')
@Index(['userId', 'status'])
@Index(['userId', 'startDate', 'endDate'])
export class PayPeriod {
  // ---------------------------------------------------------------------------
  // Primary Key
  // ---------------------------------------------------------------------------

  @PrimaryGeneratedColumn('uuid')
  id: string;

  // ---------------------------------------------------------------------------
  // Core Fields
  // ---------------------------------------------------------------------------

  /**
   * Display name for the pay period.
   * @example "August 2025 - Week 1", "September 2025 Monthly"
   */
  @Column({ length: 100, nullable: true })
  name: string;

  /**
   * First day of the pay period (inclusive).
   */
  @Column({ type: 'date' })
  startDate: Date;

  /**
   * Last day of the pay period (inclusive).
   */
  @Column({ type: 'date' })
  endDate: Date;

  /**
   * Scheduled date for payment disbursement.
   */
  @Column({ type: 'date', nullable: true })
  payDate: Date | null;

  /**
   * How often this type of pay period recurs.
   */
  @Column({
    type: 'simple-enum',
    enum: PayPeriodFrequency,
    default: PayPeriodFrequency.MONTHLY,
  })
  frequency: PayPeriodFrequency;

  /**
   * Current status in the payroll workflow.
   */
  @Column({
    type: 'simple-enum',
    enum: PayPeriodStatus,
    default: PayPeriodStatus.DRAFT,
  })
  status: PayPeriodStatus;

  /**
   * Whether this is an off-cycle payroll (bonus, advance, etc.).
   */
  @Column({ type: 'boolean', default: false })
  isOffCycle: boolean;

  // ---------------------------------------------------------------------------
  // Ownership & Authorization
  // ---------------------------------------------------------------------------

  /**
   * User/employer who owns this pay period.
   */
  @Column({ type: 'uuid' })
  @Index()
  userId: string;

  /**
   * User who created this pay period.
   */
  @Column({ type: 'varchar', nullable: true })
  createdBy: string | null;

  /**
   * User who approved this pay period for processing.
   */
  @Column({ type: 'varchar', nullable: true })
  approvedBy: string | null;

  // ---------------------------------------------------------------------------
  // Financial Totals
  // ---------------------------------------------------------------------------

  /**
   * Sum of all gross salaries in this period.
   */
  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalGrossAmount: number;

  /**
   * Sum of all net pay amounts in this period.
   */
  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalNetAmount: number;

  /**
   * Sum of all tax deductions in this period.
   */
  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalTaxAmount: number;

  // ---------------------------------------------------------------------------
  // Worker Counts
  // ---------------------------------------------------------------------------

  /**
   * Total number of workers included in this pay period.
   */
  @Column('int', { default: 0 })
  totalWorkers: number;

  /**
   * Number of workers whose payroll has been processed.
   */
  @Column('int', { default: 0 })
  processedWorkers: number;

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  /**
   * Additional notes and metadata for this pay period.
   */
  @Column({ type: 'json', nullable: true })
  notes: PayPeriodNotes | null;

  // ---------------------------------------------------------------------------
  // Timestamps
  // ---------------------------------------------------------------------------

  /**
   * When this pay period was approved.
   */
  @Column({ type: 'timestamp', nullable: true })
  approvedAt: Date | null;

  /**
   * When payroll processing completed.
   */
  @Column({ type: 'timestamp', nullable: true })
  processedAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // ---------------------------------------------------------------------------
  // Relations
  // ---------------------------------------------------------------------------

  /**
   * Tax submissions generated for this pay period.
   */
  @OneToMany(() => TaxSubmission, (taxSubmission) => taxSubmission.payPeriod)
  taxSubmissions: TaxSubmission[];

  /**
   * Payroll records for individual workers in this period.
   */
  @OneToMany(() => PayrollRecord, (record) => record.payPeriodId)
  payrollRecords: PayrollRecord[];

  /**
   * Payment transactions associated with this pay period.
   */
  @OneToMany(() => Transaction, (transaction) => transaction.payPeriod)
  transactions: Transaction[];

  // ---------------------------------------------------------------------------
  // Lifecycle Hooks
  // ---------------------------------------------------------------------------

  @BeforeInsert()
  @BeforeUpdate()
  validateDates(): void {
    if (this.startDate && this.endDate) {
      const start = new Date(this.startDate);
      const end = new Date(this.endDate);

      if (end < start) {
        throw new Error('End date cannot be before start date');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Computed Properties
  // ---------------------------------------------------------------------------

  /**
   * Number of workers pending processing.
   */
  get pendingWorkers(): number {
    return Math.max(0, this.totalWorkers - this.processedWorkers);
  }

  /**
   * Percentage of workers processed (0-100).
   */
  get completionPercentage(): number {
    if (this.totalWorkers === 0) return 0;
    return Math.round((this.processedWorkers / this.totalWorkers) * 100);
  }

  /**
   * Whether all workers have been processed.
   */
  get isFullyProcessed(): boolean {
    return this.totalWorkers > 0 && this.processedWorkers >= this.totalWorkers;
  }

  /**
   * Total deductions (gross minus net).
   */
  get totalDeductions(): number {
    return Number(this.totalGrossAmount) - Number(this.totalNetAmount);
  }

  /**
   * Number of days in this pay period.
   */
  get durationDays(): number {
    const start = new Date(this.startDate);
    const end = new Date(this.endDate);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1; // +1 to include both days
  }

  /**
   * Whether this pay period can be edited.
   */
  get isEditable(): boolean {
    return (
      this.status === PayPeriodStatus.DRAFT ||
      this.status === PayPeriodStatus.ACTIVE
    );
  }

  /**
   * Whether this pay period is in a terminal state.
   */
  get isClosed(): boolean {
    return this.status === PayPeriodStatus.CLOSED;
  }

  /**
   * Whether payments can be initiated for this period.
   */
  get canInitiatePayments(): boolean {
    return this.status === PayPeriodStatus.COMPLETED;
  }

  // ---------------------------------------------------------------------------
  // Instance Methods
  // ---------------------------------------------------------------------------

  /**
   * Check if a status transition is valid.
   */
  canTransitionTo(newStatus: PayPeriodStatus): boolean {
    return PAY_PERIOD_TRANSITIONS[this.status].includes(newStatus);
  }

  /**
   * Get valid next statuses from current state.
   */
  getValidTransitions(): PayPeriodStatus[] {
    return PAY_PERIOD_TRANSITIONS[this.status];
  }

  /**
   * Get a summary of this pay period's statistics.
   */
  getSummary(): PayPeriodSummary {
    return {
      totalGrossAmount: Number(this.totalGrossAmount),
      totalNetAmount: Number(this.totalNetAmount),
      totalTaxAmount: Number(this.totalTaxAmount),
      totalWorkers: this.totalWorkers,
      processedWorkers: this.processedWorkers,
      pendingWorkers: this.pendingWorkers,
      completionPercentage: this.completionPercentage,
    };
  }

  /**
   * Check if a date falls within this pay period.
   */
  containsDate(date: Date): boolean {
    const checkDate = new Date(date);
    const start = new Date(this.startDate);
    const end = new Date(this.endDate);

    // Reset time components for date-only comparison
    checkDate.setHours(0, 0, 0, 0);
    start.setHours(0, 0, 0, 0);
    end.setHours(0, 0, 0, 0);

    return checkDate >= start && checkDate <= end;
  }

  /**
   * Get a display-friendly date range string.
   */
  getDateRangeDisplay(locale = 'en-US'): string {
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    };

    const start = new Date(this.startDate).toLocaleDateString(locale, options);
    const end = new Date(this.endDate).toLocaleDateString(locale, options);

    return `${start} - ${end}`;
  }

  /**
   * Create a display-friendly status label.
   */
  getStatusDisplay(): string {
    const labels: Record<PayPeriodStatus, string> = {
      [PayPeriodStatus.DRAFT]: 'Draft',
      [PayPeriodStatus.ACTIVE]: 'Active',
      [PayPeriodStatus.PROCESSING]: 'Processing',
      [PayPeriodStatus.COMPLETED]: 'Completed',
      [PayPeriodStatus.CLOSED]: 'Closed',
    };

    return labels[this.status];
  }

  /**
   * Create a display-friendly frequency label.
   */
  getFrequencyDisplay(): string {
    const labels: Record<PayPeriodFrequency, string> = {
      [PayPeriodFrequency.WEEKLY]: 'Weekly',
      [PayPeriodFrequency.BIWEEKLY]: 'Bi-Weekly',
      [PayPeriodFrequency.MONTHLY]: 'Monthly',
      [PayPeriodFrequency.QUARTERLY]: 'Quarterly',
    };

    return labels[this.frequency];
  }
}

// =============================================================================
// FACTORY FUNCTIONS
// =============================================================================

/**
 * Create a new pay period with sensible defaults.
 */
export function createPayPeriod(
  params: Pick<PayPeriod, 'name' | 'startDate' | 'endDate' | 'userId'> &
    Partial<Pick<PayPeriod, 'frequency' | 'payDate' | 'createdBy' | 'notes'>>,
): Partial<PayPeriod> {
  return {
    name: params.name,
    startDate: params.startDate,
    endDate: params.endDate,
    userId: params.userId,
    frequency: params.frequency ?? PayPeriodFrequency.MONTHLY,
    payDate: params.payDate ?? null,
    createdBy: params.createdBy ?? params.userId,
    notes: params.notes ?? null,
    status: PayPeriodStatus.DRAFT,
    totalGrossAmount: 0,
    totalNetAmount: 0,
    totalTaxAmount: 0,
    totalWorkers: 0,
    processedWorkers: 0,
  };
}

/**
 * Generate a default name for a pay period based on dates and frequency.
 */
export function generatePayPeriodName(
  startDate: Date,
  frequency: PayPeriodFrequency,
): string {
  const date = new Date(startDate);
  const monthName = date.toLocaleDateString('en-US', { month: 'long' });
  const year = date.getFullYear();

  switch (frequency) {
    case PayPeriodFrequency.WEEKLY: {
      const weekNumber = Math.ceil(date.getDate() / 7);
      return `${monthName} ${year} - Week ${weekNumber}`;
    }
    case PayPeriodFrequency.BIWEEKLY: {
      const biweekNumber = date.getDate() <= 15 ? 1 : 2;
      return `${monthName} ${year} - Period ${biweekNumber}`;
    }
    case PayPeriodFrequency.MONTHLY:
      return `${monthName} ${year}`;
    case PayPeriodFrequency.QUARTERLY: {
      const quarter = Math.ceil((date.getMonth() + 1) / 3);
      return `Q${quarter} ${year}`;
    }
    default:
      return `${monthName} ${year}`;
  }
}
