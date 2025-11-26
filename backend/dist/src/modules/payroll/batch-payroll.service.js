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
exports.BatchPayrollService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const worker_entity_1 = require("../workers/entities/worker.entity");
const transaction_entity_1 = require("../payments/entities/transaction.entity");
const payroll_service_1 = require("./payroll.service");
const mpesa_service_1 = require("../payments/mpesa.service");
const taxes_service_1 = require("../taxes/taxes.service");
const tax_payments_service_1 = require("../tax-payments/services/tax-payments.service");
let BatchPayrollService = class BatchPayrollService {
    workersRepository;
    transactionsRepository;
    payrollService;
    mpesaService;
    taxesService;
    taxPaymentsService;
    constructor(workersRepository, transactionsRepository, payrollService, mpesaService, taxesService, taxPaymentsService) {
        this.workersRepository = workersRepository;
        this.transactionsRepository = transactionsRepository;
        this.payrollService = payrollService;
        this.mpesaService = mpesaService;
        this.taxesService = taxesService;
        this.taxPaymentsService = taxPaymentsService;
    }
    async processBatchPayroll(userId, batchRequest) {
        const allWorkers = await this.workersRepository.find({
            where: { userId, isActive: true },
        });
        const selectedWorkers = allWorkers.filter((worker) => batchRequest.workerIds.includes(worker.id));
        if (selectedWorkers.length !== batchRequest.workerIds.length) {
            throw new common_1.BadRequestException('Some workers not found or not active');
        }
        const batchId = `batch_${Date.now()}_${userId}`;
        const results = [];
        for (const worker of selectedWorkers) {
            try {
                const taxBreakdown = await this.taxesService.calculateTaxes(worker.salaryGross);
                const netPay = worker.salaryGross - taxBreakdown.totalDeductions;
                const transaction = this.transactionsRepository.create({
                    userId,
                    workerId: worker.id,
                    amount: netPay,
                    type: 'SALARY_PAYOUT',
                    status: 'PENDING',
                    metadata: {
                        grossSalary: worker.salaryGross,
                        taxBreakdown,
                        batchId,
                        processDate: batchRequest.processDate.toISOString(),
                    },
                });
                const savedTransaction = await this.transactionsRepository.save(transaction);
                const paymentResult = await this.mpesaService.sendB2C(savedTransaction.id, worker.phoneNumber, netPay, `Salary Payment - ${batchId}`);
                let paymentStatus = 'PENDING';
                let errorMessage;
                if (paymentResult.error) {
                    paymentStatus = 'FAILED';
                    errorMessage = paymentResult.error;
                }
                else {
                    paymentStatus = 'PENDING';
                }
                results.push({
                    workerId: worker.id,
                    workerName: worker.name,
                    grossSalary: worker.salaryGross,
                    netPay: Math.round(netPay * 100) / 100,
                    paymentStatus,
                    transactionId: savedTransaction.id,
                    errorMessage,
                });
            }
            catch (error) {
                results.push({
                    workerId: worker.id,
                    workerName: worker.name,
                    grossSalary: worker.salaryGross,
                    netPay: 0,
                    paymentStatus: 'FAILED',
                    errorMessage: error.message,
                });
            }
        }
        const successfulPayments = results.filter((r) => r.paymentStatus === 'SUCCESS').length;
        const failedPayments = results.filter((r) => r.paymentStatus === 'FAILED').length;
        if (successfulPayments > 0) {
            const processDate = batchRequest.processDate;
            await this.accumulateTaxPayments(userId, batchId, processDate.getFullYear(), processDate.getMonth() + 1);
        }
        return {
            batchId,
            totalWorkers: selectedWorkers.length,
            successfulPayments,
            failedPayments,
            results,
        };
    }
    async getBatchPayrollStatus(batchId, userId) {
        const transactions = await this.transactionsRepository.find({
            where: {
                userId,
                metadata: { batchId },
            },
            relations: ['workerId'],
        });
        return {
            batchId,
            totalTransactions: transactions.length,
            pendingTransactions: transactions.filter((t) => t.status === 'PENDING')
                .length,
            successfulTransactions: transactions.filter((t) => t.status === 'SUCCESS')
                .length,
            failedTransactions: transactions.filter((t) => t.status === 'FAILED')
                .length,
            transactions: transactions.map((t) => ({
                transactionId: t.id,
                workerId: t.workerId,
                amount: t.amount,
                status: t.status,
                createdAt: t.createdAt,
                providerRef: t.providerRef,
            })),
        };
    }
    async getUserPayrollHistory(userId, limit = 10) {
        const transactions = await this.transactionsRepository.find({
            where: { userId, type: 'SALARY_PAYOUT' },
            order: { createdAt: 'DESC' },
            take: limit,
        });
        return transactions.map((transaction) => ({
            transactionId: transaction.id,
            workerId: transaction.workerId,
            amount: transaction.amount,
            status: transaction.status,
            createdAt: transaction.createdAt,
            metadata: transaction.metadata,
        }));
    }
    async accumulateTaxPayments(userId, batchId, year, month) {
        try {
            const transactions = await this.transactionsRepository.find({
                where: {
                    userId,
                    metadata: { batchId },
                    status: 'SUCCESS',
                },
            });
            if (transactions.length === 0) {
                return;
            }
            let totalNssf = 0;
            let totalShif = 0;
            let totalHousingLevy = 0;
            let totalPaye = 0;
            for (const transaction of transactions) {
                const metadata = transaction.metadata;
                if (metadata?.taxBreakdown) {
                    totalNssf += metadata.taxBreakdown.nssf || 0;
                    totalShif += metadata.taxBreakdown.nhif || 0;
                    totalHousingLevy += metadata.taxBreakdown.housingLevy || 0;
                    totalPaye += metadata.taxBreakdown.paye || 0;
                }
            }
            console.log(`Tax obligations accumulated for ${year}-${month}:`);
            console.log(`NSSF: ${totalNssf}`);
            console.log(`SHIF: ${totalShif}`);
            console.log(`Housing Levy: ${totalHousingLevy}`);
            console.log(`PAYE: ${totalPaye}`);
            console.log(`Total: ${totalNssf + totalShif + totalHousingLevy + totalPaye}`);
        }
        catch (error) {
            console.error('Error accumulating tax payments:', error);
        }
    }
};
exports.BatchPayrollService = BatchPayrollService;
exports.BatchPayrollService = BatchPayrollService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(worker_entity_1.Worker)),
    __param(1, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        payroll_service_1.PayrollService,
        mpesa_service_1.MpesaService,
        taxes_service_1.TaxesService,
        tax_payments_service_1.TaxPaymentsService])
], BatchPayrollService);
//# sourceMappingURL=batch-payroll.service.js.map