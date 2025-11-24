import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkersService } from './workers.service';
import { WorkersController } from './workers.controller';
import { Worker } from './entities/worker.entity';
import { Termination } from './entities/termination.entity';
import { TerminationService } from './services/termination.service';
import { TaxesModule } from '../taxes/taxes.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([Worker, Termination]), TaxesModule, UsersModule],
  controllers: [WorkersController],
  providers: [WorkersService, TerminationService],
  exports: [WorkersService],
})
export class WorkersModule {}
