import { TimeTrackingService } from './time-tracking.service';
import { ClockInDto, ClockOutDto } from './dto/time-tracking.dto';
export declare class TimeTrackingController {
    private readonly timeTrackingService;
    constructor(timeTrackingService: TimeTrackingService);
    clockIn(req: any, dto: ClockInDto): Promise<import("./entities/time-entry.entity").TimeEntry>;
    clockOut(req: any, dto: ClockOutDto): Promise<import("./entities/time-entry.entity").TimeEntry>;
    getActiveEntry(req: any, workerId: string): Promise<import("./entities/time-entry.entity").TimeEntry | null>;
    getTimeEntries(req: any, workerId?: string, startDate?: string, endDate?: string): Promise<import("./entities/time-entry.entity").TimeEntry[]>;
}
