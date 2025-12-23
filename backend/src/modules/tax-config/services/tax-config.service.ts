import { Injectable, Inject, Optional, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, MoreThanOrEqual, IsNull } from 'typeorm';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { TaxConfig, TaxType, RateType } from '../entities/tax-config.entity';

const TAX_CONFIG_CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours (tax rates rarely change)

@Injectable()
export class TaxConfigService {
  private readonly logger = new Logger(TaxConfigService.name);

  constructor(
    @InjectRepository(TaxConfig)
    private taxConfigRepository: Repository<TaxConfig>,
    @Optional() @Inject(CACHE_MANAGER) private cacheManager?: Cache,
  ) {}

  /**
   * Get active tax configuration for a specific date (with caching)
   */
  async getActiveTaxConfig(
    taxType: TaxType,
    date: Date = new Date(),
  ): Promise<TaxConfig | null> {
    // Cache key based on tax type and date (day granularity)
    const dateKey = date.toISOString().split('T')[0];
    const cacheKey = `tax:config:${taxType}:${dateKey}`;

    // Try cache first
    if (this.cacheManager) {
      const cached = await this.cacheManager.get<TaxConfig>(cacheKey);
      if (cached) {
        this.logger.debug(`Cache hit for ${taxType} tax config`);
        return cached;
      }
    }

    const config = await this.taxConfigRepository.findOne({
      where: [
        {
          taxType,
          effectiveFrom: LessThanOrEqual(date),
          effectiveTo: MoreThanOrEqual(date),
          isActive: true,
        },
        {
          taxType,
          effectiveFrom: LessThanOrEqual(date),
          effectiveTo: IsNull(),
          isActive: true,
        },
      ],
      order: {
        effectiveFrom: 'DESC',
      },
    });

    // Cache the result
    if (this.cacheManager && config) {
      await this.cacheManager.set(cacheKey, config, TAX_CONFIG_CACHE_TTL);
      this.logger.debug(`Cached ${taxType} tax config for 24 hours`);
    }

    return config;
  }

  /**
   * Get all active tax configurations for a date
   */
  async getAllActiveTaxConfigs(date: Date = new Date()): Promise<TaxConfig[]> {
    const taxTypes = Object.values(TaxType);
    const configs: TaxConfig[] = [];

    for (const taxType of taxTypes) {
      const config = await this.getActiveTaxConfig(taxType, date);
      if (config) {
        configs.push(config);
      }
    }

    return configs;
  }

  /**
   * Get tax configuration history for a specific type
   */
  async getTaxHistory(taxType: TaxType): Promise<TaxConfig[]> {
    return this.taxConfigRepository.find({
      where: { taxType },
      order: { effectiveFrom: 'DESC' },
    });
  }

  /**
   * Create new tax configuration
   */
  async createTaxConfig(configData: Partial<TaxConfig>): Promise<TaxConfig> {
    const config = this.taxConfigRepository.create(configData);
    return this.taxConfigRepository.save(config);
  }

  /**
   * Seed initial tax configurations for 2024/2025
   */
  async seedInitialConfigs(): Promise<void> {
    const existingConfigs = await this.taxConfigRepository.count();
    if (existingConfigs > 0) {
      return; // Already seeded
    }

    const configs: Partial<TaxConfig>[] = [
      // PAYE - Graduated rates
      {
        taxType: TaxType.PAYE,
        rateType: RateType.GRADUATED,
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

      // SHIF - Replaced NHIF October 1, 2024
      {
        taxType: TaxType.SHIF,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-10-01'),
        effectiveTo: undefined,
        configuration: {
          percentage: 0.0275,
          minAmount: 300,
          maxAmount: undefined,
        },
        paymentDeadline: '9th of following month',
        notes:
          'SHIF 2.75% of gross salary, min KES 300, no cap. Replaced NHIF Oct 1, 2024',
      },

      // NSSF Tier 1 - February 2025 rates
      {
        taxType: TaxType.NSSF_TIER1,
        rateType: RateType.TIERED,
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

      // NSSF Tier 2 - February 2025 rates
      {
        taxType: TaxType.NSSF_TIER2,
        rateType: RateType.TIERED,
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
        notes:
          'NSSF Tier II: 6% of KES 8,001-72,000 (max KES 3,840 each party)',
      },

      // Housing Levy
      {
        taxType: TaxType.HOUSING_LEVY,
        rateType: RateType.PERCENTAGE,
        effectiveFrom: new Date('2024-03-19'),
        effectiveTo: undefined,
        configuration: {
          percentage: 0.015,
          minAmount: undefined,
          maxAmount: undefined,
        },
        paymentDeadline: '9th working day after end of month',
        notes:
          'Housing Levy: 1.5% employee + 1.5% employer. Fully tax-deductible from Dec 27, 2024',
      },
    ];

    for (const configData of configs) {
      await this.createTaxConfig(configData);
    }
  }
}
