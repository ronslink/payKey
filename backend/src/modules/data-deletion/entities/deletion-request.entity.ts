import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

export enum DeletionStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

@Entity('deletion_requests')
export class DeletionRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  email: string;

  @Column({ nullable: true })
  reason: string;

  @Column({
    type: 'enum',
    enum: DeletionStatus,
    default: DeletionStatus.PENDING,
  })
  status: DeletionStatus;

  @CreateDateColumn()
  requestedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  processedAt: Date;

  @Column({ nullable: true })
  errorMessage: string;

  @Column({ nullable: true })
  userId: string; // Linked user ID if found
}
