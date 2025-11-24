import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from './entities/worker.entity';
import { CreateWorkerDto } from './dto/create-worker.dto';

@Injectable()
export class WorkersService {
  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
  ) {}

  async create(
    userId: string,
    createWorkerDto: CreateWorkerDto,
  ): Promise<Worker> {
    const worker = this.workersRepository.create({
      ...createWorkerDto,
      userId,
    });
    return this.workersRepository.save(worker);
  }

  async findAll(userId: string): Promise<Worker[]> {
    return this.workersRepository.find({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string, userId: string): Promise<Worker | null> {
    return this.workersRepository.findOne({
      where: { id, userId },
    });
  }

  async update(
    id: string,
    userId: string,
    updateWorkerDto: Partial<CreateWorkerDto>,
  ): Promise<Worker> {
    const worker = await this.workersRepository.findOne({
      where: { id, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    Object.assign(worker, updateWorkerDto);
    return this.workersRepository.save(worker);
  }

  async remove(id: string, userId: string): Promise<void> {
    const worker = await this.workersRepository.findOne({
      where: { id, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    await this.workersRepository.remove(worker);
  }

  async getWorkerCount(userId: string): Promise<number> {
    return this.workersRepository.count({
      where: { userId, isActive: true },
    });
  }

  async archiveWorker(id: string, userId: string): Promise<Worker> {
    const worker = await this.workersRepository.findOne({
      where: { id, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    worker.isActive = false;
    worker.terminatedAt = new Date();
    return this.workersRepository.save(worker);
  }
}
