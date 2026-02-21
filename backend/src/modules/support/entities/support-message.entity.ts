import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { SupportTicket } from './support-ticket.entity';

export enum SenderRole {
  USER = 'USER',
  ADMIN = 'ADMIN',
}

@Entity('support_messages')
export class SupportMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => SupportTicket, (ticket) => ticket.messages, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'ticketId' })
  ticket: SupportTicket;

  @Column()
  ticketId: string;

  @Column()
  senderId: string;

  @Column({
    type: 'enum',
    enum: SenderRole,
  })
  senderRole: SenderRole;

  @Column({ type: 'text' })
  message: string;

  @CreateDateColumn()
  createdAt: Date;
}
