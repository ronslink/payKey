import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum ExportType {
  QUICKBOOKS_IIF = 'QUICKBOOKS_IIF',
  XERO_CSV = 'XERO_CSV',
  GENERIC_CSV = 'GENERIC_CSV',
  EXCEL = 'EXCEL',
  KRA_P10_CSV = 'KRA_P10_CSV',
  NSSF_RETURN_EXCEL = 'NSSF_RETURN_EXCEL',
  SHIF_RETURN_EXCEL = 'SHIF_RETURN_EXCEL',
  MUSTER_ROLL_CSV = 'MUSTER_ROLL_CSV',
}

@Entity('exports')
export class Export {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({
    type: 'enum',
    enum: ExportType,
  })
  exportType: ExportType;

  @Column({ type: 'date' })
  startDate: Date;

  @Column({ type: 'date' })
  endDate: Date;

  @Column()
  fileName: string;

  @Column({ nullable: true })
  filePath: string;

  @Column({ type: 'int', default: 0 })
  recordCount: number;

  @CreateDateColumn()
  createdAt: Date;
}
