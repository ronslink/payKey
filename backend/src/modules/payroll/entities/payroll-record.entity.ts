import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Worker } from '../../workers/entities/worker.entity';

export enum PayrollStatus {
  DRAFT = 'draft',
  FINALIZED = 'finalized',
  PAID = 'paid',
}

@Entity('payroll_records')
export class PayrollRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  workerId: string;

  @Column({ nullable: true })
  payPeriodId: string;

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

  @Column('decimal', { precision: 10, scale: 2 })
  netSalary: number;

  @Column('decimal', { precision: 10, scale: 2 })
  taxAmount: number;

  @Column({
    type: 'simple-enum',
    enum: PayrollStatus,
    default: PayrollStatus.DRAFT
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
