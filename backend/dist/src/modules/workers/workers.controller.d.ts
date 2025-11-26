import { WorkersService } from './workers.service';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { CreateTerminationDto } from './dto/termination.dto';
import { CreateLeaveRequestDto, ApproveLeaveRequestDto, UpdateLeaveRequestDto } from './dto/create-leave-request.dto';
import { TerminationService } from './services/termination.service';
import { LeaveManagementService } from './services/leave-management.service';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import type { Response } from 'express';
export declare class WorkersController {
    private readonly workersService;
    private readonly terminationService;
    private readonly leaveManagementService;
    constructor(workersService: WorkersService, terminationService: TerminationService, leaveManagementService: LeaveManagementService);
    create(req: AuthenticatedRequest, createWorkerDto: CreateWorkerDto): Promise<import("./entities/worker.entity").Worker>;
    update(req: AuthenticatedRequest, id: string, updateWorkerDto: Partial<CreateWorkerDto>): Promise<import("./entities/worker.entity").Worker>;
    remove(req: AuthenticatedRequest, id: string): Promise<void>;
    findAll(req: AuthenticatedRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    findOne(req: AuthenticatedRequest, id: string): Promise<import("./entities/worker.entity").Worker | null>;
    calculateFinalPayment(req: AuthenticatedRequest, id: string, terminationDate: string): Promise<import("./dto/termination.dto").FinalPaymentCalculationDto>;
    terminateWorker(req: AuthenticatedRequest, id: string, dto: CreateTerminationDto): Promise<import("./entities/termination.entity").Termination>;
    getTerminationHistory(req: AuthenticatedRequest): Promise<import("./entities/termination.entity").Termination[]>;
    createLeaveRequest(req: AuthenticatedRequest, workerId: string, createLeaveRequestDto: CreateLeaveRequestDto): Promise<import("./entities/leave-request.entity").LeaveRequest>;
    getLeaveRequests(req: AuthenticatedRequest): Promise<import("./entities/leave-request.entity").LeaveRequest[]>;
    getWorkerLeaveRequests(req: AuthenticatedRequest, workerId: string): Promise<import("./entities/leave-request.entity").LeaveRequest[]>;
    approveLeaveRequest(req: AuthenticatedRequest, requestId: string, approveLeaveRequestDto: ApproveLeaveRequestDto): Promise<import("./entities/leave-request.entity").LeaveRequest>;
    updateLeaveRequest(req: AuthenticatedRequest, requestId: string, updateLeaveRequestDto: UpdateLeaveRequestDto): Promise<import("./entities/leave-request.entity").LeaveRequest>;
    cancelLeaveRequest(req: AuthenticatedRequest, requestId: string): Promise<import("./entities/leave-request.entity").LeaveRequest>;
    getLeaveBalance(req: AuthenticatedRequest, workerId: string): Promise<{
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
