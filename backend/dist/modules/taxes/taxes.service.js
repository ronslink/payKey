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
let TaxesService = class TaxesService {
    taxTableRepository;
    taxSubmissionRepository;
    usersService;
    constructor(taxTableRepository, taxSubmissionRepository, usersService) {
        this.taxTableRepository = taxTableRepository;
        this.taxSubmissionRepository = taxSubmissionRepository;
        this.usersService = usersService;
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
    calculateNSSF(grossSalary, table) {
        const { tierILimit, tierIILimit, rate } = table.nssfConfig;
        const tierI = Math.min(grossSalary, tierILimit) * rate;
        const tierII = grossSalary > tierILimit
            ? Math.min(grossSalary - tierILimit, tierIILimit - tierILimit) * rate
            : 0;
        return Math.round((tierI + tierII) * 100) / 100;
    }
    calculateNHIF(grossSalary, table) {
        return Math.round(grossSalary * table.nhifConfig.rate * 100) / 100;
    }
    calculateHousingLevy(grossSalary, table) {
        return Math.round(grossSalary * Number(table.housingLevyRate) * 100) / 100;
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
        const table = await this.getTaxTable(date);
        const nssf = this.calculateNSSF(grossSalary, table);
        const nhif = this.calculateNHIF(grossSalary, table);
        const housingLevy = this.calculateHousingLevy(grossSalary, table);
        const paye = this.calculatePAYE(grossSalary, nssf, table);
        const totalDeductions = nssf + nhif + housingLevy + paye;
        return {
            nssf,
            nhif,
            housingLevy,
            paye,
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
    async markAsFiled(id, userId) {
        const submission = await this.taxSubmissionRepository.findOne({
            where: { id, userId },
        });
        if (!submission) {
            throw new common_1.NotFoundException('Tax submission not found');
        }
        submission.status = tax_submission_entity_1.TaxSubmissionStatus.FILED;
        submission.filingDate = new Date();
        return this.taxSubmissionRepository.save(submission);
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
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        users_service_1.UsersService])
], TaxesService);
//# sourceMappingURL=taxes.service.js.map