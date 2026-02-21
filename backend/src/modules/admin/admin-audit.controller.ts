import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { AdminService } from './admin.service';

@Controller('api/admin/audit-logs')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminAuditController {
  constructor(private readonly adminService: AdminService) {}

  @Get()
  getAuditLogs(
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('entityType') entityType?: string,
    @Query('action') action?: string,
    @Query('adminEmail') adminEmail?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.adminService.getAuditLogs({
      page: parseInt(page),
      limit: parseInt(limit),
      entityType,
      action,
      adminEmail,
      startDate,
      endDate,
    });
  }
}
