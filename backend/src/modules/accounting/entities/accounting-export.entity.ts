import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PayPeriod } from '../../payroll/entities/pay-period.entity';

export enum ExportFormat {
  CSV = 'CSV',
  EXCEL = 'EXCEL',
  QUICKBOOKS = 'QUICKBOOKS',
  XERO = 'XERO',
  SAGE = 'SAGE',
}

export enum ExportStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

@Entity('accounting_exports')
export class AccountingExport {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @ManyToOne(() => PayPeriod)
  @JoinColumn({ name: 'payPeriodId' })
  payPeriod: PayPeriod;

  @Column()
  payPeriodId: string;

  @Column({
    type: 'enum',
    enum: ExportFormat,
  })
  format: ExportFormat;

  @Column({
    type: 'enum',
    enum: ExportStatus,
    default: ExportStatus.PENDING,
  })
  status: ExportStatus;

  @Column({ nullable: true })
  filePath: string;

  @Column({ nullable: true })
  externalId: string; // For QuickBooks/Xero journal entry IDs

  @Column({ type: 'text', nullable: true })
  errorMessage: string;

  @CreateDateColumn()
  createdAt: Date;
}
