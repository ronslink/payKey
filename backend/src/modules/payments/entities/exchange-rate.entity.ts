import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

@Entity('exchange_rates')
export class ExchangeRate {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  sourceCurrency: string; // e.g. 'EUR'

  @Column()
  targetCurrency: string; // e.g. 'KES'

  @Column('decimal', { precision: 10, scale: 4 })
  rate: number;

  @CreateDateColumn()
  createdAt: Date;
}
