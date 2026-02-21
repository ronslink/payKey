import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum PromoItemType {
  DISCOUNT = 'DISCOUNT',
  FREE_TRIAL = 'FREE_TRIAL',
  FEATURE_UNLOCK = 'FEATURE_UNLOCK',
  CREDIT = 'CREDIT',
}

export enum PromoStatus {
  DRAFT = 'DRAFT',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  EXPIRED = 'EXPIRED',
}

@Entity('promotional_items')
export class PromotionalItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: PromoItemType,
  })
  type: PromoItemType;

  @Column({
    type: 'enum',
    enum: PromoStatus,
    default: PromoStatus.DRAFT,
  })
  status: PromoStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  discountPercentage: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  discountAmount: number | null;

  @Column({ type: 'int', nullable: true })
  freeTrialDays: number | null;

  @Column({ type: 'json', nullable: true })
  features: string[] | null;

  @Column({ type: 'int', nullable: true })
  maxUses: number | null;

  @Column({ type: 'int', default: 0 })
  currentUses: number;

  @Column({ type: 'timestamptz', nullable: true })
  validFrom: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  validUntil: Date | null;

  @Column({ type: 'json', nullable: true })
  applicableTiers: string[] | null;

  @Column({ type: 'varchar', length: 50, nullable: true, unique: true })
  promoCode: string | null;

  @Column({ type: 'text', nullable: true })
  termsAndConditions: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
