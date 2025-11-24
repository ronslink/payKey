import { Worker } from './worker.entity';
import { User } from '../../users/entities/user.entity';
export declare enum LeaveType {
    ANNUAL = "ANNUAL",
    SICK = "SICK",
    MATERNITY = "MATERNITY",
    PATERNITY = "PATERNITY",
    EMERGENCY = "EMERGENCY",
    UNPAID = "UNPAID"
}
export declare enum LeaveStatus {
    PENDING = "PENDING",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED",
    CANCELLED = "CANCELLED"
}
export declare class LeaveRequest {
    id: string;
    workerId: string;
    worker: Worker;
    requestedById: string;
    requestedBy: User;
    leaveType: LeaveType;
    startDate: Date;
    endDate: Date;
    totalDays: number;
    reason: string;
    status: LeaveStatus;
    approvedById: string;
    approvedBy: User;
    approvedAt: Date;
    rejectionReason: string;
    dailyPayRate: number;
    paidLeave: boolean;
    emergencyContact: string;
    emergencyPhone: string;
    createdAt: Date;
    updatedAt: Date;
}
