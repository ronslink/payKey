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
exports.TaxesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const tax_table_entity_1 = require("./entities/tax-table.entity");
const tax_submission_entity_1 = require("./entities/tax-submission.entity");
const users_service_1 = require("../users/users.service");
const payroll_record_entity_1 = require("../payroll/entities/payroll-record.entity");
const tax_config_service_1 = require("../tax-config/services/tax-config.service");
const tax_config_entity_1 = require("../tax-config/entities/tax-config.entity");
const activities_service_1 = require("../activities/activities.service");
const activity_entity_1 = require("../activities/entities/activity.entity");
let TaxesService = class TaxesService {
    taxTableRepository;
    taxSubmissionRepository;
    payrollRecordRepository;
    taxConfigService;
    usersService;
    activitiesService;
    constructor(taxTableRepository, taxSubmissionRepository, payrollRecordRepository, taxConfigService, usersService, activitiesService) {
        this.taxTableRepository = taxTableRepository;
        this.taxSubmissionRepository = taxSubmissionRepository;
        this.payrollRecordRepository = payrollRecordRepository;
        this.taxConfigService = taxConfigService;
        this.usersService = usersService;
        this.activitiesService = activitiesService;
    }
    async createTaxTable(data) {
        const taxTable = this.taxTableRepository.create(data);
        return this.taxTableRepository.save(taxTable);
    }
    async getTaxTables() {
        return this.taxTableRepository.find({ order: { effectiveDate: 'DESC' } });
    }
    async getTaxTable(date) {
        const taxTable = await this.taxTableRepository.findOne({
            where: {
                effectiveDate: (0, typeorm_2.LessThanOrEqual)(date),
                isActive: true,
            },
            order: { effectiveDate: 'DESC' },
        });
        if (!taxTable) {
            return this.getDefaultTaxTable();
        }
        return taxTable;
    }
    getDefaultTaxTable() {
        return {
            id: 'default',
            year: 2024,
            effectiveDate: new Date('2024-01-01'),
            nssfConfig: {
                tierILimit: 7000,
                tierIILimit: 36000,
                rate: 0.06,
            },
            nhifConfig: {
                rate: 0.0275,
            },
            housingLevyRate: 0.015,
            payeBands: [
                { limit: 24000, rate: 0.1 },
                { limit: 32333, rate: 0.25 },
                { limit: Infinity, rate: 0.3 },
            ],
            personalRelief: 2400,
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date(),
        };
    }
    async calculateNSSF(grossSalary, date) {
        const tier1Config = await this.taxConfigService.getActiveTaxConfig(tax_config_entity_1.TaxType.NSSF_TIER1, date);
        const tier2Config = await this.taxConfigService.getActiveTaxConfig(tax_config_entity_1.TaxType.NSSF_TIER2, date);
        let totalNssf = 0;
        if (tier1Config && tier1Config.configuration.tiers) {
            const tier1 = tier1Config.configuration.tiers[0];
            const tier1Limit = tier1.salaryTo || 8000;
            totalNssf += Math.min(grossSalary, tier1Limit) * tier1.rate;
        }
        if (tier2Config && tier2Config.configuration.tiers) {
            const tier2 = tier2Config.configuration.tiers[0];
            if (grossSalary > 8000) {
                const tier2Limit = tier2.salaryTo || 72000;
                const tier2From = tier2.salaryFrom || 8001;
                totalNssf +=
                    Math.min(grossSalary - 8000, tier2Limit - tier2From) * tier2.rate;
            }
        }
        return Math.round(totalNssf * 100) / 100;
    }
    async calculatePAYEFromConfig(grossSalary, nssf, date) {
        const payeConfig = await this.taxConfigService.getActiveTaxConfig(tax_config_entity_1.TaxType.PAYE, date);
        if (payeConfig && payeConfig.configuration.brackets) {
            const taxableIncome = grossSalary - nssf;
            let tax = 0;
            let remainingIncome = taxableIncome;
            let previousLimit = 0;
            for (const bracket of payeConfig.configuration.brackets) {
                if (remainingIncome <= 0)
                    break;
                const taxableAmount = bracket.to === null
                    ? remainingIncome
                    : Math.min(remainingIncome, bracket.to - previousLimit);
                tax += taxableAmount * bracket.rate;
                remainingIncome -= taxableAmount;
                previousLimit = bracket.to || previousLimit;
            }
            const personalRelief = payeConfig.configuration.personalRelief || 2400;
            const paye = Math.max(0, tax - personalRelief);
            return Math.round(paye * 100) / 100;
        }
        const table = await this.getTaxTable(date);
        return this.calculatePAYE(grossSalary, nssf, table);
    }
    async calculateSHIF(grossSalary, date) {
        const shifConfig = await this.taxConfigService.getActiveTaxConfig(tax_config_entity_1.TaxType.SHIF, date);
        if (shifConfig && shifConfig.configuration.percentage !== undefined) {
            const shifAmount = grossSalary * shifConfig.configuration.percentage;
            const minAmount = shifConfig.configuration.minAmount || 0;
            return Math.round(Math.max(shifAmount, minAmount) * 100) / 100;
        }
        const shifAmount = grossSalary * 0.0275;
        return Math.round(Math.max(shifAmount, 300) * 100) / 100;
    }
    async calculateHousingLevy(grossSalary, date) {
        const housingConfig = await this.taxConfigService.getActiveTaxConfig(tax_config_entity_1.TaxType.HOUSING_LEVY, date);
        if (housingConfig && housingConfig.configuration.percentage !== undefined) {
            return (Math.round(grossSalary * housingConfig.configuration.percentage * 100) /
                100);
        }
        return Math.round(grossSalary * 0.015 * 100) / 100;
    }
    calculatePAYE(grossSalary, nssf, table) {
        const taxableIncome = grossSalary - nssf;
        let tax = 0;
        let remainingIncome = taxableIncome;
        let previousLimit = 0;
        for (const band of table.payeBands) {
            if (remainingIncome <= 0)
                break;
            const taxableAmount = band.limit === Infinity
                ? remainingIncome
                : Math.min(remainingIncome, band.limit - previousLimit);
            tax += taxableAmount * band.rate;
            remainingIncome -= taxableAmount;
            previousLimit = band.limit;
        }
        const paye = Math.max(0, tax - Number(table.personalRelief));
        return Math.round(paye * 100) / 100;
    }
    async calculateTaxes(grossSalary, date = new Date()) {
        const nssf = await this.calculateNSSF(grossSalary, date);
        const [shif, housingLevy, payeConfig] = await Promise.all([
            this.calculateSHIF(grossSalary, date),
            this.calculateHousingLevy(grossSalary, date),
            this.calculatePAYEFromConfig(grossSalary, nssf, date),
        ]);
        const totalDeductions = nssf + shif + housingLevy + payeConfig;
        return {
            nssf,
            nhif: shif,
            housingLevy,
            paye: payeConfig,
            totalDeductions: Math.round(totalDeductions * 100) / 100,
        };
    }
    async calculateNetPay(grossSalary) {
        const taxes = await this.calculateTaxes(grossSalary);
        return Math.round((grossSalary - taxes.totalDeductions) * 100) / 100;
    }
    async calculatePayroll(workerId, workerName, grossSalary) {
        const taxBreakdown = await this.calculateTaxes(grossSalary);
        const netPay = grossSalary - taxBreakdown.totalDeductions;
        return {
            workerId,
            workerName,
            grossSalary,
            taxBreakdown,
            netPay: Math.round(netPay * 100) / 100,
        };
    }
    async getMonthlyPayrollSummary(userId, year, month) {
        return Promise.resolve({
            totalGross: 0,
            totalPaye: 0,
            totalNssf: 0,
            totalShif: 0,
            totalHousingLevy: 0,
        });
    }
    async getSubmissions(userId) {
        return this.taxSubmissionRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            relations: ['payPeriod'],
        });
    }
    async generateTaxSubmission(payPeriodId, userId) {
        const payrollRecords = await this.payrollRecordRepository.find({
            where: {
                payPeriodId,
                userId,
                status: 'finalized',
            },
        });
        if (payrollRecords.length === 0) {
            throw new common_1.NotFoundException('No finalized payroll records found for this period');
        }
        const totalPaye = payrollRecords.reduce((sum, record) => sum + Number(record.taxAmount), 0);
        const totalNssf = payrollRecords.reduce((sum, record) => sum + Number(record.taxBreakdown.nssf), 0);
        const totalNhif = payrollRecords.reduce((sum, record) => sum + Number(record.taxBreakdown.nhif), 0);
        const totalHousingLevy = payrollRecords.reduce((sum, record) => sum + Number(record.taxBreakdown.housingLevy), 0);
        let submission = await this.taxSubmissionRepository.findOne({
            where: { payPeriodId, userId },
        });
        if (submission) {
            submission.totalPaye = totalPaye;
            submission.totalNssf = totalNssf;
            submission.totalNhif = totalNhif;
            submission.totalHousingLevy = totalHousingLevy;
        }
        else {
            submission = this.taxSubmissionRepository.create({
                userId,
                payPeriodId,
                totalPaye,
                totalNssf,
                totalNhif,
                totalHousingLevy,
                status: tax_submission_entity_1.TaxSubmissionStatus.PENDING,
            });
        }
        const savedSubmission = await this.taxSubmissionRepository.save(submission);
        try {
            await this.activitiesService.logActivity(userId, activity_entity_1.ActivityType.TAX, 'Tax Submission Generated', `Generated tax submission for pay period`, {
                submissionId: savedSubmission.id,
                payPeriodId,
                totalPaye,
                totalNssf,
                totalNhif,
                totalHousingLevy,
            });
        }
        catch (e) {
            console.error('Failed to log activity:', e);
        }
        return savedSubmission;
    }
    async getTaxSubmissionByPeriod(payPeriodId, userId) {
        return this.taxSubmissionRepository.findOne({
            where: { payPeriodId, userId },
            relations: ['payPeriod'],
        });
    }
    async markAsFiled(id, userId) {
        const submission = await this.taxSubmissionRepository.findOne({
            where: { id, userId },
        });
        if (!submission) {
            throw new common_1.NotFoundException('Tax submission not found');
        }
        submission.status = tax_submission_entity_1.TaxSubmissionStatus.FILED;
        submission.filingDate = new Date();
        const savedSubmission = await this.taxSubmissionRepository.save(submission);
        try {
            await this.activitiesService.logActivity(userId, activity_entity_1.ActivityType.TAX, 'Tax Returns Filed', `Marked tax submission as filed`, {
                submissionId: savedSubmission.id,
                filingDate: savedSubmission.filingDate,
            });
        }
        catch (e) {
            console.error('Failed to log activity:', e);
        }
        return savedSubmission;
    }
    async getComplianceStatus(userId) {
        const user = await this.usersService.findOneById(userId);
        return {
            kraPin: !!user?.kraPin,
            nssf: !!user?.nssfNumber,
            nhif: !!user?.nhifNumber,
            isCompliant: !!user?.kraPin && !!user?.nssfNumber && !!user?.nhifNumber,
        };
    }
    getUpcomingDeadlines() {
        const today = new Date();
        const currentMonth = today.getMonth();
        const currentYear = today.getFullYear();
        const createDeadline = (day, monthOffset = 0) => {
            let month = currentMonth + monthOffset;
            let year = currentYear;
            if (month > 11) {
                month = 0;
                year++;
            }
            const deadline = new Date(year, month, day);
            if (deadline < today && monthOffset === 0) {
                return createDeadline(day, 1);
            }
            return deadline;
        };
        const payeDeadline = createDeadline(9);
        const nssfDeadline = createDeadline(15);
        const nhifDeadline = createDeadline(9);
        const housingLevyDeadline = createDeadline(9);
        return [
            {
                title: 'PAYE Remittance',
                dueDate: payeDeadline,
                description: 'Pay As You Earn for previous month',
            },
            {
                title: 'Housing Levy',
                dueDate: housingLevyDeadline,
                description: 'Affordable Housing Levy remittance',
            },
            {
                title: 'SHIF/NHIF Contribution',
                dueDate: nhifDeadline,
                description: 'Social Health Insurance Fund',
            },
            {
                title: 'NSSF Contribution',
                dueDate: nssfDeadline,
                description: 'National Social Security Fund',
            },
        ].sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
    }
};
exports.TaxesService = TaxesService;
exports.TaxesService = TaxesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(tax_table_entity_1.TaxTable)),
    __param(1, (0, typeorm_1.InjectRepository)(tax_submission_entity_1.TaxSubmission)),
    __param(2, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        tax_config_service_1.TaxConfigService,
        users_service_1.UsersService,
        activities_service_1.ActivitiesService])
], TaxesService);
//# sourceMappingURL=taxes.service.js.map