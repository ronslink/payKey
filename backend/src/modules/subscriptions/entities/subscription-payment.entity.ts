import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Subscription } from './subscription.entity';

export enum PaymentStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
}

export enum PaymentMethod {
  CREDIT_CARD = 'Credit Card',
  BANK_TRANSFER = 'Bank Transfer',
  PAYPAL = 'PayPal',
  STRIPE = 'stripe',
  MPESA = 'mpesa',
  WALLET = 'Wallet',
}

// Transformer to convert decimal strings to numbers
const decimalTransformer = {
  to: (value: number | null): number | null => value,
  from: (value: string | null): number | null => {
    return value === null || value === undefined ? null : parseFloat(value);
  },
};

@Entity('subscription_payments')
export class SubscriptionPayment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Subscription)
  @JoinColumn({ name: 'subscriptionId' })
  subscription: Subscription;

  @Column()
  subscriptionId: string;

  @Column({ nullable: true })
  userId: string;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: decimalTransformer,
  })
  amount: number;

  @Column({ default: 'USD' })
  currency: string;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.COMPLETED,
  })
  status: PaymentStatus;

  @Column()
  paymentMethod: PaymentMethod | string;

  @Column()
  billingPeriod: string;

  @Column({ type: 'timestamptz' })
  periodStart: Date;

  @Column({ type: 'timestamptz' })
  periodEnd: Date;

  @Column({ type: 'timestamptz' })
  dueDate: Date;

  @Column({ type: 'timestamptz', nullable: true })
  paidDate: Date;

  @Column({ nullable: true })
  invoiceNumber: string;

  @Column({ nullable: true })
  paymentProvider: string;

  @Column({ nullable: true })
  transactionId: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata: any;

  // Promo code audit fields
  @Column({ type: 'varchar', length: 50, nullable: true })
  promoCodeUsed: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    transformer: decimalTransformer,
    nullable: true,
  })
  promoDiscountAmount: number | null;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
