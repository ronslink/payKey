import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TimeTrackingController } from './time-tracking.controller';
import { TimeTrackingService } from './time-tracking.service';
import { TimeEntry } from './entities/time-entry.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Property } from '../properties/entities/property.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TimeEntry, Worker, Property]),
    forwardRef(() => UsersModule),
  ],
  controllers: [TimeTrackingController],
  providers: [TimeTrackingService],
  exports: [TimeTrackingService],
})
export class TimeTrackingModule {}
