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
var PayrollPaymentService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PayrollPaymentService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const transaction_entity_1 = require("./entities/transaction.entity");
const mpesa_service_1 = require("./mpesa.service");
const payroll_record_entity_1 = require("../payroll/entities/payroll-record.entity");
let PayrollPaymentService = PayrollPaymentService_1 = class PayrollPaymentService {
    transactionRepository;
    mpesaService;
    payrollRecordRepository;
    logger = new common_1.Logger(PayrollPaymentService_1.name);
    constructor(transactionRepository, mpesaService, payrollRecordRepository) {
        this.transactionRepository = transactionRepository;
        this.mpesaService = mpesaService;
        this.payrollRecordRepository = payrollRecordRepository;
    }
    async processPayouts(payrollRecords) {
        const results = [];
        let successCount = 0;
        let failureCount = 0;
        for (const record of payrollRecords) {
            try {
                if (record.status !== payroll_record_entity_1.PayrollStatus.FINALIZED) {
                    throw new Error(`Payroll record ${record.id} is not finalized`);
                }
                const transaction = this.transactionRepository.create({
                    userId: record.userId,
                    workerId: record.workerId,
                    amount: Number(record.netSalary),
                    currency: 'KES',
                    type: transaction_entity_1.TransactionType.SALARY_PAYOUT,
                    status: transaction_entity_1.TransactionStatus.PENDING,
                    metadata: {
                        payrollRecordId: record.id,
                        workerName: record.worker.name,
                    },
                });
                const savedTransaction = await this.transactionRepository.save(transaction);
                const b2cResult = await this.mpesaService.sendB2C(savedTransaction.id, record.worker.phoneNumber, Number(record.netSalary), `Salary Payment`);
                if (b2cResult.error) {
                    results.push({
                        workerId: record.workerId,
                        workerName: record.worker.name,
                        success: false,
                        error: b2cResult.error,
                    });
                    record.paymentStatus = 'failed';
                    await this.payrollRecordRepository.save(record);
                    failureCount++;
                    continue;
                }
                record.paymentStatus = 'processing';
                record.paymentDate = new Date();
                await this.payrollRecordRepository.save(record);
                results.push({
                    workerId: record.workerId,
                    workerName: record.worker.name,
                    success: true,
                    transactionId: savedTransaction.id,
                });
                successCount++;
            }
            catch (error) {
                this.logger.error(`Failed to process payout for record ${record.id}`, error);
                results.push({
                    workerId: record.workerId,
                    workerName: record.worker?.name || 'Unknown',
                    success: false,
                    error: error.message || 'Processing failed',
                });
                failureCount++;
            }
        }
        return {
            successCount,
            failureCount,
            results,
        };
    }
};
exports.PayrollPaymentService = PayrollPaymentService;
exports.PayrollPaymentService = PayrollPaymentService = PayrollPaymentService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __param(2, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        mpesa_service_1.MpesaService,
        typeorm_2.Repository])
], PayrollPaymentService);
//# sourceMappingURL=payroll-payment.service.js.map