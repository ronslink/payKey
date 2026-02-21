import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { Worker } from './worker.entity';

export enum DocumentType {
  ID_COPY = 'ID_COPY',
  CONTRACT = 'CONTRACT',
  CERTIFICATE = 'CERTIFICATE',
  TAX_DOCUMENT = 'TAX_DOCUMENT',
  OTHER = 'OTHER',
}

@Entity('worker_documents')
@Index(['workerId', 'createdAt'])
export class WorkerDocument {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Worker, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'workerId' })
  worker: Worker;

  @Column()
  workerId: string;

  @Column({
    type: 'enum',
    enum: DocumentType,
    default: DocumentType.OTHER,
  })
  type: DocumentType;

  @Column()
  name: string; // Original filename

  @Column()
  url: string; // File URL

  @Column({ type: 'integer', nullable: true })
  fileSize: number; // Size in bytes

  @Column({ nullable: true })
  mimeType: string;

  @Column({ type: 'date', nullable: true })
  expiresAt: Date; // For documents that expire (e.g., certificates)

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;
}
