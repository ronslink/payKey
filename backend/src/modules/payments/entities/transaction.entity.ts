import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Worker } from '../../workers/entities/worker.entity';
import { PayPeriod } from '../../payroll/entities/pay-period.entity';

export enum TransactionType {
  SUBSCRIPTION = 'SUBSCRIPTION',
  SALARY_PAYOUT = 'SALARY_PAYOUT',
  TOPUP = 'TOPUP',
  DEPOSIT = 'DEPOSIT', // Alias for TOPUP/INCOMING
}

export enum TransactionStatus {
  PENDING = 'PENDING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  CLEARING = 'CLEARING',
  MANUAL_INTERVENTION = 'MANUAL_INTERVENTION',
}

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.id)
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Worker, { nullable: true })
  worker: Worker;

  @Column({ nullable: true })
  workerId: string;

  @Column('decimal', { precision: 12, scale: 2 })
  amount: number;

  @Column({ default: 'KES' })
  currency: string;

  @Column({
    type: 'enum',
    enum: TransactionType,
    nullable: true,
  })
  type: TransactionType;

  @Column({
    type: 'enum',
    enum: TransactionStatus,
    default: TransactionStatus.PENDING,
  })
  status: TransactionStatus;

  @Column({ nullable: true })
  providerRef: string;

  @Column({ nullable: true })
  provider: string;

  @Column({ nullable: true })
  recipientPhone: string;

  @Column({ nullable: true })
  accountReference: string;

  @Column({ nullable: true })
  propertyId: string;

  @Column('jsonb', { nullable: true })
  metadata: any;

  @ManyToOne(() => PayPeriod, (payPeriod) => payPeriod.transactions, {
    nullable: true,
  })
  payPeriod: PayPeriod;

  @Column({ nullable: true })
  payPeriodId: string;

  @CreateDateColumn()
  createdAt: Date;
}
