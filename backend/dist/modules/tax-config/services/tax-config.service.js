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
exports.TaxConfigService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const tax_config_entity_1 = require("../entities/tax-config.entity");
let TaxConfigService = class TaxConfigService {
    taxConfigRepository;
    constructor(taxConfigRepository) {
        this.taxConfigRepository = taxConfigRepository;
    }
    async getActiveTaxConfig(taxType, date = new Date()) {
        return this.taxConfigRepository.findOne({
            where: [
                {
                    taxType,
                    effectiveFrom: (0, typeorm_2.LessThanOrEqual)(date),
                    effectiveTo: (0, typeorm_2.MoreThanOrEqual)(date),
                    isActive: true,
                },
                {
                    taxType,
                    effectiveFrom: (0, typeorm_2.LessThanOrEqual)(date),
                    effectiveTo: (0, typeorm_2.IsNull)(),
                    isActive: true,
                },
            ],
            order: {
                effectiveFrom: 'DESC',
            },
        });
    }
    async getAllActiveTaxConfigs(date = new Date()) {
        const taxTypes = Object.values(tax_config_entity_1.TaxType);
        const configs = [];
        for (const taxType of taxTypes) {
            const config = await this.getActiveTaxConfig(taxType, date);
            if (config) {
                configs.push(config);
            }
        }
        return configs;
    }
    async getTaxHistory(taxType) {
        return this.taxConfigRepository.find({
            where: { taxType },
            order: { effectiveFrom: 'DESC' },
        });
    }
    async createTaxConfig(configData) {
        const config = this.taxConfigRepository.create(configData);
        return this.taxConfigRepository.save(config);
    }
    async seedInitialConfigs() {
        const existingConfigs = await this.taxConfigRepository.count();
        if (existingConfigs > 0) {
            return;
        }
        const configs = [
            {
                taxType: tax_config_entity_1.TaxType.PAYE,
                rateType: tax_config_entity_1.RateType.GRADUATED,
                effectiveFrom: new Date('2023-07-01'),
                effectiveTo: undefined,
                configuration: {
                    brackets: [
                        { from: 0, to: 24000, rate: 0.1 },
                        { from: 24001, to: 32333, rate: 0.25 },
                        { from: 32334, to: 500000, rate: 0.3 },
                        { from: 500001, to: 800000, rate: 0.325 },
                        { from: 800001, to: null, rate: 0.35 },
                    ],
                    personalRelief: 2400,
                    insuranceRelief: 0.15,
                    maxInsuranceRelief: 5000,
                },
                paymentDeadline: '9th of following month',
                notes: 'PAYE rates effective July 1, 2023',
            },
            {
                taxType: tax_config_entity_1.TaxType.SHIF,
                rateType: tax_config_entity_1.RateType.PERCENTAGE,
                effectiveFrom: new Date('2024-10-01'),
                effectiveTo: undefined,
                configuration: {
                    percentage: 0.0275,
                    minAmount: 300,
                    maxAmount: undefined,
                },
                paymentDeadline: '9th of following month',
                notes: 'SHIF 2.75% of gross salary, min KES 300, no cap. Replaced NHIF Oct 1, 2024',
            },
            {
                taxType: tax_config_entity_1.TaxType.NSSF_TIER1,
                rateType: tax_config_entity_1.RateType.TIERED,
                effectiveFrom: new Date('2025-02-01'),
                effectiveTo: undefined,
                configuration: {
                    tiers: [
                        {
                            name: 'Tier I',
                            salaryFrom: 0,
                            salaryTo: 8000,
                            rate: 0.06,
                        },
                    ],
                },
                paymentDeadline: '9th of following month',
                notes: 'NSSF Tier I: 6% of first KES 8,000 (KES 480 each party)',
            },
            {
                taxType: tax_config_entity_1.TaxType.NSSF_TIER2,
                rateType: tax_config_entity_1.RateType.TIERED,
                effectiveFrom: new Date('2025-02-01'),
                effectiveTo: undefined,
                configuration: {
                    tiers: [
                        {
                            name: 'Tier II',
                            salaryFrom: 8001,
                            salaryTo: 72000,
                            rate: 0.06,
                        },
                    ],
                },
                paymentDeadline: '9th of following month',
                notes: 'NSSF Tier II: 6% of KES 8,001-72,000 (max KES 3,840 each party)',
            },
            {
                taxType: tax_config_entity_1.TaxType.HOUSING_LEVY,
                rateType: tax_config_entity_1.RateType.PERCENTAGE,
                effectiveFrom: new Date('2024-03-19'),
                effectiveTo: undefined,
                configuration: {
                    percentage: 0.015,
                    minAmount: undefined,
                    maxAmount: undefined,
                },
                paymentDeadline: '9th working day after end of month',
                notes: 'Housing Levy: 1.5% employee + 1.5% employer. Fully tax-deductible from Dec 27, 2024',
            },
        ];
        for (const configData of configs) {
            await this.createTaxConfig(configData);
        }
    }
};
exports.TaxConfigService = TaxConfigService;
exports.TaxConfigService = TaxConfigService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(tax_config_entity_1.TaxConfig)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], TaxConfigService);
//# sourceMappingURL=tax-config.service.js.map