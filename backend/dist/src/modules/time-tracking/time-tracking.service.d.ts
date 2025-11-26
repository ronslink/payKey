import { Repository } from 'typeorm';
import { TimeEntry } from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';
import { ClockInDto, ClockOutDto } from './dto/time-tracking.dto';
export declare class TimeTrackingService {
    private timeEntryRepository;
    private workerRepository;
    constructor(timeEntryRepository: Repository<TimeEntry>, workerRepository: Repository<Worker>);
    private calculateDistance;
    private validateGeofence;
    clockIn(userId: string, dto: ClockInDto): Promise<TimeEntry>;
    clockOut(userId: string, dto: ClockOutDto): Promise<TimeEntry>;
    getActiveEntry(userId: string, workerId: string): Promise<TimeEntry | null>;
    getTimeEntries(userId: string, workerId?: string, startDate?: Date, endDate?: Date): Promise<TimeEntry[]>;
    getWorkerTimeEntries(userId: string, workerId: string, startDate?: Date, endDate?: Date): Promise<TimeEntry[]>;
}
