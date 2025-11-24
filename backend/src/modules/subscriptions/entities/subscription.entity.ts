import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum SubscriptionStatus {
  ACTIVE = 'ACTIVE',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
  PAST_DUE = 'PAST_DUE',
  TRIAL = 'TRIAL',
}

// Transformer to convert decimal strings to numbers
const decimalTransformer = {
  to: (value: number | null): number | null => value,
  from: (value: string | null): number | null => {
    return value === null || value === undefined ? null : parseFloat(value);
  },
};

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
  })
  tier: string;

  @Column({
    type: 'enum',
    enum: SubscriptionStatus,
    default: SubscriptionStatus.ACTIVE,
  })
  status: SubscriptionStatus;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: decimalTransformer,
    nullable: true,
  })
  amount: number;

  @Column({ default: 'USD' })
  currency: string;

  @Column({ type: 'timestamptz', nullable: true })
  startDate: Date;

  @Column({ type: 'timestamptz', nullable: true })
  endDate: Date;

  @Column({ type: 'timestamptz', nullable: true })
  nextBillingDate: Date;

  @Column({ nullable: true })
  stripeSubscriptionId: string;

  @Column({ nullable: true })
  stripePriceId: string;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}