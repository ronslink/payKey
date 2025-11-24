import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Worker } from './worker.entity';
import { User } from '../../users/entities/user.entity';

export enum TerminationReason {
  RESIGNATION = 'RESIGNATION',
  DISMISSAL = 'DISMISSAL',
  CONTRACT_END = 'CONTRACT_END',
  ILLNESS = 'ILLNESS',
  DEATH = 'DEATH',
  RETIREMENT = 'RETIREMENT',
  REDUNDANCY = 'REDUNDANCY',
  OTHER = 'OTHER',
}

@Entity('terminations')
export class Termination {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Worker)
  @JoinColumn({ name: 'workerId' })
  worker: Worker;

  @Column()
  workerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: TerminationReason,
  })
  reason: TerminationReason;

  @Column({ type: 'date' })
  terminationDate: Date;

  @Column({ type: 'date', nullable: true })
  lastWorkingDate: Date;

  @Column({ type: 'int', default: 0 })
  noticePeriodDays: number;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  proratedSalary: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  unusedLeavePayout: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  severancePay: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  totalFinalPayment: number;

  @Column({ type: 'jsonb', nullable: true })
  paymentBreakdown: {
    daysWorked: number;
    dailyRate: number;
    unusedLeaveDays: number;
    taxDeductions: any;
    severancePay?: number;
    outstandingPayments?: number;
  };

  @CreateDateColumn()
  createdAt: Date;
}
