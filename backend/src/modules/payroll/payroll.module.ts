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
import { User } from '../users/entities/user.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';
import { TimeEntry } from '../time-tracking/entities/time-entry.entity';
import { PayPeriodsService } from './pay-periods.service';
import { PaymentsModule } from '../payments/payments.module';
import { TaxesModule } from '../taxes/taxes.module';
import { TaxPaymentsModule } from '../tax-payments/tax-payments.module';
import { PayslipService } from './payslip.service';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PayPeriod,
      PayrollRecord,
      Worker,
      User,
      LeaveRequest,
      Transaction,
      TaxSubmission,
      TimeEntry,
    ]),
    PaymentsModule,
    TaxesModule,
    TaxPaymentsModule,
    ActivitiesModule,
  ],
  controllers: [
    PayrollController,
    BatchPayrollController,
    PayrollRecordsController,
    PayPeriodsController,
  ],
  providers: [
    PayrollService,
    BatchPayrollService,
    PayPeriodsService,
    PayslipService,
  ],
  exports: [PayrollService, BatchPayrollService, PayPeriodsService],
})
export class PayrollModule {}
