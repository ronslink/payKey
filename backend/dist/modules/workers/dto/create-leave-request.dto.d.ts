import { LeaveType } from '../entities/leave-request.entity';
export declare class CreateLeaveRequestDto {
    leaveType: LeaveType;
    startDate: string;
    endDate: string;
    reason?: string;
    paidLeave?: boolean;
    dailyPayRate?: number;
    emergencyContact?: string;
    emergencyPhone?: string;
}
export declare class ApproveLeaveRequestDto {
    approved: boolean;
    rejectionReason?: string;
}
export declare class UpdateLeaveRequestDto {
    leaveType?: LeaveType;
    startDate?: string;
    endDate?: string;
    reason?: string;
    paidLeave?: boolean;
    dailyPayRate?: number;
    emergencyContact?: string;
    emergencyPhone?: string;
}
