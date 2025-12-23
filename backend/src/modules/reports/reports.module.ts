import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { User } from '../users/entities/user.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { TaxSubmission } from '../taxes/entities/tax-submission.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Worker,
      Transaction,
      LeaveRequest,
      User,
      PayrollRecord,
      PayPeriod,
      TaxSubmission,
    ]),
  ],
  controllers: [ReportsController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}
