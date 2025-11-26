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
exports.PayrollService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const worker_entity_1 = require("../workers/entities/worker.entity");
const taxes_service_1 = require("../taxes/taxes.service");
const payroll_record_entity_1 = require("./entities/payroll-record.entity");
const payroll_payment_service_1 = require("../payments/payroll-payment.service");
let PayrollService = class PayrollService {
    workersRepository;
    payrollRepository;
    taxesService;
    payrollPaymentService;
    constructor(workersRepository, payrollRepository, taxesService, payrollPaymentService) {
        this.workersRepository = workersRepository;
        this.payrollRepository = payrollRepository;
        this.taxesService = taxesService;
        this.payrollPaymentService = payrollPaymentService;
    }
    async calculatePayrollForUser(userId) {
        const workers = await this.workersRepository.find({
            where: { userId, isActive: true },
        });
        const payrollItems = await Promise.all(workers.map(async (worker) => {
            const taxBreakdown = await this.taxesService.calculateTaxes(worker.salaryGross);
            const netPay = worker.salaryGross - taxBreakdown.totalDeductions;
            return {
                workerId: worker.id,
                workerName: worker.name,
                grossSalary: worker.salaryGross,
                taxBreakdown,
                netPay: Math.round(netPay * 100) / 100,
                phoneNumber: worker.phoneNumber,
            };
        }));
        const totalGross = payrollItems.reduce((sum, item) => sum + item.grossSalary, 0);
        const totalDeductions = payrollItems.reduce((sum, item) => sum + item.taxBreakdown.totalDeductions, 0);
        const totalNetPay = payrollItems.reduce((sum, item) => sum + item.netPay, 0);
        return {
            payrollItems,
            summary: {
                totalGross: Math.round(totalGross * 100) / 100,
                totalDeductions: Math.round(totalDeductions * 100) / 100,
                totalNetPay: Math.round(totalNetPay * 100) / 100,
                workerCount: workers.length,
            },
        };
    }
    async calculateSingleWorkerPayroll(workerId, userId) {
        const worker = await this.workersRepository.findOne({
            where: { id: workerId, userId },
        });
        if (!worker) {
            throw new Error('Worker not found');
        }
        const taxBreakdown = await this.taxesService.calculateTaxes(worker.salaryGross);
        const netPay = worker.salaryGross - taxBreakdown.totalDeductions;
        return {
            worker,
            payrollCalculation: {
                grossSalary: worker.salaryGross,
                taxBreakdown,
                netPay: Math.round(netPay * 100) / 100,
            },
        };
    }
    async saveDraftPayroll(userId, payPeriodId, items) {
        const periodStart = new Date();
        const periodEnd = new Date();
        const savedRecords = await Promise.all(items.map(async (item) => {
            const totalEarnings = item.grossSalary + (item.bonuses || 0) + (item.otherEarnings || 0);
            const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);
            const totalDeductions = taxBreakdown.totalDeductions + (item.otherDeductions || 0);
            const netPay = totalEarnings - totalDeductions;
            let record = await this.payrollRepository.findOne({
                where: {
                    userId,
                    payPeriodId,
                    workerId: item.workerId,
                    status: payroll_record_entity_1.PayrollStatus.DRAFT,
                },
            });
            if (!record) {
                record = new payroll_record_entity_1.PayrollRecord();
                record.userId = userId;
                record.payPeriodId = payPeriodId;
                record.workerId = item.workerId;
                record.status = payroll_record_entity_1.PayrollStatus.DRAFT;
                record.periodStart = periodStart;
                record.periodEnd = periodEnd;
            }
            record.grossSalary = item.grossSalary;
            record.bonuses = item.bonuses || 0;
            record.otherEarnings = item.otherEarnings || 0;
            record.otherDeductions = item.otherDeductions || 0;
            record.taxAmount = taxBreakdown.paye;
            record.netSalary = netPay;
            record.taxBreakdown = taxBreakdown;
            record.deductions = {
                ...taxBreakdown,
                otherDeductions: item.otherDeductions || 0,
            };
            return this.payrollRepository.save(record);
        }));
        return savedRecords;
    }
    async updateDraftPayrollItem(userId, recordId, updates) {
        const record = await this.payrollRepository.findOne({
            where: { id: recordId, userId, status: payroll_record_entity_1.PayrollStatus.DRAFT },
        });
        if (!record) {
            throw new Error('Draft payroll record not found');
        }
        if (updates.grossSalary !== undefined)
            record.grossSalary = updates.grossSalary;
        if (updates.bonuses !== undefined)
            record.bonuses = updates.bonuses;
        if (updates.otherEarnings !== undefined)
            record.otherEarnings = updates.otherEarnings;
        if (updates.otherDeductions !== undefined)
            record.otherDeductions = updates.otherDeductions;
        const totalEarnings = Number(record.grossSalary) +
            Number(record.bonuses) +
            Number(record.otherEarnings);
        const taxBreakdown = await this.taxesService.calculateTaxes(totalEarnings);
        const totalDeductions = taxBreakdown.totalDeductions + Number(record.otherDeductions);
        const netPay = totalEarnings - totalDeductions;
        record.taxAmount = taxBreakdown.paye;
        record.netSalary = netPay;
        record.taxBreakdown = taxBreakdown;
        record.deductions = {
            ...taxBreakdown,
            otherDeductions: record.otherDeductions,
        };
        return this.payrollRepository.save(record);
    }
    async getDraftPayroll(userId, payPeriodId) {
        const records = await this.payrollRepository.find({
            where: {
                userId,
                payPeriodId,
                status: payroll_record_entity_1.PayrollStatus.DRAFT,
            },
            relations: ['worker'],
        });
        return records.map((record) => ({
            id: record.id,
            workerId: record.workerId,
            workerName: record.worker.name,
            grossSalary: Number(record.grossSalary),
            bonuses: Number(record.bonuses),
            otherEarnings: Number(record.otherEarnings),
            otherDeductions: Number(record.otherDeductions),
            taxBreakdown: record.taxBreakdown,
            netPay: Number(record.netSalary),
            status: record.status,
        }));
    }
    async finalizePayroll(userId, payPeriodId) {
        const records = await this.payrollRepository.find({
            where: {
                userId,
                payPeriodId,
                status: payroll_record_entity_1.PayrollStatus.DRAFT,
            },
            relations: ['worker'],
        });
        if (records.length === 0) {
            throw new Error('No draft payroll records found for this period');
        }
        const finalizedDate = new Date();
        const updatedRecords = await Promise.all(records.map(async (record) => {
            record.status = payroll_record_entity_1.PayrollStatus.FINALIZED;
            record.finalizedAt = finalizedDate;
            return this.payrollRepository.save(record);
        }));
        const payoutResults = await this.payrollPaymentService.processPayouts(updatedRecords);
        try {
            await this.taxesService.generateTaxSubmission(payPeriodId, userId);
        }
        catch (error) {
            console.error('Failed to generate tax submission:', error);
        }
        return {
            finalizedRecords: updatedRecords,
            payoutResults,
        };
    }
};
exports.PayrollService = PayrollService;
exports.PayrollService = PayrollService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __param(1, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        taxes_service_1.TaxesService,
        payroll_payment_service_1.PayrollPaymentService])
], PayrollService);
//# sourceMappingURL=payroll.service.js.map