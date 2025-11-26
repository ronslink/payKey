import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccountingController } from './accounting.controller';
import { AccountingExportService } from './accounting-export.service';
import { AccountMapping } from './entities/account-mapping.entity';
import { AccountingExport } from './entities/accounting-export.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([AccountMapping, AccountingExport, PayrollRecord]),
  ],
  controllers: [AccountingController],
  providers: [AccountingExportService],
  exports: [AccountingExportService],
})
export class AccountingModule {}
