import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentsController } from './payments.controller';
import { MpesaService } from './mpesa.service';
import { PayrollPaymentService } from './payroll-payment.service';
import { Transaction } from './entities/transaction.entity';
import { Worker } from '../workers/entities/worker.entity';
import { TaxesModule } from '../taxes/taxes.module';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { TimeTrackingModule } from '../time-tracking/time-tracking.module';

import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [
    TypeOrmModule.forFeature([Transaction, Worker, PayPeriod, PayrollRecord, TaxSubmission]),
    TaxesModule,
    TimeTrackingModule,
    HttpModule,
  ],
  controllers: [PaymentsController],
  providers: [MpesaService, PayrollPaymentService],
  exports: [MpesaService, PayrollPaymentService],
})
export class PaymentsModule { }
