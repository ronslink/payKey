import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { TaxSubmission } from '../../taxes/entities/tax-submission.entity';
import { Transaction } from '../../payments/entities/transaction.entity';
import { PayrollRecord } from './payroll-record.entity';

export enum PayPeriodFrequency {
  WEEKLY = 'WEEKLY',
  BIWEEKLY = 'BIWEEKLY',
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
}

export enum PayPeriodStatus {
  DRAFT = 'DRAFT',
  ACTIVE = 'ACTIVE',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  CLOSED = 'CLOSED',
}

@Entity('pay_periods')
export class PayPeriod {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // e.g., "August 2025 - Week 1"

  @Column({ type: 'date' })
  startDate: Date;

  @Column({ type: 'date' })
  endDate: Date;

  @Column()
  userId: string;

  @Column({ type: 'date', nullable: true })
  payDate: string;

  @Column({
    type: 'enum',
    enum: PayPeriodFrequency,
    default: PayPeriodFrequency.MONTHLY,
  })
  frequency: PayPeriodFrequency;

  @Column({
    type: 'enum',
    enum: PayPeriodStatus,
    default: PayPeriodStatus.DRAFT,
  })
  status: PayPeriodStatus;

  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalGrossAmount: number;

  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalNetAmount: number;

  @Column('decimal', { precision: 15, scale: 2, default: 0 })
  totalTaxAmount: number;

  @Column('int', { default: 0 })
  totalWorkers: number;

  @Column('int', { default: 0 })
  processedWorkers: number;

  @Column({ type: 'json', nullable: true })
  notes: Record<string, any>;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  approvedBy: string;

  @Column({ type: 'timestamp', nullable: true })
  approvedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  processedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => TaxSubmission, (taxSubmission) => taxSubmission.payPeriod)
  taxSubmissions: TaxSubmission[];

  // Property for Transaction entity relationship
  transactions: any[];
}
