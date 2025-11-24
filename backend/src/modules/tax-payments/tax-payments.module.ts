import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TaxPayment } from './entities/tax-payment.entity';
import { TaxPaymentsService } from './services/tax-payments.service';
import { TaxPaymentsController } from './controllers/tax-payments.controller';
import { TaxConfigModule } from '../tax-config/tax-config.module';
import { TaxesModule } from '../taxes/taxes.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TaxPayment]),
    TaxConfigModule,
    TaxesModule,
  ],
  controllers: [TaxPaymentsController],
  providers: [TaxPaymentsService],
  exports: [TaxPaymentsService],
})
export class TaxPaymentsModule {}
