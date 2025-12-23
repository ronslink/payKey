import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { WorkersService } from './workers.service';
import { WorkersController } from './workers.controller';
import { Worker } from './entities/worker.entity';
import { Termination } from './entities/termination.entity';
import { LeaveRequest } from './entities/leave-request.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { User } from '../users/entities/user.entity';
import { TerminationService } from './services/termination.service';
import { LeaveManagementService } from './services/leave-management.service';
import { EmployeePortalService } from './services/employee-portal.service';
import { EmployeePortalController } from './controllers/employee-portal.controller';
import { TaxesModule } from '../taxes/taxes.module';
import { UsersModule } from '../users/users.module';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Worker,
      Termination,
      LeaveRequest,
      PayrollRecord,
      PayPeriod,
      User,
    ]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET', 'your-secret-key'),
        signOptions: { expiresIn: '7d' },
      }),
      inject: [ConfigService],
    }),
    TaxesModule,
    UsersModule,
    ActivitiesModule,
  ],
  controllers: [WorkersController, EmployeePortalController],
  providers: [
    WorkersService,
    TerminationService,
    LeaveManagementService,
    EmployeePortalService,
  ],
  exports: [WorkersService, EmployeePortalService],
})
export class WorkersModule {}
