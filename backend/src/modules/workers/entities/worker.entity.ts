import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Property } from '../../properties/entities/property.entity';

// Transformer to convert decimal strings to numbers
const decimalTransformer = {
  to: (value: number | null): number | null => value,
  from: (value: string | null): number | null => {
    return value === null || value === undefined ? null : parseFloat(value);
  },
};

export enum EmploymentType {
  FIXED = 'FIXED',
  HOURLY = 'HOURLY',
}

export enum PaymentFrequency {
  MONTHLY = 'MONTHLY',
  WEEKLY = 'WEEKLY',
}

export enum PaymentMethod {
  MPESA = 'MPESA',
  BANK = 'BANK',
  CASH = 'CASH',
}

@Entity('workers')
export class Worker {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: EmploymentType,
    default: EmploymentType.FIXED,
  })
  employmentType: EmploymentType;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    nullable: true,
    transformer: decimalTransformer,
  })
  hourlyRate: number;

  @ManyToOne(() => User, (user) => user.id)
  user: User;

  @Column()
  userId: string;

  @Column()
  name: string;

  @Column()
  phoneNumber: string;

  @Column({ nullable: true })
  idNumber: string;

  @Column({ nullable: true })
  kraPin: string;

  @Column('decimal', {
    precision: 12,
    scale: 2,
    transformer: decimalTransformer,
  })
  salaryGross: number;

  @Column({ type: 'date' })
  startDate: Date;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'int', default: 0 })
  leaveBalance: number;

  // Employee Portal Link
  @Column({ nullable: true })
  linkedUserId: string; // Links to User account if employee has logged in

  @Column({ nullable: true })
  inviteCode: string; // 6-digit code for employee to claim account

  @Column({ type: 'timestamp', nullable: true })
  inviteCodeExpiry: Date;

  @Column({ nullable: true })
  email: string;

  @Column({ nullable: true })
  nssfNumber: string;

  @Column({ nullable: true })
  nhifNumber: string;

  @Column({ nullable: true })
  jobTitle: string;

  @Column('decimal', {
    precision: 12,
    scale: 2,
    default: 0,
    transformer: decimalTransformer,
  })
  housingAllowance: number;

  @Column('decimal', {
    precision: 12,
    scale: 2,
    default: 0,
    transformer: decimalTransformer,
  })
  transportAllowance: number;

  @Column({
    type: 'enum',
    enum: PaymentFrequency,
    default: PaymentFrequency.MONTHLY,
  })
  paymentFrequency: PaymentFrequency;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.MPESA,
  })
  paymentMethod: PaymentMethod;

  @Column({ nullable: true })
  mpesaNumber: string;

  @Column({ nullable: true })
  bankName: string;

  @Column({ nullable: true })
  bankAccount: string;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ nullable: true })
  terminationId: string;

  @Column({ type: 'timestamp', nullable: true })
  terminatedAt: Date;

  @ManyToOne(() => Property, { nullable: true })
  @JoinColumn({ name: 'propertyId' })
  property: Property;

  @Column({ nullable: true })
  propertyId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
