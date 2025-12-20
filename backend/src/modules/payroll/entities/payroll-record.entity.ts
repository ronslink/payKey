import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Worker } from '../../workers/entities/worker.entity';
import { PayPeriod } from './pay-period.entity';

export enum PayrollStatus {
  DRAFT = 'draft',
  FINALIZED = 'finalized',
  PAID = 'paid',
}

@Entity('payroll_records')
@Index(['payPeriodId'])
@Index(['userId', 'periodStart'])
@Index(['workerId'])
export class PayrollRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  workerId: string;

  @Column({ type: 'uuid', nullable: true })
  payPeriodId: string;

  @ManyToOne(() => PayPeriod, (payPeriod) => payPeriod.payrollRecords)
  @JoinColumn({ name: 'payPeriodId' })
  payPeriod: PayPeriod;

  @ManyToOne(() => Worker, { eager: true })
  @JoinColumn({ name: 'workerId' })
  worker: Worker;

  @Column({ type: 'date' })
  periodStart: Date;

  @Column({ type: 'date' })
  periodEnd: Date;

  @Column('decimal', { precision: 10, scale: 2 })
  grossSalary: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  bonuses: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  otherEarnings: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  otherDeductions: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  holidayHours: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  sundayHours: number;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  overtimePay: number;

  @Column('decimal', { precision: 10, scale: 2 })
  netSalary: number;

  @Column('decimal', { precision: 10, scale: 2 })
  taxAmount: number;

  @Column({
    type: 'simple-enum',
    enum: PayrollStatus,
    default: PayrollStatus.DRAFT,
  })
  status: PayrollStatus;

  @Column({ default: 'pending' })
  paymentStatus: string; // 'pending', 'paid', 'failed', 'processing'

  @Column({ default: 'mpesa' })
  paymentMethod: string; // 'mpesa', 'bank', 'cash'

  @Column({ type: 'timestamp', nullable: true })
  paymentDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  finalizedAt: Date;

  @Column({ type: 'json', nullable: true })
  taxBreakdown: Record<string, any>;

  @Column({ type: 'json', nullable: true })
  deductions: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
