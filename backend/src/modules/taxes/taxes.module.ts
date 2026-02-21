import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TaxesController } from './taxes.controller';
import { TaxSubmissionController } from './tax-submission.controller';
import { TaxesService } from './taxes.service';
import { TaxTable } from './entities/tax-table.entity';
import { TaxSubmission } from './entities/tax-submission.entity';
import { UsersModule } from '../users/users.module';
import { TaxConfigModule } from '../tax-config/tax-config.module';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TaxTable, TaxSubmission, PayrollRecord]),
    forwardRef(() => UsersModule),
    TaxConfigModule,
    ActivitiesModule,
  ],
  controllers: [TaxesController, TaxSubmissionController],
  providers: [TaxesService],
  exports: [TaxesService],
})
export class TaxesModule {}
