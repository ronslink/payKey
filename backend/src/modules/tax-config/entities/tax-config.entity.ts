import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum TaxType {
  PAYE = 'PAYE',
  SHIF = 'SHIF',
  NSSF_TIER1 = 'NSSF_TIER1',
  NSSF_TIER2 = 'NSSF_TIER2',
  HOUSING_LEVY = 'HOUSING_LEVY',
}

export enum RateType {
  PERCENTAGE = 'PERCENTAGE',
  GRADUATED = 'GRADUATED',
  TIERED = 'TIERED',
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

  // Reliefs/deductions
  personalRelief?: number;
  insuranceRelief?: number;
  maxInsuranceRelief?: number;
}

@Entity('tax_configs')
export class TaxConfig {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: TaxType,
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
