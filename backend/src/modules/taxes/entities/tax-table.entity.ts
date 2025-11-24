import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export interface NssfConfig {
  tierILimit: number;
  tierIILimit: number;
  rate: number;
}

export interface NhifConfig {
  rate: number;
}

export interface PayeBand {
  limit: number;
  rate: number;
}

@Entity('tax_tables')
export class TaxTable {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  year: number;

  @Column({ type: 'date' })
  effectiveDate: Date;

  @Column('jsonb')
  nssfConfig: NssfConfig;

  @Column('jsonb')
  nhifConfig: NhifConfig;

  @Column('decimal', { precision: 5, scale: 4 })
  housingLevyRate: number;

  @Column('jsonb')
  payeBands: PayeBand[];

  @Column('decimal', { precision: 12, scale: 2 })
  personalRelief: number;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
