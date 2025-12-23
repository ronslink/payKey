import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { TaxConfigService } from '../services/tax-config.service';
import { TaxConfig, TaxType } from '../entities/tax-config.entity';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';

@Controller('tax-config')
@UseGuards(JwtAuthGuard)
export class TaxConfigController {
  constructor(private readonly taxConfigService: TaxConfigService) { }

  @Get('active')
  async getActiveTaxConfigs(): Promise<TaxConfig[]> {
    return this.taxConfigService.getAllActiveTaxConfigs();
  }

  @Get('history/:taxType')
  async getTaxHistory(@Body('taxType') taxType: TaxType): Promise<TaxConfig[]> {
    return this.taxConfigService.getTaxHistory(taxType);
  }

  @Post('seed')
  async seedInitialConfigs(): Promise<{ message: string }> {
    await this.taxConfigService.seedInitialConfigs();
    return { message: 'Tax configurations seeded successfully' };
  }

  @Post()
  async create(@Body() createTaxConfigDto: Partial<TaxConfig>): Promise<TaxConfig> {
    return this.taxConfigService.createTaxConfig(createTaxConfigDto);
  }
}
