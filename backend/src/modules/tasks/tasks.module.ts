import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { TaxesModule } from '../taxes/taxes.module';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([PayPeriod, LeaveRequest]),
        TaxesModule,
        ActivitiesModule, // Just in case we need it later, though not used yet
    ],
    controllers: [TasksController],
    providers: [TasksService],
})
export class TasksModule { }
