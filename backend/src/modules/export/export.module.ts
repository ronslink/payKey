import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Export } from './entities/export.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { ExportService } from './services/export.service';
import { ExportController } from './controllers/export.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Export, Transaction, PayrollRecord])],
  controllers: [ExportController],
  providers: [ExportService],
  exports: [ExportService],
})
export class ExportModule { }
