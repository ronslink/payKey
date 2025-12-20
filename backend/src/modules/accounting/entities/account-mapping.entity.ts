import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum AccountCategory {
  SALARY_EXPENSE = 'SALARY_EXPENSE',
  PAYE_LIABILITY = 'PAYE_LIABILITY',
  NSSF_LIABILITY = 'NSSF_LIABILITY',
  NHIF_LIABILITY = 'NHIF_LIABILITY',
  HOUSING_LEVY_LIABILITY = 'HOUSING_LEVY_LIABILITY',
  CASH_BANK = 'CASH_BANK',
}

@Entity('account_mappings')
export class AccountMapping {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({
    type: 'enum',
    enum: AccountCategory,
  })
  category: AccountCategory;

  @Column()
  accountCode: string;

  @Column()
  accountName: string;

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
