"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExportService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const export_entity_1 = require("../entities/export.entity");
const transaction_entity_1 = require("../../payments/entities/transaction.entity");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let ExportService = class ExportService {
    exportRepository;
    transactionRepository;
    exportsDir = path.join(process.cwd(), 'exports');
    constructor(exportRepository, transactionRepository) {
        this.exportRepository = exportRepository;
        this.transactionRepository = transactionRepository;
        if (!fs.existsSync(this.exportsDir)) {
            fs.mkdirSync(this.exportsDir, { recursive: true });
        }
    }
    async getPayrollData(userId, startDate, endDate) {
        const transactions = await this.transactionRepository.find({
            where: {
                userId,
                createdAt: (0, typeorm_2.Between)(startDate, endDate),
                type: transaction_entity_1.TransactionType.SALARY_PAYOUT,
            },
            order: {
                createdAt: 'ASC',
            },
        });
        return transactions.map((t) => ({
            date: t.createdAt.toISOString().split('T')[0],
            workerName: t.metadata?.workerName || 'Unknown',
            workerId: t.workerId,
            grossSalary: t.metadata?.grossSalary || 0,
            paye: t.metadata?.taxBreakdown?.paye || 0,
            nssf: t.metadata?.taxBreakdown?.nssf || 0,
            shif: t.metadata?.taxBreakdown?.nhif || 0,
            housingLevy: t.metadata?.taxBreakdown?.housingLevy || 0,
            totalDeductions: t.metadata?.taxBreakdown?.totalDeductions || 0,
            netPay: t.metadata?.netPay || t.amount,
        }));
    }
    async generateQuickBooksIIF(userId, startDate, endDate) {
        const records = await this.getPayrollData(userId, startDate, endDate);
        let iif = '!TRNS\tDATE\tACCNT\tAMOUNT\tMEMO\n';
        iif += '!SPL\tDATE\tACCNT\tAMOUNT\tMEMO\n';
        iif += '!ENDTRNS\n';
        for (const record of records) {
            const date = new Date(record.date).toLocaleDateString('en-US');
            const memo = `${record.workerName} - Payroll`;
            iif += `TRNS\t${date}\tPayroll Expense\t${record.grossSalary.toFixed(2)}\t${memo}\n`;
            iif += `SPL\t${date}\tPAYE Payable\t${record.paye.toFixed(2)}\tPAYE\n`;
            iif += `SPL\t${date}\tNSSF Payable\t${record.nssf.toFixed(2)}\tNSSF\n`;
            iif += `SPL\t${date}\tSHIF Payable\t${record.shif.toFixed(2)}\tSHIF\n`;
            iif += `SPL\t${date}\tHousing Levy Payable\t${record.housingLevy.toFixed(2)}\tHousing Levy\n`;
            iif += `SPL\t${date}\tCash\t-${record.netPay.toFixed(2)}\tNet Pay\n`;
            iif += 'ENDTRNS\n';
        }
        return iif;
    }
    async generateXeroCSV(userId, startDate, endDate) {
        const records = await this.getPayrollData(userId, startDate, endDate);
        let csv = '*ContactName,*InvoiceNumber,*InvoiceDate,*DueDate,*Description,*Quantity,*UnitAmount,*AccountCode,*TaxType,Currency\n';
        records.forEach((record, index) => {
            const invoiceNum = `PAY-${new Date(record.date).getTime()}-${index + 1}`;
            const date = new Date(record.date)
                .toLocaleDateString('en-GB')
                .split('/')
                .reverse()
                .join('/');
            csv += `${record.workerName},${invoiceNum},${date},${date},Salary Payment,1,${record.netPay.toFixed(2)},6200,Tax Exempt,KES\n`;
        });
        return csv;
    }
    async generateGenericCSV(userId, startDate, endDate) {
        const records = await this.getPayrollData(userId, startDate, endDate);
        let csv = 'Date,Worker Name,Worker ID,Gross Salary,PAYE,NSSF,SHIF,Housing Levy,Total Deductions,Net Pay\n';
        for (const record of records) {
            csv += `${record.date},${record.workerName},${record.workerId},`;
            csv += `${record.grossSalary.toFixed(2)},${record.paye.toFixed(2)},`;
            csv += `${record.nssf.toFixed(2)},${record.shif.toFixed(2)},`;
            csv += `${record.housingLevy.toFixed(2)},${record.totalDeductions.toFixed(2)},`;
            csv += `${record.netPay.toFixed(2)}\n`;
        }
        return csv;
    }
    async createExport(userId, exportType, startDate, endDate) {
        let content;
        let extension;
        switch (exportType) {
            case export_entity_1.ExportType.QUICKBOOKS_IIF:
                content = await this.generateQuickBooksIIF(userId, startDate, endDate);
                extension = 'iif';
                break;
            case export_entity_1.ExportType.XERO_CSV:
                content = await this.generateXeroCSV(userId, startDate, endDate);
                extension = 'csv';
                break;
            case export_entity_1.ExportType.GENERIC_CSV:
                content = await this.generateGenericCSV(userId, startDate, endDate);
                extension = 'csv';
                break;
            default:
                throw new Error('Unsupported export type');
        }
        const fileName = `payroll_export_${Date.now()}.${extension}`;
        const filePath = path.join(this.exportsDir, fileName);
        fs.writeFileSync(filePath, content, 'utf-8');
        const recordCount = content.split('\n').length - 1;
        const exportRecord = this.exportRepository.create({
            userId,
            exportType,
            startDate,
            endDate,
            fileName,
            filePath,
            recordCount,
        });
        return this.exportRepository.save(exportRecord);
    }
    async getExportHistory(userId) {
        return this.exportRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: 50,
        });
    }
    async getExportFile(id, userId) {
        const exportRecord = await this.exportRepository.findOne({
            where: { id, userId },
        });
        if (!exportRecord || !exportRecord.filePath) {
            throw new Error('Export not found');
        }
        return fs.readFileSync(exportRecord.filePath);
    }
};
exports.ExportService = ExportService;
exports.ExportService = ExportService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(export_entity_1.Export)),
    __param(1, (0, typeorm_1.InjectRepository)(transaction_entity_1.Transaction)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], ExportService);
//# sourceMappingURL=export.service.js.map