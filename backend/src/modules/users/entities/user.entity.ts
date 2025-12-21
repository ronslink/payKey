import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UserTier {
  FREE = 'FREE',
  BASIC = 'BASIC',
  GOLD = 'GOLD',
  PLATINUM = 'PLATINUM',
}

export enum UserRole {
  ADMIN = 'ADMIN',
  USER = 'USER', // Legacy, treat as EMPLOYER
  EMPLOYER = 'EMPLOYER',
  WORKER = 'WORKER',
}

export enum IdType {
  NATIONAL_ID = 'NATIONAL_ID',
  ALIEN_ID = 'ALIEN_ID',
  PASSPORT = 'PASSPORT',
}

export enum PayrollFrequency {
  WEEKLY = 'WEEKLY',
  BI_WEEKLY = 'BI_WEEKLY',
  MONTHLY = 'MONTHLY',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.USER,
  })
  role: UserRole;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({
    type: 'enum',
    enum: UserTier,
    default: UserTier.FREE,
  })
  tier: UserTier;

  @Column({ nullable: true })
  stripeCustomerId: string;

  // Compliance Fields
  @Column({ nullable: true })
  kraPin: string;

  @Column({ nullable: true })
  nssfNumber: string;

  @Column({ nullable: true })
  shifNumber: string; // Renamed from nhifNumber

  @Column({
    type: 'enum',
    enum: IdType,
    nullable: true,
  })
  idType: IdType;

  @Column({ nullable: true })
  idNumber: string;

  @Column({ nullable: true })
  nationalityId: string;

  @Column({ nullable: true })
  address: string;

  @Column({ nullable: true })
  city: string;

  @Column({ nullable: true })
  countryId: string;

  @Column({ nullable: true })
  residentStatus: string;

  @Column({ default: false, name: 'isOnboardingCompleted' })
  isOnboardingCompleted: boolean;

  // New Compliance & Payment Fields
  @Column({ nullable: true })
  businessName: string;

  @Column({ nullable: true })
  bankName: string;

  @Column({ nullable: true })
  bankAccount: string;

  @Column({ nullable: true })
  mpesaPaybill: string;

  @Column({ nullable: true })
  mpesaTill: string;

  // Payroll Settings
  @Column({
    type: 'enum',
    enum: PayrollFrequency,
    default: PayrollFrequency.MONTHLY,
    nullable: true,
  })
  defaultPayrollFrequency: PayrollFrequency;

  // Employee Portal Fields
  @Column({ nullable: true })
  employerId: string; // For EMPLOYEE role: links to employer's user ID

  @Column({ nullable: true })
  linkedWorkerId: string; // For EMPLOYEE role: links to their worker record

  @Column({ nullable: true })
  phoneNumber: string; // For employee login via phone

  @Column({ nullable: true })
  pin: string; // Hashed PIN for employee login

  // Wallet for payroll payments
  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  walletBalance: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
