import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DataDeletionController } from './data-deletion.controller';
import { DataDeletionService } from './data-deletion.service';
import { DataDeletionScheduler } from './data-deletion.scheduler';
import { DeletionRequest } from './entities/deletion-request.entity';
import { User } from '../users/entities/user.entity';
import { Worker } from '../workers/entities/worker.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TimeEntry } from '../time-tracking/entities/time-entry.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { Property } from '../properties/entities/property.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      DeletionRequest,
      User,
      Worker,
      PayPeriod,
      PayrollRecord,
      TimeEntry,
      LeaveRequest,
      Property,
      Transaction,
      Subscription,
    ]),
  ],
  controllers: [DataDeletionController],
  providers: [DataDeletionService, DataDeletionScheduler],
  exports: [DataDeletionService],
})
export class DataDeletionModule {}
