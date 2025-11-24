import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PayrollController } from './payroll.controller';
import { PayrollService } from './payroll.service';
import { BatchPayrollController } from './batch-payroll.controller';
import { BatchPayrollService } from './batch-payroll.service';
import { PayrollRecordsController } from './payroll-records.controller';
import { PayPeriodsController } from './pay-periods.controller';
import { PayPeriod } from './entities/pay-period.entity';
import { PayrollRecord } from './entities/payroll-record.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity'; // Added import
import { PayPeriodsService } from './pay-periods.service';
import { PaymentsModule } from '../payments/payments.module';
import { TaxesModule } from '../taxes/taxes.module';
import { TaxPaymentsModule } from '../tax-payments/tax-payments.module';
import { PayslipService } from './payslip.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([PayPeriod, PayrollRecord, Worker, Transaction, TaxSubmission]), // Added TaxSubmission
    PaymentsModule,
    TaxesModule,
    TaxPaymentsModule,
  ],
  controllers: [
    PayrollController,
    BatchPayrollController,
    PayrollRecordsController,
    PayPeriodsController,
  ],
  providers: [PayrollService, BatchPayrollService, PayPeriodsService, PayslipService],
  exports: [PayrollService, BatchPayrollService, PayPeriodsService],
})
export class PayrollModule { }
