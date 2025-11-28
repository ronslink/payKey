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
  USER = 'USER',
}

export enum IdType {
  NATIONAL_ID = 'NATIONAL_ID',
  ALIEN_ID = 'ALIEN_ID',
  PASSPORT = 'PASSPORT',
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
  nhifNumber: string;

  @Column({
    type: 'enum',
    enum: IdType,
    nullable: true,
    name: 'idtype',
  })
  idType: IdType;

  @Column({ nullable: true })
  idNumber: string;

  @Column({ nullable: true, name: 'nationalityid' })
  nationalityId: string;

  @Column({ nullable: true })
  address: string;

  @Column({ nullable: true })
  city: string;

  @Column({ nullable: true })
  countryId: string;

  @Column({ default: true, name: 'isresident' })
  isResident: boolean;

  @Column({ nullable: true, name: 'countryoforigin' })
  countryOfOrigin: string;

  @Column({ default: false, name: 'isOnboardingCompleted' })
  isOnboardingCompleted: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
