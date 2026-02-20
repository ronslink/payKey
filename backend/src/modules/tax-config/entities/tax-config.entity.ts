import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum TaxType {
  PAYE = 'PAYE',
  NHIF = 'NHIF', // Legacy, replaced by SHIF Oct 2024
  SHIF = 'SHIF',
  NSSF_TIER1 = 'NSSF_TIER1',
  NSSF_TIER2 = 'NSSF_TIER2',
  HOUSING_LEVY = 'HOUSING_LEVY',
}

export enum RateType {
  PERCENTAGE = 'PERCENTAGE',
  GRADUATED = 'GRADUATED',
  TIERED = 'TIERED',
  BANDED = 'BANDED', // For NHIF banded rates
}

export interface TaxBracket {
  from: number;
  to: number | null;
  rate: number;
}

export interface TaxTier {
  name: string;
  salaryFrom: number;
  salaryTo: number | null;
  rate: number;
}

export interface TaxConfiguration {
  // For percentage-based (SHIF, Housing Levy)
  percentage?: number;
  minAmount?: number;
  maxAmount?: number;

  // For graduated (PAYE)
  brackets?: TaxBracket[];

  // For tiered (NSSF)
  tiers?: TaxTier[];

  // For banded (NHIF)
  bands?: Array<{ from: number; to: number | null; amount: number }>;

  // Reliefs/deductions
  personalRelief?: number;
  insuranceRelief?: number;
  maxInsuranceRelief?: number;
}

@Entity('tax_config')
export class TaxConfig {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'varchar',
    nullable: true,
  })
  taxType: TaxType;

  @Column({
    type: 'enum',
    enum: RateType,
  })
  rateType: RateType;

  @Column({ type: 'date' })
  effectiveFrom: Date;

  @Column({ type: 'date', nullable: true })
  effectiveTo: Date;

  @Column({ type: 'jsonb' })
  configuration: TaxConfiguration;

  @Column({ default: '9th of following month' })
  paymentDeadline: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
