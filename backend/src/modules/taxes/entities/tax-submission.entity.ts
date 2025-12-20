import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PayPeriod } from '../../payroll/entities/pay-period.entity';

export enum TaxSubmissionStatus {
  PENDING = 'PENDING',
  FILED = 'FILED',
}

@Entity('tax_submissions')
export class TaxSubmission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  userId: string;

  @ManyToOne(() => PayPeriod, (payPeriod) => payPeriod.taxSubmissions)
  @JoinColumn({ name: 'payPeriodId' })
  payPeriod: PayPeriod;

  @Column()
  payPeriodId: string;

  @Column('decimal', { precision: 12, scale: 2, default: 0 })
  totalPaye: number;

  @Column('decimal', { precision: 12, scale: 2, default: 0 })
  totalNssf: number;

  @Column('decimal', { precision: 12, scale: 2, default: 0 })
  totalNhif: number;

  @Column('decimal', { precision: 12, scale: 2, default: 0 })
  totalHousingLevy: number;

  @Column({
    type: 'enum',
    enum: TaxSubmissionStatus,
    default: TaxSubmissionStatus.PENDING,
  })
  status: TaxSubmissionStatus;

  @Column({ type: 'timestamp', nullable: true })
  filingDate: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
