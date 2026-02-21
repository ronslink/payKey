import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('admin_audit_logs')
export class AdminAuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  adminUserId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'adminUserId' })
  adminUser: User;

  @Column()
  action: string;

  @Column()
  entityType: string;

  @Column({ nullable: true })
  entityId: string;

  @Column('jsonb', { nullable: true })
  oldValues: any;

  @Column('jsonb', { nullable: true })
  newValues: any;

  @Column({ nullable: true })
  ipAddress: string;

  @Column({ nullable: true })
  userAgent: string;

  @CreateDateColumn()
  createdAt: Date;
}
