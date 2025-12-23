import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TestingService } from './testing.service';
import { TestingController } from './testing.controller';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { TaxPayment } from '../tax-payments/entities/tax-payment.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PayPeriod,
      PayrollRecord,
      TaxSubmission,
      TaxPayment,
      User,
    ]),
  ],
  controllers: [TestingController],
  providers: [TestingService],
})
export class TestingModule {}
