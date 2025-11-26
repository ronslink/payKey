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
const transaction_entity_1 = require("./entities/transaction.entity");
const time_tracking_service_1 = require("../time-tracking/time-tracking.service");
const pay_period_entity_1 = require("../payroll/entities/pay-period.entity");
const tax_submission_entity_1 = require("../taxes/entities/tax-submission.entity");
const mpesa_service_1 = require("./mpesa.service");
let PayrollService = class PayrollService {
    workerRepository;
    transactionRepository;
    payPeriodRepository;
    taxSubmissionRepository;
    taxesService;
    timeTrackingService;
    mpesaService;
    constructor(workerRepository, transactionRepository, payPeriodRepository, taxSubmissionRepository, taxesService, timeTrackingService, mpesaService) {
        this.workerRepository = workerRepository;
        this.transactionRepository = transactionRepository;
        this.payPeriodRepository = payPeriodRepository;
        this.taxSubmissionRepository = taxSubmissionRepository;
        this.taxesService = taxesService;
        this.timeTrackingService = timeTrackingService;
        this.mpesaService = mpesaService;
    }
    async calculateWorkerPayroll(worker, startDate, endDate) {
        let grossSalary = Number(worker.salaryGross);
        if (worker.employmentType === worker_entity_1.EmploymentType.HOURLY) {
            if (!startDate || !endDate) {
                const now = new Date();
                startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
            }
            const timeEntries = await this.timeTrackingService.getWorkerTimeEntries(worker.userId, worker.id, startDate, endDate);
            const totalHours = timeEntries.reduce((sum, entry) => sum + (entry.totalHours || 0), 0);
            grossSalary = totalHours * Number(worker.hourlyRate || 0);
        }
        return await this.taxesService.calculatePayroll(worker.id, worker.name, grossSalary);
    }
    async calculatePayroll(workerIds, userId, startDate, endDate) {
        const calculations = [];
        for (const workerId of workerIds) {
            const worker = await this.workerRepository.findOne({
                where: { id: workerId, userId },
            });
            if (!worker) {
                throw new common_1.NotFoundException(`Worker ${workerId} not found`);
            }
            const calculation = await this.calculateWorkerPayroll(worker, startDate, endDate);
            calculations.push(calculation);
        }
        return calculations;
    }
    async createPayPeriod(userId, year, month) {
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0);
        const name = startDate.toLocaleString('default', {
            month: 'long',
            year: 'numeric',
        });
        const payPeriod = this.payPeriodRepository.create({
            userId,
            name,
            startDate,
            endDate,
            status: pay_period_entity_1.PayPeriodStatus.ACTIVE,
        });
        return this.payPeriodRepository.save(payPeriod);
    }
    async processPayroll(userId, workerIds, payPeriodId) {
        const payPeriod = await this.payPeriodRepository.findOne({
            where: { id: payPeriodId, userId },
        });
        if (!payPeriod) {
            throw new common_1.NotFoundException('Pay Period not found');
        }
        if (payPeriod.status !== pay_period_entity_1.PayPeriodStatus.ACTIVE) {
            throw new common_1.BadRequestException('Pay Period is not OPEN');
        }
        payPeriod.status = pay_period_entity_1.PayPeriodStatus.PROCESSING;
        await this.payPeriodRepository.save(payPeriod);
        const results = [];
        let successCount = 0;
        let failureCount = 0;
        let totalGross = 0;
        let totalNet = 0;
        let totalPaye = 0;
        let totalNssf = 0;
        let totalNhif = 0;
        let totalHousingLevy = 0;
        for (const workerId of workerIds) {
            try {
                const worker = await this.workerRepository.findOne({
                    where: { id: workerId, userId },
                });
                if (!worker) {
                    results.push({
                        workerId,
                        workerName: 'Unknown',
                        success: false,
                        error: 'Worker not found',
                    });
                    failureCount++;
                    continue;
                }
                const payroll = await this.calculateWorkerPayroll(worker, payPeriod.startDate, payPeriod.endDate);
                const transaction = this.transactionRepository.create({
                    userId,
                    workerId: worker.id,
                    amount: payroll.netPay,
                    currency: 'KES',
                    type: transaction_entity_1.TransactionType.SALARY_PAYOUT,
                    status: transaction_entity_1.TransactionStatus.PENDING,
                    payPeriod,
                    metadata: {
                        grossSalary: payroll.grossSalary,
                        taxBreakdown: payroll.taxBreakdown,
                        netPay: payroll.netPay,
                        workerName: payroll.workerName,
                    },
                });
                const savedTransaction = await this.transactionRepository.save(transaction);
                const b2cResult = await this.mpesaService.sendB2C(savedTransaction.id, worker.phoneNumber, payroll.netPay, `Salary for ${payPeriod.name}`);
                if (b2cResult.error) {
                    results.push({
                        workerId: worker.id,
                        workerName: worker.name,
                        success: false,
                        error: b2cResult.error,
                    });
                    failureCount++;
                    continue;
                }
                totalPaye += Number(payroll.taxBreakdown.paye);
                totalNssf += Number(payroll.taxBreakdown.nssf);
                totalNhif += Number(payroll.taxBreakdown.nhif);
                totalHousingLevy += Number(payroll.taxBreakdown.housingLevy);
                results.push({
                    workerId: worker.id,
                    workerName: worker.name,
                    success: true,
                    grossSalary: payroll.grossSalary,
                    netPay: payroll.netPay,
                    transactionId: savedTransaction.id,
                });
                successCount++;
                totalGross += payroll.grossSalary;
                totalNet += payroll.netPay;
            }
            catch (error) {
                results.push({
                    workerId,
                    workerName: 'Unknown',
                    success: false,
                    error: error.message || 'Processing failed',
                });
                failureCount++;
            }
        }
        const taxSubmission = this.taxSubmissionRepository.create({
            userId,
            payPeriod,
            totalPaye,
            totalNssf,
            totalNhif,
            totalHousingLevy,
            status: tax_submission_entity_1.TaxSubmissionStatus.PENDING,
        });
        await this.taxSubmissionRepository.save(taxSubmission);
        payPeriod.status = pay_period_entity_1.PayPeriodStatus.CLOSED;
        await this.payPeriodRepository.save(payPeriod);
        return {
            payPeriodId: payPeriod.id,
            totalWorkers: workerIds.length,
            successCount,
            failureCount,
            totalGross,
            totalNet,
            taxSubmissionId: taxSubmission.id,
            results,
            processedAt: new Date(),
        };
    }
};
exports.PayrollService = PayrollService;
exports.PayrollService = PayrollService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __param(1, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __param(2, (0, typeorm_1.InjectRepository)(pay_period_entity_1.PayPeriod)),
    __param(3, (0, typeorm_1.InjectRepository)(tax_submission_entity_1.TaxSubmission)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        taxes_service_1.TaxesService,
        time_tracking_service_1.TimeTrackingService,
        mpesa_service_1.MpesaService])
], PayrollService);
//# sourceMappingURL=payroll.service.js.map