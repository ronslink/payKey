import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';

@Entity('subscription_plans')
export class SubscriptionPlan {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    tier: string; // FREE, BASIC, GOLD, PLATINUM

    @Column()
    name: string;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    priceUSD: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    priceKES: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    priceUSDYearly: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    priceKESYearly: number;

    @Column({ type: 'int', default: 1 })
    workerLimit: number;

    @Column('jsonb', { default: [] })
    features: string[];

    @Column({ default: false })
    importAccess: boolean;

    @Column({ default: false })
    isPopular: boolean;

    @Column({ default: true })
    isActive: boolean;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
