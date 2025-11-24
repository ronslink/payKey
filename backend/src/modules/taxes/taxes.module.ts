import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TaxesController } from './taxes.controller';
import { TaxSubmissionController } from './tax-submission.controller';
import { TaxesService } from './taxes.service';
import { TaxTable } from './entities/tax-table.entity';
import { TaxSubmission } from './entities/tax-submission.entity';
import { UsersModule } from '../users/users.module';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
@Module({
  imports: [TypeOrmModule.forFeature([TaxTable, TaxSubmission, PayrollRecord]), UsersModule],
  controllers: [TaxesController, TaxSubmissionController],
  providers: [TaxesService],
  exports: [TaxesService],
})
export class TaxesModule { }
