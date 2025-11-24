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
import { TaxType } from '../../tax-config/entities/tax-config.entity';

// Transformer to convert decimal strings to numbers
const decimalTransformer = {
  to: (value: number | null): number | null => value,
  from: (value: string | null): number | null => {
    return value === null || value === undefined ? null : parseFloat(value);
  },
};

export enum PaymentStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  OVERDUE = 'OVERDUE',
}

export enum PaymentMethod {
  MPESA = 'MPESA',
  BANK = 'BANK',
}

@Entity('tax_payments')
export class TaxPayment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: TaxType,
  })
  taxType: TaxType;

  @Column({ type: 'int' })
  paymentYear: number;

  @Column({ type: 'int' })
  paymentMonth: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, transformer: decimalTransformer })
  amount: number;

  @Column({ type: 'date', nullable: true })
  paymentDate: Date;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    nullable: true,
  })
  paymentMethod: PaymentMethod;

  @Column({ nullable: true })
  receiptNumber: string;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status: PaymentStatus;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
