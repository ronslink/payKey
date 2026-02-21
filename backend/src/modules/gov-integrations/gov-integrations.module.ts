import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GovSubmission } from './entities/gov-submission.entity';
import { GovSubmissionsController } from './gov-submissions.controller';
import { KraService } from './services/kra.service';
import { ShifService } from './services/shif.service';
import { NssfService } from './services/nssf.service';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';

@Module({
  imports: [TypeOrmModule.forFeature([GovSubmission, PayrollRecord])],
  controllers: [GovSubmissionsController],
  providers: [KraService, ShifService, NssfService],
  exports: [KraService, ShifService, NssfService],
})
export class GovIntegrationsModule {}
