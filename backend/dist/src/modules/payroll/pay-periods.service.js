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
exports.PayPeriodsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const pay_period_entity_1 = require("./entities/pay-period.entity");
const payroll_record_entity_1 = require("./entities/payroll-record.entity");
const tax_payments_service_1 = require("../tax-payments/services/tax-payments.service");
let PayPeriodsService = class PayPeriodsService {
    payPeriodRepository;
    payrollRecordRepository;
    taxPaymentsService;
    constructor(payPeriodRepository, payrollRecordRepository, taxPaymentsService) {
        this.payPeriodRepository = payPeriodRepository;
        this.payrollRecordRepository = payrollRecordRepository;
        this.taxPaymentsService = taxPaymentsService;
    }
    async create(createPayPeriodDto) {
        if (new Date(createPayPeriodDto.startDate) >=
            new Date(createPayPeriodDto.endDate)) {
            throw new common_1.BadRequestException('Start date must be before end date');
        }
        const overlapping = await this.payPeriodRepository
            .createQueryBuilder('pp')
            .where('pp.startDate <= :endDate', {
            endDate: createPayPeriodDto.endDate,
        })
            .andWhere('pp.endDate >= :startDate', {
            startDate: createPayPeriodDto.startDate,
        })
            .getOne();
        if (overlapping) {
            throw new common_1.BadRequestException('Pay period overlaps with existing period');
        }
        const payPeriod = this.payPeriodRepository.create({
            ...createPayPeriodDto,
            status: pay_period_entity_1.PayPeriodStatus.DRAFT,
        });
        return this.payPeriodRepository.save(payPeriod);
    }
    async findAll(page = 1, limit = 10, status, frequency) {
        const queryBuilder = this.payPeriodRepository.createQueryBuilder('pp');
        if (status) {
            queryBuilder.andWhere('pp.status = :status', { status });
        }
        if (frequency) {
            queryBuilder.andWhere('pp.frequency = :frequency', { frequency });
        }
        const [data, total] = await queryBuilder
            .orderBy('pp.startDate', 'DESC')
            .skip((page - 1) * limit)
            .take(limit)
            .getManyAndCount();
        return { data, total, page, limit };
    }
    async findOne(id) {
        const payPeriod = await this.payPeriodRepository.findOne({ where: { id } });
        if (!payPeriod) {
            throw new common_1.NotFoundException(`Pay period with ID ${id} not found`);
        }
        return payPeriod;
    }
    async update(id, updatePayPeriodDto) {
        const payPeriod = await this.findOne(id);
        if (updatePayPeriodDto.status) {
            this.validateStatusTransition(payPeriod.status, updatePayPeriodDto.status);
        }
        if (updatePayPeriodDto.startDate || updatePayPeriodDto.endDate) {
            const newStartDate = updatePayPeriodDto.startDate || payPeriod.startDate;
            const newEndDate = updatePayPeriodDto.endDate || payPeriod.endDate;
            if (new Date(newStartDate) >= new Date(newEndDate)) {
                throw new common_1.BadRequestException('Start date must be before end date');
            }
            const overlapping = await this.payPeriodRepository
                .createQueryBuilder('pp')
                .where('pp.id != :id', { id })
                .andWhere('pp.startDate <= :endDate', { endDate: newEndDate })
                .andWhere('pp.endDate >= :startDate', { startDate: newStartDate })
                .getOne();
            if (overlapping) {
                throw new common_1.BadRequestException('Pay period overlaps with existing period');
            }
        }
        if (updatePayPeriodDto.status === pay_period_entity_1.PayPeriodStatus.COMPLETED &&
            payPeriod.status !== pay_period_entity_1.PayPeriodStatus.COMPLETED) {
        }
        await this.payPeriodRepository.update(id, updatePayPeriodDto);
        return this.findOne(id);
    }
    async remove(id) {
        const payPeriod = await this.findOne(id);
        if ([
            pay_period_entity_1.PayPeriodStatus.PROCESSING,
            pay_period_entity_1.PayPeriodStatus.COMPLETED,
            pay_period_entity_1.PayPeriodStatus.CLOSED,
        ].includes(payPeriod.status)) {
            throw new common_1.BadRequestException('Cannot delete pay period that is processing, completed, or closed');
        }
        const payrollRecords = await this.payrollRecordRepository.count({
            where: {
                periodStart: payPeriod.startDate,
                periodEnd: payPeriod.endDate,
            },
        });
        if (payrollRecords > 0) {
            throw new common_1.BadRequestException('Cannot delete pay period with existing payroll records');
        }
        await this.payPeriodRepository.remove(payPeriod);
    }
    async activate(id) {
        return this.update(id, { status: pay_period_entity_1.PayPeriodStatus.ACTIVE });
    }
    async process(id) {
        const payPeriod = await this.findOne(id);
        if (payPeriod.status !== pay_period_entity_1.PayPeriodStatus.ACTIVE &&
            payPeriod.status !== pay_period_entity_1.PayPeriodStatus.DRAFT) {
            throw new common_1.BadRequestException('Only draft or active pay periods can be processed');
        }
        const payrollRecords = await this.payrollRecordRepository.find({
            where: {
                periodStart: payPeriod.startDate,
                periodEnd: payPeriod.endDate,
            },
        });
        const totals = payrollRecords.reduce((acc, record) => ({
            grossAmount: acc.grossAmount + Number(record.grossSalary),
            netAmount: acc.netAmount + Number(record.netSalary),
            taxAmount: acc.taxAmount + Number(record.taxAmount),
            processedWorkers: acc.processedWorkers + 1,
        }), { grossAmount: 0, netAmount: 0, taxAmount: 0, processedWorkers: 0 });
        await this.payPeriodRepository.update(id, {
            status: pay_period_entity_1.PayPeriodStatus.PROCESSING,
            totalGrossAmount: totals.grossAmount,
            totalNetAmount: totals.netAmount,
            totalTaxAmount: totals.taxAmount,
            processedWorkers: totals.processedWorkers,
            processedAt: new Date(),
        });
        return this.findOne(id);
    }
    async complete(id) {
        const payPeriod = await this.findOne(id);
        if (payPeriod.status !== pay_period_entity_1.PayPeriodStatus.PROCESSING) {
            throw new common_1.BadRequestException('Only processing pay periods can be completed');
        }
        await this.generateTaxSubmissionData(id);
        return this.update(id, { status: pay_period_entity_1.PayPeriodStatus.COMPLETED });
    }
    async generateTaxSubmissionData(payPeriodId) {
        const payPeriod = await this.findOne(payPeriodId);
        const payrollRecords = await this.payrollRecordRepository.find({
            where: {
                periodStart: payPeriod.startDate,
                periodEnd: payPeriod.endDate,
            },
        });
        if (payrollRecords.length === 0) {
            return;
        }
        const uniqueUserIds = [...new Set(payrollRecords.map((r) => r.userId))];
        const startDate = new Date(payPeriod.startDate);
        const paymentYear = startDate.getFullYear();
        const paymentMonth = startDate.getMonth() + 1;
        for (const userId of uniqueUserIds) {
            try {
                const monthlySummary = await this.taxPaymentsService.generateMonthlySummary(userId, paymentYear, paymentMonth);
                console.log(`Tax submission data generated for user ${userId}: ${monthlySummary.totalDue} total due`);
            }
            catch (error) {
                console.error(`Failed to generate tax submission for user ${userId}:`, error);
            }
        }
    }
    async close(id) {
        return this.update(id, { status: pay_period_entity_1.PayPeriodStatus.CLOSED });
    }
    validateStatusTransition(currentStatus, newStatus) {
        const validTransitions = {
            [pay_period_entity_1.PayPeriodStatus.DRAFT]: [
                pay_period_entity_1.PayPeriodStatus.ACTIVE,
                pay_period_entity_1.PayPeriodStatus.CLOSED,
            ],
            [pay_period_entity_1.PayPeriodStatus.ACTIVE]: [
                pay_period_entity_1.PayPeriodStatus.PROCESSING,
                pay_period_entity_1.PayPeriodStatus.CLOSED,
            ],
            [pay_period_entity_1.PayPeriodStatus.PROCESSING]: [
                pay_period_entity_1.PayPeriodStatus.COMPLETED,
                pay_period_entity_1.PayPeriodStatus.CLOSED,
            ],
            [pay_period_entity_1.PayPeriodStatus.COMPLETED]: [pay_period_entity_1.PayPeriodStatus.CLOSED],
            [pay_period_entity_1.PayPeriodStatus.CLOSED]: [],
        };
        if (!validTransitions[currentStatus]?.includes(newStatus)) {
            throw new common_1.BadRequestException(`Invalid status transition from ${currentStatus} to ${newStatus}`);
        }
    }
    async getPayPeriodStatistics(id) {
        const payPeriod = await this.findOne(id);
        const payrollRecords = await this.payrollRecordRepository.find({
            where: {
                periodStart: payPeriod.startDate,
                periodEnd: payPeriod.endDate,
            },
        });
        return {
            payPeriod: {
                id: payPeriod.id,
                name: payPeriod.name,
                status: payPeriod.status,
                startDate: payPeriod.startDate,
                endDate: payPeriod.endDate,
            },
            statistics: {
                totalWorkers: payrollRecords.length,
                pendingPayments: payrollRecords.filter((r) => r.paymentStatus === 'pending').length,
                processedPayments: payrollRecords.filter((r) => r.paymentStatus === 'paid').length,
                totalGrossAmount: payrollRecords.reduce((sum, r) => sum + Number(r.grossSalary), 0),
                totalNetAmount: payrollRecords.reduce((sum, r) => sum + Number(r.netSalary), 0),
                totalTaxAmount: payrollRecords.reduce((sum, r) => sum + Number(r.taxAmount), 0),
            },
        };
    }
    async generatePayPeriods(userId, frequency, startDate, endDate) {
        const periods = [];
        const currentDate = new Date(startDate);
        const stepDays = this.getStepDays(frequency);
        while (currentDate <= endDate) {
            const periodEnd = new Date(currentDate);
            periodEnd.setDate(periodEnd.getDate() + stepDays - 1);
            if (periodEnd > endDate)
                break;
            const periodStart = new Date(currentDate);
            const name = this.generatePeriodName(periodStart, periodEnd, frequency);
            const payPeriod = this.payPeriodRepository.create({
                name,
                startDate: periodStart.toISOString().split('T')[0],
                endDate: periodEnd.toISOString().split('T')[0],
                frequency: frequency,
                status: pay_period_entity_1.PayPeriodStatus.DRAFT,
                createdBy: userId,
            });
            periods.push(await this.payPeriodRepository.save(payPeriod));
            currentDate.setDate(currentDate.getDate() + stepDays);
        }
        return periods;
    }
    getStepDays(frequency) {
        const frequencyMap = {
            WEEKLY: 7,
            BIWEEKLY: 14,
            MONTHLY: 30,
            QUARTERLY: 90,
        };
        return frequencyMap[frequency] || 30;
    }
    generatePeriodName(startDate, endDate, frequency) {
        const monthNames = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
        ];
        const startMonth = monthNames[startDate.getMonth()];
        const endMonth = monthNames[endDate.getMonth()];
        if (frequency === 'MONTHLY' && startMonth === endMonth) {
            return `${startMonth} ${startDate.getFullYear()}`;
        }
        return `${startMonth} ${startDate.getDate()}, ${startDate.getFullYear()} - ${endMonth} ${endDate.getDate()}, ${endDate.getFullYear()}`;
    }
};
exports.PayPeriodsService = PayPeriodsService;
exports.PayPeriodsService = PayPeriodsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(pay_period_entity_1.PayPeriod)),
    __param(1, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        tax_payments_service_1.TaxPaymentsService])
], PayPeriodsService);
//# sourceMappingURL=pay-periods.service.js.map