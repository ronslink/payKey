import { User } from '../../users/entities/user.entity';
export declare enum TimeEntryStatus {
    IN_PROGRESS = "IN_PROGRESS",
    COMPLETED = "COMPLETED"
}
export declare class TimeEntry {
    id: string;
    user: User;
    workerId: string;
    userId: string;
    propertyId: string;
    clockInTime: Date;
    clockOutTime: Date;
    clockInLatitude: number;
    clockInLongitude: number;
    clockOutLatitude: number;
    clockOutLongitude: number;
    totalHours: number;
    status: TimeEntryStatus;
    notes: string;
    createdAt: Date;
}
