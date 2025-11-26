"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LeaveManagementService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const leave_request_entity_1 = require("../entities/leave-request.entity");
const worker_entity_1 = require("../entities/worker.entity");
let LeaveManagementService = class LeaveManagementService {
    leaveRequestRepository;
    workersRepository;
    constructor(leaveRequestRepository, workersRepository) {
        this.leaveRequestRepository = leaveRequestRepository;
        this.workersRepository = workersRepository;
    }
    async createLeaveRequest(userId, workerId, createLeaveRequestDto) {
        const worker = await this.workersRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        const startDate = new Date(createLeaveRequestDto.startDate);
        const endDate = new Date(createLeaveRequestDto.endDate);
        if (startDate > endDate) {
            throw new common_1.BadRequestException('Start date must be before end date');
        }
        if (startDate < new Date()) {
            throw new common_1.BadRequestException('Cannot create leave request for past dates');
        }
        const timeDiff = endDate.getTime() - startDate.getTime();
        const totalDays = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1;
        const overlappingLeave = await this.leaveRequestRepository.findOne({
            where: {
                workerId,
                status: leave_request_entity_1.LeaveStatus.PENDING,
                startDate: (0, typeorm_2.Between)(startDate, endDate),
            },
        });
        if (overlappingLeave) {
            throw new common_1.BadRequestException('Worker already has pending leave for these dates');
        }
        const dailyPayRate = createLeaveRequestDto.dailyPayRate || worker.salaryGross / 30;
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
    async getLeaveRequestsForUser(userId) {
        const workers = await this.workersRepository.find({
            where: { userId },
        });
        const workerIds = workers.map((worker) => worker.id);
        return this.leaveRequestRepository.find({
            where: { workerId: workerIds },
            relations: ['worker', 'approvedBy', 'requestedBy'],
            order: { createdAt: 'DESC' },
        });
    }
    async getLeaveRequestsForWorker(userId, workerId) {
        const worker = await this.workersRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        return this.leaveRequestRepository.find({
            where: { workerId },
            relations: ['approvedBy', 'requestedBy'],
            order: { createdAt: 'DESC' },
        });
    }
    async approveLeaveRequest(userId, requestId, approveLeaveRequestDto) {
        const leaveRequest = await this.leaveRequestRepository.findOne({
            where: { id: requestId },
            relations: ['worker'],
        });
        if (!leaveRequest) {
            throw new common_1.NotFoundException('Leave request not found');
        }
        const worker = await this.workersRepository.findOne({
            where: { id: leaveRequest.workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        if (approveLeaveRequestDto.approved) {
            leaveRequest.status = leave_request_entity_1.LeaveStatus.APPROVED;
            leaveRequest.approvedAt = new Date();
            leaveRequest.approvedById = userId;
        }
        else {
            leaveRequest.status = leave_request_entity_1.LeaveStatus.REJECTED;
            leaveRequest.rejectionReason =
                approveLeaveRequestDto.rejectionReason || '';
        }
        return this.leaveRequestRepository.save(leaveRequest);
    }
    async updateLeaveRequest(userId, requestId, updateLeaveRequestDto) {
        const leaveRequest = await this.leaveRequestRepository.findOne({
            where: { id: requestId },
            relations: ['worker'],
        });
        if (!leaveRequest) {
            throw new common_1.NotFoundException('Leave request not found');
        }
        const worker = await this.workersRepository.findOne({
            where: { id: leaveRequest.workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        if (leaveRequest.status !== leave_request_entity_1.LeaveStatus.PENDING) {
            throw new common_1.BadRequestException('Can only update pending leave requests');
        }
        const startDate = updateLeaveRequestDto.startDate
            ? new Date(updateLeaveRequestDto.startDate)
            : leaveRequest.startDate;
        const endDate = updateLeaveRequestDto.endDate
            ? new Date(updateLeaveRequestDto.endDate)
            : leaveRequest.endDate;
        if (startDate > endDate) {
            throw new common_1.BadRequestException('Start date must be before end date');
        }
        const timeDiff = endDate.getTime() - startDate.getTime();
        const totalDays = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1;
        Object.assign(leaveRequest, {
            ...updateLeaveRequestDto,
            startDate,
            endDate,
            totalDays,
            dailyPayRate: updateLeaveRequestDto.dailyPayRate || leaveRequest.dailyPayRate,
        });
        return this.leaveRequestRepository.save(leaveRequest);
    }
    async cancelLeaveRequest(userId, requestId) {
        const leaveRequest = await this.leaveRequestRepository.findOne({
            where: { id: requestId },
            relations: ['worker'],
        });
        if (!leaveRequest) {
            throw new common_1.NotFoundException('Leave request not found');
        }
        const worker = await this.workersRepository.findOne({
            where: { id: leaveRequest.workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        if (leaveRequest.status === leave_request_entity_1.LeaveStatus.CANCELLED) {
            throw new common_1.BadRequestException('Leave request is already cancelled');
        }
        leaveRequest.status = leave_request_entity_1.LeaveStatus.CANCELLED;
        return this.leaveRequestRepository.save(leaveRequest);
    }
    async getLeaveBalance(workerId, userId) {
        const worker = await this.workersRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        const currentYear = new Date().getFullYear();
        const startOfYear = new Date(currentYear, 0, 1);
        const endOfYear = new Date(currentYear, 11, 31);
        const annualLeaves = await this.leaveRequestRepository.find({
            where: {
                workerId,
                status: leave_request_entity_1.LeaveStatus.APPROVED,
                leaveType: 'ANNUAL',
                startDate: (0, typeorm_2.Between)(startOfYear, endOfYear),
            },
        });
        const usedAnnualLeaves = annualLeaves.reduce((total, leave) => total + leave.totalDays, 0);
        const totalAnnualLeaves = 15;
        const pendingLeaves = await this.leaveRequestRepository.count({
            where: {
                workerId,
                status: leave_request_entity_1.LeaveStatus.PENDING,
            },
        });
        return {
            workerId: worker.id,
            workerName: worker.name,
            year: currentYear,
            totalAnnualLeaves,
            usedAnnualLeaves,
            remainingAnnualLeaves: Math.max(0, totalAnnualLeaves - usedAnnualLeaves),
            sickLeaves: 0,
            pendingLeaves,
        };
    }
};
exports.LeaveManagementService = LeaveManagementService;
exports.LeaveManagementService = LeaveManagementService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(leave_request_entity_1.LeaveRequest)),
    __param(1, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], LeaveManagementService);
//# sourceMappingURL=leave-management.service.js.map