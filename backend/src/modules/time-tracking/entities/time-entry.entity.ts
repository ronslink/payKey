import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Worker } from '../../workers/entities/worker.entity';

export enum TimeEntryStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
}

@Entity('time_entries')
export class TimeEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.id)
  user: User;

  @Column()
  workerId: string;

  @Column()
  userId: string;

  @Column({ nullable: true })
  propertyId: string;

  @Column({ type: 'timestamp' })
  clockInTime: Date;

  @Column({ type: 'timestamp', nullable: true })
  clockOutTime: Date;

  @Column('decimal', { precision: 10, scale: 6, nullable: true })
  clockInLatitude: number;

  @Column('decimal', { precision: 10, scale: 6, nullable: true })
  clockInLongitude: number;

  @Column('decimal', { precision: 10, scale: 6, nullable: true })
  clockOutLatitude: number;

  @Column('decimal', { precision: 10, scale: 6, nullable: true })
  clockOutLongitude: number;

  @Column('decimal', { precision: 5, scale: 2, nullable: true })
  totalHours: number;

  @Column({
    type: 'enum',
    enum: TimeEntryStatus,
    default: TimeEntryStatus.IN_PROGRESS,
  })
  status: TimeEntryStatus;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;
}
