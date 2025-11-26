import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkersService } from './workers.service';
import { WorkersController } from './workers.controller';
import { Worker } from './entities/worker.entity';
import { Termination } from './entities/termination.entity';
import { LeaveRequest } from './entities/leave-request.entity';
import { TerminationService } from './services/termination.service';
import { LeaveManagementService } from './services/leave-management.service';
import { TaxesModule } from '../taxes/taxes.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([Worker, Termination, LeaveRequest]), TaxesModule, UsersModule],
  controllers: [WorkersController],
  providers: [WorkersService, TerminationService, LeaveManagementService],
  exports: [WorkersService],
})
export class WorkersModule {}
