import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TaxConfig } from './entities/tax-config.entity';
import { TaxConfigService } from './services/tax-config.service';
import { TaxConfigController } from './controllers/tax-config.controller';

@Module({
  imports: [TypeOrmModule.forFeature([TaxConfig])],
  controllers: [TaxConfigController],
  providers: [TaxConfigService],
  exports: [TaxConfigService],
})
export class TaxConfigModule {}
