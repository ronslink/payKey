import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PayrollController } from './payroll.controller';
import { PayrollService } from './payroll.service';
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
import { BullModule } from '@nestjs/bullmq';
import { PayrollProcessor } from './payroll.processor';

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
    BullModule.registerQueue({
      name: 'payroll-processing',
    }),
  ],
  controllers: [
    PayrollController,
    PayrollRecordsController,
    PayPeriodsController,
  ],
  providers: [
    PayrollService,
    PayPeriodsService,
    PayslipService,
    PayrollProcessor,
  ],
  exports: [PayrollService, PayPeriodsService],
})
export class PayrollModule { }
