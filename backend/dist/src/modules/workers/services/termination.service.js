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
exports.TerminationService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const worker_entity_1 = require("../entities/worker.entity");
const termination_entity_1 = require("../entities/termination.entity");
const taxes_service_1 = require("../../taxes/taxes.service");
let TerminationService = class TerminationService {
    workerRepository;
    terminationRepository;
    taxesService;
    constructor(workerRepository, terminationRepository, taxesService) {
        this.workerRepository = workerRepository;
        this.terminationRepository = terminationRepository;
        this.taxesService = taxesService;
    }
    async calculateFinalPayment(workerId, userId, terminationDate) {
        const worker = await this.workerRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        if (!worker.isActive) {
            throw new common_1.BadRequestException('Worker is already terminated');
        }
        const grossSalary = Number(worker.salaryGross);
        const termDate = new Date(terminationDate);
        const year = termDate.getFullYear();
        const month = termDate.getMonth();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysWorked = termDate.getDate();
        const dailyRate = grossSalary / daysInMonth;
        const proratedSalary = dailyRate * daysWorked;
        const unusedLeaveDays = worker.leaveBalance || 0;
        const leavePayoutRate = dailyRate;
        const unusedLeavePayout = unusedLeaveDays * leavePayoutRate;
        const severancePay = 0;
        const totalGross = proratedSalary + unusedLeavePayout + severancePay;
        const taxCalculation = await this.taxesService.calculatePayroll(worker.id, worker.name, totalGross);
        return {
            proratedSalary: Math.round(proratedSalary * 100) / 100,
            unusedLeavePayout: Math.round(unusedLeavePayout * 100) / 100,
            severancePay: Math.round(severancePay * 100) / 100,
            totalGross: Math.round(totalGross * 100) / 100,
            taxDeductions: {
                nssf: taxCalculation.taxBreakdown.nssf,
                nhif: taxCalculation.taxBreakdown.nhif,
                housingLevy: taxCalculation.taxBreakdown.housingLevy,
                paye: taxCalculation.taxBreakdown.paye,
                total: taxCalculation.taxBreakdown.totalDeductions,
            },
            totalNet: taxCalculation.netPay,
            breakdown: {
                daysWorked,
                totalDaysInMonth: daysInMonth,
                dailyRate: Math.round(dailyRate * 100) / 100,
                unusedLeaveDays,
                leavePayoutRate: Math.round(leavePayoutRate * 100) / 100,
            },
        };
    }
    async terminateWorker(workerId, userId, dto) {
        const worker = await this.workerRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new common_1.NotFoundException('Worker not found');
        }
        if (!worker.isActive) {
            throw new common_1.BadRequestException('Worker is already terminated');
        }
        const terminationDate = new Date(dto.terminationDate);
        const finalPayment = await this.calculateFinalPayment(workerId, userId, terminationDate);
        const severancePay = dto.severancePay ?? 0;
        const outstandingPayments = dto.outstandingPayments ?? 0;
        const totalGross = finalPayment.proratedSalary +
            finalPayment.unusedLeavePayout +
            severancePay +
            outstandingPayments;
        const taxCalculation = await this.taxesService.calculatePayroll(worker.id, worker.name, totalGross);
        const termination = this.terminationRepository.create({
            workerId,
            userId,
            reason: dto.reason,
            terminationDate,
            lastWorkingDate: dto.lastWorkingDate
                ? new Date(dto.lastWorkingDate)
                : terminationDate,
            noticePeriodDays: dto.noticePeriodDays || 0,
            notes: dto.notes,
            proratedSalary: finalPayment.proratedSalary,
            unusedLeavePayout: finalPayment.unusedLeavePayout,
            severancePay,
            totalFinalPayment: taxCalculation.netPay,
            paymentBreakdown: {
                ...finalPayment.breakdown,
                severancePay,
                outstandingPayments,
            },
        });
        const savedTermination = await this.terminationRepository.save(termination);
        worker.isActive = false;
        worker.terminatedAt = terminationDate;
        worker.terminationId = savedTermination.id;
        await this.workerRepository.save(worker);
        return savedTermination;
    }
    async getTerminationHistory(userId) {
        return this.terminationRepository.find({
            where: { userId },
            relations: ['worker'],
            order: { createdAt: 'DESC' },
        });
    }
    async getTermination(id, userId) {
        const termination = await this.terminationRepository.findOne({
            where: { id, userId },
            relations: ['worker'],
        });
        if (!termination) {
            throw new common_1.NotFoundException('Termination record not found');
        }
        return termination;
    }
};
exports.TerminationService = TerminationService;
exports.TerminationService = TerminationService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __param(1, (0, typeorm_1.InjectRepository)(termination_entity_1.Termination)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        taxes_service_1.TaxesService])
], TerminationService);
//# sourceMappingURL=termination.service.js.map