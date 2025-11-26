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
exports.AccountingExportService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const payroll_record_entity_1 = require("../payroll/entities/payroll-record.entity");
const account_mapping_entity_1 = require("./entities/account-mapping.entity");
const accounting_export_entity_1 = require("./entities/accounting-export.entity");
let AccountingExportService = class AccountingExportService {
    payrollRecordRepository;
    accountMappingRepository;
    accountingExportRepository;
    constructor(payrollRecordRepository, accountMappingRepository, accountingExportRepository) {
        this.payrollRecordRepository = payrollRecordRepository;
        this.accountMappingRepository = accountMappingRepository;
        this.accountingExportRepository = accountingExportRepository;
    }
    async generateJournalEntries(payPeriodId, userId) {
        const payrollRecords = await this.payrollRecordRepository.find({
            where: {
                payPeriodId,
                userId,
                status: 'finalized',
            },
            relations: ['worker'],
        });
        if (payrollRecords.length === 0) {
            throw new Error('No finalized payroll records found for this period');
        }
        const mappings = await this.getAccountMappings(userId);
        const totals = this.aggregatePayrollTotals(payrollRecords);
        const entries = [];
        const date = new Date();
        const description = `Payroll for ${new Date(payrollRecords[0].createdAt).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`;
        entries.push({
            date,
            account: mappings.SALARY_EXPENSE.accountCode,
            accountName: mappings.SALARY_EXPENSE.accountName,
            debit: totals.totalGrossSalary,
            credit: 0,
            description: `${description} - Gross Salaries`,
        });
        if (totals.totalPaye > 0) {
            entries.push({
                date,
                account: mappings.PAYE_LIABILITY.accountCode,
                accountName: mappings.PAYE_LIABILITY.accountName,
                debit: 0,
                credit: totals.totalPaye,
                description: `${description} - PAYE`,
            });
        }
        if (totals.totalNssf > 0) {
            entries.push({
                date,
                account: mappings.NSSF_LIABILITY.accountCode,
                accountName: mappings.NSSF_LIABILITY.accountName,
                debit: 0,
                credit: totals.totalNssf,
                description: `${description} - NSSF`,
            });
        }
        if (totals.totalNhif > 0) {
            entries.push({
                date,
                account: mappings.NHIF_LIABILITY.accountCode,
                accountName: mappings.NHIF_LIABILITY.accountName,
                debit: 0,
                credit: totals.totalNhif,
                description: `${description} - NHIF`,
            });
        }
        if (totals.totalHousingLevy > 0) {
            entries.push({
                date,
                account: mappings.HOUSING_LEVY_LIABILITY.accountCode,
                accountName: mappings.HOUSING_LEVY_LIABILITY.accountName,
                debit: 0,
                credit: totals.totalHousingLevy,
                description: `${description} - Housing Levy`,
            });
        }
        entries.push({
            date,
            account: mappings.CASH_BANK.accountCode,
            accountName: mappings.CASH_BANK.accountName,
            debit: 0,
            credit: totals.totalNetPay,
            description: `${description} - Net Pay`,
        });
        const totalDebits = entries.reduce((sum, e) => sum + e.debit, 0);
        const totalCredits = entries.reduce((sum, e) => sum + e.credit, 0);
        const isBalanced = Math.abs(totalDebits - totalCredits) < 0.01;
        return {
            entries,
            totalDebits,
            totalCredits,
            isBalanced,
        };
    }
    async exportToCSV(payPeriodId, userId) {
        const journalEntries = await this.generateJournalEntries(payPeriodId, userId);
        if (!journalEntries.isBalanced) {
            throw new Error('Journal entries are not balanced. Cannot export.');
        }
        const headers = [
            'Date',
            'Account Code',
            'Account Name',
            'Debit',
            'Credit',
            'Description',
        ];
        const rows = journalEntries.entries.map((entry) => [
            entry.date.toISOString().split('T')[0],
            entry.account,
            entry.accountName,
            entry.debit > 0 ? entry.debit.toFixed(2) : '',
            entry.credit > 0 ? entry.credit.toFixed(2) : '',
            entry.description,
        ]);
        rows.push([
            '',
            '',
            'TOTALS',
            journalEntries.totalDebits.toFixed(2),
            journalEntries.totalCredits.toFixed(2),
            '',
        ]);
        const csv = [headers, ...rows]
            .map((row) => row.map((cell) => `"${cell}"`).join(','))
            .join('\n');
        return csv;
    }
    async getAccountMappings(userId) {
        const mappings = await this.accountMappingRepository.find({
            where: { userId },
        });
        if (mappings.length === 0) {
            return this.getDefaultAccountMappings();
        }
        const result = {};
        for (const mapping of mappings) {
            result[mapping.category] = {
                accountCode: mapping.accountCode,
                accountName: mapping.accountName,
            };
        }
        const defaults = this.getDefaultAccountMappings();
        for (const category of Object.values(account_mapping_entity_1.AccountCategory)) {
            if (!result[category]) {
                result[category] = defaults[category];
            }
        }
        return result;
    }
    getDefaultAccountMappings() {
        return {
            [account_mapping_entity_1.AccountCategory.SALARY_EXPENSE]: {
                accountCode: '6100',
                accountName: 'Salaries and Wages',
            },
            [account_mapping_entity_1.AccountCategory.PAYE_LIABILITY]: {
                accountCode: '2110',
                accountName: 'PAYE Payable',
            },
            [account_mapping_entity_1.AccountCategory.NSSF_LIABILITY]: {
                accountCode: '2120',
                accountName: 'NSSF Payable',
            },
            [account_mapping_entity_1.AccountCategory.NHIF_LIABILITY]: {
                accountCode: '2130',
                accountName: 'NHIF Payable',
            },
            [account_mapping_entity_1.AccountCategory.HOUSING_LEVY_LIABILITY]: {
                accountCode: '2140',
                accountName: 'Housing Levy Payable',
            },
            [account_mapping_entity_1.AccountCategory.CASH_BANK]: {
                accountCode: '1010',
                accountName: 'Cash at Bank',
            },
        };
    }
    async saveAccountMappings(userId, mappings) {
        await this.accountMappingRepository.delete({ userId });
        const entities = mappings.map((m) => this.accountMappingRepository.create({
            userId,
            category: m.category,
            accountCode: m.accountCode,
            accountName: m.accountName,
        }));
        return this.accountMappingRepository.save(entities);
    }
    aggregatePayrollTotals(payrollRecords) {
        return {
            totalGrossSalary: payrollRecords.reduce((sum, r) => sum + Number(r.grossSalary), 0),
            totalPaye: payrollRecords.reduce((sum, r) => sum + Number(r.taxAmount), 0),
            totalNssf: payrollRecords.reduce((sum, r) => sum + Number(r.taxBreakdown.nssf), 0),
            totalNhif: payrollRecords.reduce((sum, r) => sum + Number(r.taxBreakdown.nhif), 0),
            totalHousingLevy: payrollRecords.reduce((sum, r) => sum + Number(r.taxBreakdown.housingLevy), 0),
            totalNetPay: payrollRecords.reduce((sum, r) => sum + Number(r.netSalary), 0),
        };
    }
};
exports.AccountingExportService = AccountingExportService;
exports.AccountingExportService = AccountingExportService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(payroll_record_entity_1.PayrollRecord)),
    __param(1, (0, typeorm_1.InjectRepository)(account_mapping_entity_1.AccountMapping)),
    __param(2, (0, typeorm_1.InjectRepository)(accounting_export_entity_1.AccountingExport)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], AccountingExportService);
//# sourceMappingURL=accounting-export.service.js.map