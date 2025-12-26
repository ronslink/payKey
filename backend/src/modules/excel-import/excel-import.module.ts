import { Module } from '@nestjs/common';
import { ExcelImportController } from './excel-import.controller';
import { ExcelImportService } from './excel-import.service';
import { WorkersModule } from '../workers/workers.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [WorkersModule, UsersModule],
  controllers: [ExcelImportController],
  providers: [ExcelImportService],
})
export class ExcelImportModule {}
