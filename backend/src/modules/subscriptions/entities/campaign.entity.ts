import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PromotionalItem } from './promotional-item.entity';

export enum CampaignStatus {
  DRAFT = 'DRAFT',
  SCHEDULED = 'SCHEDULED',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum CampaignType {
  BANNER = 'BANNER',
  POPUP = 'POPUP',
  EMAIL = 'EMAIL',
  IN_APP_NOTIFICATION = 'IN_APP_NOTIFICATION',
  SIDEBAR = 'SIDEBAR',
}

@Entity('campaigns')
export class Campaign {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: CampaignType,
  })
  type: CampaignType;

  @Column({
    type: 'enum',
    enum: CampaignStatus,
    default: CampaignStatus.DRAFT,
  })
  status: CampaignStatus;

  @Column()
  title: string;

  @Column({ type: 'text' })
  message: string;

  @Column({ type: 'text', nullable: true })
  callToAction: string | null;

  @Column({ type: 'text', nullable: true })
  callToActionUrl: string | null;

  @Column({ type: 'text', nullable: true })
  imageUrl: string | null;

  @Column({ type: 'json', nullable: true })
  targetAudience: {
    tiers?: string[];
    userSegments?: string[];
    countries?: string[];
  } | null;

  @Column({ type: 'timestamptz', nullable: true })
  scheduledFrom: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  scheduledUntil: Date | null;

  @Column({ type: 'int', nullable: true })
  priority: number | null;

  @Column({ type: 'int', default: 0 })
  impressions: number;

  @Column({ type: 'int', default: 0 })
  clicks: number;

  @Column({ type: 'int', default: 0 })
  conversions: number;

  @ManyToOne(() => PromotionalItem, { nullable: true })
  @JoinColumn({ name: 'promotionalItemId' })
  promotionalItem: PromotionalItem | null;

  @Column({ nullable: true })
  promotionalItemId: string | null;

  @Column({ type: 'json', nullable: true })
  displaySettings: {
    position?: string;
    dismissible?: boolean;
    autoHideAfter?: number;
    showOnPages?: string[];
  } | null;

  /**
   * Timestamp of the last time this campaign was dispatched (EMAIL/PUSH sent).
   * NULL means it has never been dispatched.
   * Used by CampaignScheduler to prevent duplicate sends.
   */
  @Column({ type: 'timestamptz', nullable: true })
  lastDispatchedAt: Date | null;

  /**
   * How many recipients were reached on the last dispatch run.
   * Useful for reporting without querying notification records.
   */
  @Column({ type: 'int', default: 0 })
  lastDispatchCount: number;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
