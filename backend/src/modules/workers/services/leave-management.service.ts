import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { LeaveRequest, LeaveStatus } from '../entities/leave-request.entity';
import { Worker } from '../entities/worker.entity';
import {
  CreateLeaveRequestDto,
  ApproveLeaveRequestDto,
  UpdateLeaveRequestDto,
} from '../dto/create-leave-request.dto';

@Injectable()
export class LeaveManagementService {
  constructor(
    @InjectRepository(LeaveRequest)
    private leaveRequestRepository: Repository<LeaveRequest>,
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
  ) { }

  async createLeaveRequest(
    userId: string,
    workerId: string,
    createLeaveRequestDto: CreateLeaveRequestDto,
  ): Promise<LeaveRequest> {
    // Verify worker exists and belongs to user
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    const startDate = new Date(createLeaveRequestDto.startDate);
    const endDate = new Date(createLeaveRequestDto.endDate);

    // Validate dates
    if (startDate > endDate) {
      throw new BadRequestException('Start date must be before end date');
    }

    if (startDate < new Date()) {
      throw new BadRequestException(
        'Cannot create leave request for past dates',
      );
    }

    // Calculate total days
    const timeDiff = endDate.getTime() - startDate.getTime();
    const totalDays = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1;

    // Check for overlapping leave requests
    const overlappingLeave = await this.leaveRequestRepository.findOne({
      where: {
        workerId,
        status: LeaveStatus.PENDING,
        startDate: Between(startDate, endDate),
      },
    });

    if (overlappingLeave) {
      throw new BadRequestException(
        'Worker already has pending leave for these dates',
      );
    }

    // Calculate daily pay rate if not provided
    const dailyPayRate =
      createLeaveRequestDto.dailyPayRate || worker.salaryGross / 30; // Assuming 30 days in a month

    const leaveRequest = this.leaveRequestRepository.create({
      ...createLeaveRequestDto,
      workerId,
      requestedById: userId,
      startDate,
      endDate,
      totalDays,
      dailyPayRate,
      paidLeave: createLeaveRequestDto.paidLeave ?? true,
    });

    return this.leaveRequestRepository.save(leaveRequest);
  }

  async getLeaveRequestsForUser(userId: string): Promise<LeaveRequest[]> {
    const workers = await this.workersRepository.find({
      where: { userId },
    });

    const workerIds = workers.map((worker) => worker.id);

    return this.leaveRequestRepository.find({
      where: { workerId: workerIds as any },
      relations: ['worker', 'approvedBy', 'requestedBy'],
      order: { createdAt: 'DESC' },
    });
  }

  async getLeaveRequestsForWorker(
    userId: string,
    workerId: string,
  ): Promise<LeaveRequest[]> {
    // Verify worker belongs to user
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    return this.leaveRequestRepository.find({
      where: { workerId },
      relations: ['approvedBy', 'requestedBy'],
      order: { createdAt: 'DESC' },
    });
  }

  async approveLeaveRequest(
    userId: string,
    requestId: string,
    approveLeaveRequestDto: ApproveLeaveRequestDto,
  ): Promise<LeaveRequest> {
    const leaveRequest = await this.leaveRequestRepository.findOne({
      where: { id: requestId },
      relations: ['worker'],
    });

    if (!leaveRequest) {
      throw new NotFoundException('Leave request not found');
    }

    // Verify worker belongs to user
    const worker = await this.workersRepository.findOne({
      where: { id: leaveRequest.workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (approveLeaveRequestDto.approved) {
      leaveRequest.status = LeaveStatus.APPROVED;
      leaveRequest.approvedAt = new Date();
      leaveRequest.approvedById = userId;
    } else {
      leaveRequest.status = LeaveStatus.REJECTED;
      leaveRequest.rejectionReason =
        approveLeaveRequestDto.rejectionReason || '';
    }

    return this.leaveRequestRepository.save(leaveRequest);
  }

  async updateLeaveRequest(
    userId: string,
    requestId: string,
    updateLeaveRequestDto: UpdateLeaveRequestDto,
  ): Promise<LeaveRequest> {
    const leaveRequest = await this.leaveRequestRepository.findOne({
      where: { id: requestId },
      relations: ['worker'],
    });

    if (!leaveRequest) {
      throw new NotFoundException('Leave request not found');
    }

    // Verify worker belongs to user
    const worker = await this.workersRepository.findOne({
      where: { id: leaveRequest.workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    // Can only update pending requests
    if (leaveRequest.status !== LeaveStatus.PENDING) {
      throw new BadRequestException('Can only update pending leave requests');
    }

    const startDate = updateLeaveRequestDto.startDate
      ? new Date(updateLeaveRequestDto.startDate)
      : leaveRequest.startDate;

    const endDate = updateLeaveRequestDto.endDate
      ? new Date(updateLeaveRequestDto.endDate)
      : leaveRequest.endDate;

    if (startDate > endDate) {
      throw new BadRequestException('Start date must be before end date');
    }

    // Calculate total days
    const timeDiff = endDate.getTime() - startDate.getTime();
    const totalDays = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1;

    Object.assign(leaveRequest, {
      ...updateLeaveRequestDto,
      startDate,
      endDate,
      totalDays,
      dailyPayRate:
        updateLeaveRequestDto.dailyPayRate || leaveRequest.dailyPayRate,
    });

    return this.leaveRequestRepository.save(leaveRequest);
  }

  async cancelLeaveRequest(
    userId: string,
    requestId: string,
  ): Promise<LeaveRequest> {
    const leaveRequest = await this.leaveRequestRepository.findOne({
      where: { id: requestId },
      relations: ['worker'],
    });

    if (!leaveRequest) {
      throw new NotFoundException('Leave request not found');
    }

    // Verify worker belongs to user
    const worker = await this.workersRepository.findOne({
      where: { id: leaveRequest.workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (leaveRequest.status === LeaveStatus.CANCELLED) {
      throw new BadRequestException('Leave request is already cancelled');
    }

    leaveRequest.status = LeaveStatus.CANCELLED;
    return this.leaveRequestRepository.save(leaveRequest);
  }

  async getLeaveBalance(
    workerId: string,
    userId: string,
  ): Promise<{
    workerId: string;
    workerName: string;
    year: number;
    totalAnnualLeaves: number;
    usedAnnualLeaves: number;
    remainingAnnualLeaves: number;
    sickLeaves: number;
    pendingLeaves: number;
  }> {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    const currentYear = new Date().getFullYear();
    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear, 11, 31);

    // Get approved annual leaves for the year
    const annualLeaves = await this.leaveRequestRepository.find({
      where: {
        workerId,
        status: LeaveStatus.APPROVED,
        leaveType: 'ANNUAL' as any,
        startDate: Between(startOfYear, endOfYear),
      },
    });

    const usedAnnualLeaves = annualLeaves.reduce(
      (total, leave) => total + leave.totalDays,
      0,
    );

    // Standard annual leave entitlement per Kenya Employment Act 2007 (21 days per year)
    const totalAnnualLeaves = 21;

    // Get pending leaves
    const pendingLeaves = await this.leaveRequestRepository.count({
      where: {
        workerId,
        status: LeaveStatus.PENDING,
      },
    });

    return {
      workerId: worker.id,
      workerName: worker.name,
      year: currentYear,
      totalAnnualLeaves,
      usedAnnualLeaves,
      remainingAnnualLeaves: Math.max(0, totalAnnualLeaves - usedAnnualLeaves),
      sickLeaves: 0, // Can be expanded to track sick leaves
      pendingLeaves,
    };
  }
}
