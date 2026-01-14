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

export enum GovSubmissionType {
    KRA_P10 = 'KRA_P10',
    SHIF = 'SHIF',
    NSSF = 'NSSF',
}

export enum GovSubmissionStatus {
    GENERATED = 'GENERATED',    // File generated, ready for download
    UPLOADED = 'UPLOADED',      // User uploaded to portal
    CONFIRMED = 'CONFIRMED',    // Portal confirmed submission
    ERROR = 'ERROR',            // Error in process
}

@Entity('gov_submissions')
export class GovSubmission {
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
        enum: GovSubmissionType,
    })
    type: GovSubmissionType;

    @Column({
        type: 'enum',
        enum: GovSubmissionStatus,
        default: GovSubmissionStatus.GENERATED,
    })
    status: GovSubmissionStatus;

    @Column({ nullable: true })
    filePath: string;

    @Column({ nullable: true })
    fileName: string;

    @Column({ nullable: true })
    referenceNumber: string;  // Portal confirmation number

    @Column({ type: 'text', nullable: true })
    notes: string;

    @Column('decimal', { precision: 12, scale: 2, default: 0 })
    totalAmount: number;

    @Column({ type: 'int', default: 0 })
    employeeCount: number;

    @Column({ type: 'timestamp', nullable: true })
    uploadedAt: Date;

    @Column({ type: 'timestamp', nullable: true })
    confirmedAt: Date;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
