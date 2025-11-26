import { Repository } from 'typeorm';
import { LeaveRequest } from '../entities/leave-request.entity';
import { Worker } from '../entities/worker.entity';
import { CreateLeaveRequestDto, ApproveLeaveRequestDto, UpdateLeaveRequestDto } from '../dto/create-leave-request.dto';
export declare class LeaveManagementService {
    private leaveRequestRepository;
    private workersRepository;
    constructor(leaveRequestRepository: Repository<LeaveRequest>, workersRepository: Repository<Worker>);
    createLeaveRequest(userId: string, workerId: string, createLeaveRequestDto: CreateLeaveRequestDto): Promise<LeaveRequest>;
    getLeaveRequestsForUser(userId: string): Promise<LeaveRequest[]>;
    getLeaveRequestsForWorker(userId: string, workerId: string): Promise<LeaveRequest[]>;
    approveLeaveRequest(userId: string, requestId: string, approveLeaveRequestDto: ApproveLeaveRequestDto): Promise<LeaveRequest>;
    updateLeaveRequest(userId: string, requestId: string, updateLeaveRequestDto: UpdateLeaveRequestDto): Promise<LeaveRequest>;
    cancelLeaveRequest(userId: string, requestId: string): Promise<LeaveRequest>;
    getLeaveBalance(workerId: string, userId: string): Promise<{
        workerId: string;
        workerName: string;
        year: number;
        totalAnnualLeaves: number;
        usedAnnualLeaves: number;
        remainingAnnualLeaves: number;
        sickLeaves: number;
        pendingLeaves: number;
    }>;
}
