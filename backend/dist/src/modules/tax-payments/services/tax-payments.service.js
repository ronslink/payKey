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
exports.TaxPaymentsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const tax_payment_entity_1 = require("../entities/tax-payment.entity");
const tax_config_service_1 = require("../../tax-config/services/tax-config.service");
const taxes_service_1 = require("../../taxes/taxes.service");
const tax_config_entity_1 = require("../../tax-config/entities/tax-config.entity");
let TaxPaymentsService = class TaxPaymentsService {
    taxPaymentRepository;
    taxConfigService;
    taxesService;
    constructor(taxPaymentRepository, taxConfigService, taxesService) {
        this.taxPaymentRepository = taxPaymentRepository;
        this.taxConfigService = taxConfigService;
        this.taxesService = taxesService;
    }
    async generateMonthlySummary(userId, year, month) {
        const monthlyPayroll = await this.taxesService.getMonthlyPayrollSummary(userId, year, month);
        const date = new Date(year, month - 1, 15);
        const taxConfigs = await this.taxConfigService.getAllActiveTaxConfigs(date);
        const taxes = [];
        let totalDue = 0;
        let totalPaid = 0;
        for (const config of taxConfigs) {
            const amount = this.calculateTaxAmount(config.taxType, monthlyPayroll);
            const existingPayment = await this.taxPaymentRepository.findOne({
                where: {
                    userId,
                    taxType: config.taxType,
                    paymentYear: year,
                    paymentMonth: month,
                },
            });
            const status = existingPayment?.status || tax_payment_entity_1.PaymentStatus.PENDING;
            const paidAmount = existingPayment?.amount || 0;
            taxes.push({
                taxType: config.taxType,
                amount,
                status,
                dueDate: this.calculateDueDate(year, month),
            });
            totalDue += amount;
            if (status === tax_payment_entity_1.PaymentStatus.PAID) {
                totalPaid += paidAmount;
            }
        }
        return {
            year,
            month,
            totalDue,
            totalPaid,
            taxes,
            paymentInstructions: {
                mpesa: {
                    paybill: '222222',
                    accountNumber: 'Your iTax Payment Registration Number',
                },
                bank: 'Any KRA-appointed bank with payment slip from iTax',
                deadline: this.calculateDueDate(year, month),
            },
        };
    }
    calculateTaxAmount(taxType, payrollSummary) {
        switch (taxType) {
            case tax_config_entity_1.TaxType.PAYE:
                return payrollSummary.totalPaye || 0;
            case tax_config_entity_1.TaxType.SHIF:
                return payrollSummary.totalShif || 0;
            case tax_config_entity_1.TaxType.NSSF_TIER1:
            case tax_config_entity_1.TaxType.NSSF_TIER2:
                return payrollSummary.totalNssf || 0;
            case tax_config_entity_1.TaxType.HOUSING_LEVY:
                return payrollSummary.totalHousingLevy || 0;
            default:
                return 0;
        }
    }
    calculateDueDate(year, month) {
        const nextMonth = month === 12 ? 1 : month + 1;
        const nextYear = month === 12 ? year + 1 : year;
        return `${nextYear}-${String(nextMonth).padStart(2, '0')}-09`;
    }
    async recordPayment(userId, dto) {
        const payment = this.taxPaymentRepository.create({
            userId,
            ...dto,
            paymentDate: dto.paymentDate ? new Date(dto.paymentDate) : new Date(),
            status: dto.paymentDate ? tax_payment_entity_1.PaymentStatus.PAID : tax_payment_entity_1.PaymentStatus.PENDING,
        });
        return this.taxPaymentRepository.save(payment);
    }
    async getPaymentHistory(userId) {
        return this.taxPaymentRepository.find({
            where: { userId },
            relations: ['user'],
            order: {
                paymentYear: 'DESC',
                paymentMonth: 'DESC',
                createdAt: 'DESC',
            },
        });
    }
    async getPendingPayments(userId) {
        return this.taxPaymentRepository.find({
            where: {
                userId,
                status: tax_payment_entity_1.PaymentStatus.PENDING,
            },
            order: {
                paymentYear: 'ASC',
                paymentMonth: 'ASC',
            },
        });
    }
    async updatePaymentStatus(id, userId, status) {
        const payment = await this.taxPaymentRepository.findOne({
            where: { id, userId },
        });
        if (!payment) {
            throw new common_1.NotFoundException('Payment not found');
        }
        payment.status = status;
        return this.taxPaymentRepository.save(payment);
    }
};
exports.TaxPaymentsService = TaxPaymentsService;
exports.TaxPaymentsService = TaxPaymentsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(tax_payment_entity_1.TaxPayment)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        tax_config_service_1.TaxConfigService,
        taxes_service_1.TaxesService])
], TaxPaymentsService);
//# sourceMappingURL=tax-payments.service.js.map