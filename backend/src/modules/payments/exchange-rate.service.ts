import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ExchangeRate } from './entities/exchange-rate.entity';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class ExchangeRateService {
  private readonly logger = new Logger(ExchangeRateService.name);
  // In-memory cache for fast lookup
  private rateCache: Map<string, number> = new Map();

  constructor(
    @InjectRepository(ExchangeRate)
    private rateRepository: Repository<ExchangeRate>,
    private configService: ConfigService,
    private httpService: HttpService,
  ) {}

  /**
   * Get the latest exchange rate for a pair
   * Tries cache first, then DB, then Error
   */
  async getLatestRate(source: string, target: string): Promise<number> {
    const key = `${source}_${target}`;

    // 1. Check Cache
    if (this.rateCache.has(key)) {
      return this.rateCache.get(key)!;
    }

    // 2. Check DB (Last Success)
    const rate = await this.rateRepository.findOne({
      where: { sourceCurrency: source, targetCurrency: target },
      order: { createdAt: 'DESC' },
    });

    if (rate) {
      const val = Number(rate.rate);
      this.rateCache.set(key, val);
      return val;
    }

    this.logger.warn(`No exchange rate found for ${source}/${target}.`);
    if (source === target) return 1;
    throw new Error(`Exchange rate not found for ${source}->${target}`);
  }

  /**
   * Update exchange rates periodically
   * Every 4 hours = 6 times a day (covering the requested 5)
   */
  @Cron(CronExpression.EVERY_4_HOURS)
  async fetchAndStoreRates() {
    this.logger.log('Fetching latest exchange rates...');
    try {
      // Fetch EUR-based rates
      const eurResponse = await lastValueFrom(
        this.httpService.get('https://api.exchangerate-api.com/v4/latest/EUR'),
      );

      const eurRates = eurResponse.data.rates;
      const eurToKes = eurRates['KES'];
      const eurToUsd = eurRates['USD'];

      if (eurToKes) {
        // Save EUR -> KES
        await this.rateRepository.save({
          sourceCurrency: 'EUR',
          targetCurrency: 'KES',
          rate: eurToKes,
        });
        this.rateCache.set('EUR_KES', eurToKes);
        this.logger.log(`Updated EUR->KES rate: ${eurToKes}`);
      }

      // Calculate and save USD -> KES (since Stripe uses USD)
      if (eurToKes && eurToUsd) {
        const usdToKes = eurToKes / eurToUsd;
        await this.rateRepository.save({
          sourceCurrency: 'USD',
          targetCurrency: 'KES',
          rate: usdToKes,
        });
        this.rateCache.set('USD_KES', usdToKes);
        this.logger.log(`Updated USD->KES rate: ${usdToKes}`);
      }

      // Also fetch direct USD rates for accuracy
      try {
        const usdResponse = await lastValueFrom(
          this.httpService.get('https://api.exchangerate-api.com/v4/latest/USD'),
        );
        const usdRates = usdResponse.data.rates;
        const usdToKesDirect = usdRates['KES'];
        
        if (usdToKesDirect) {
          await this.rateRepository.save({
            sourceCurrency: 'USD',
            targetCurrency: 'KES',
            rate: usdToKesDirect,
          });
          this.rateCache.set('USD_KES', usdToKesDirect);
          this.logger.log(`Updated USD->KES rate (direct): ${usdToKesDirect}`);
        }
      } catch (usdError) {
        this.logger.warn('Could not fetch direct USD rates, using calculated rate');
      }

    } catch (e) {
      this.logger.error(
        'Failed to update rates. Using last successful rate.',
        e,
      );
      // System naturally falls back to DB/Cache on failure
    }
  }

  // Initial fetch on startup
  async onModuleInit() {
    await this.fetchAndStoreRates();
  }
}
