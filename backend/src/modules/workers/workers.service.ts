import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Worker } from './entities/worker.entity';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { ActivitiesService } from '../activities/activities.service';
import { ActivityType } from '../activities/entities/activity.entity';

@Injectable()
export class WorkersService {
  constructor(
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    private activitiesService: ActivitiesService,
  ) { }

  async create(
    userId: string,
    createWorkerDto: CreateWorkerDto,
  ): Promise<Worker> {
    const worker = this.workersRepository.create({
      ...createWorkerDto,
      userId,
    });
    const savedWorker = await this.workersRepository.save(worker);

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.WORKER,
        'New Worker Added',
        `Added ${savedWorker.name} to your team`,
        {
          workerId: savedWorker.id,
          workerName: savedWorker.name,
        },
      );
    } catch (e) {
      console.error('Failed to log activity:', e);
    }

    return savedWorker;
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
    const savedWorker = await this.workersRepository.save(worker);

    try {
      await this.activitiesService.logActivity(
        userId,
        ActivityType.WORKER,
        'Worker Archived',
        `Archived worker ${savedWorker.name}`,
        {
          workerId: savedWorker.id,
          workerName: savedWorker.name,
        },
      );
    } catch (e) {
      console.error('Failed to log activity:', e);
    }

    return savedWorker;
  }
}
