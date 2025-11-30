import { Repository } from 'typeorm';
import { Worker } from './entities/worker.entity';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { ActivitiesService } from '../activities/activities.service';
export declare class WorkersService {
    private workersRepository;
    private activitiesService;
    constructor(workersRepository: Repository<Worker>, activitiesService: ActivitiesService);
    create(userId: string, createWorkerDto: CreateWorkerDto): Promise<Worker>;
    findAll(userId: string): Promise<Worker[]>;
    findOne(id: string, userId: string): Promise<Worker | null>;
    update(id: string, userId: string, updateWorkerDto: Partial<CreateWorkerDto>): Promise<Worker>;
    remove(id: string, userId: string): Promise<void>;
    getWorkerCount(userId: string): Promise<number>;
    archiveWorker(id: string, userId: string): Promise<Worker>;
}
