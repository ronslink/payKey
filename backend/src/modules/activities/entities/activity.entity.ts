import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum ActivityType {
  PAYROLL = 'payroll',
  WORKER = 'worker',
  TAX = 'tax',
  LEAVE = 'leave',
  TIME_TRACKING = 'time_tracking',
  ACCOUNTING = 'accounting',
}

@Entity('activities')
export class Activity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({
    type: 'enum',
    enum: ActivityType,
  })
  type: ActivityType;

  @Column()
  title: string;

  @Column()
  description: string;

  @Column('jsonb', { nullable: true })
  metadata: {
    workerCount?: number;
    amount?: number;
    workerName?: string;
    payPeriodId?: string;
    taxSubmissionId?: string;
    [key: string]: any;
  };

  @CreateDateColumn()
  timestamp: Date;
}
