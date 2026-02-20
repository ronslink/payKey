import {
    Controller,
    Get,
    Query,
    Param,
    UseGuards,
    Logger,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { AdminService } from './admin.service';

@Controller('api/admin')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminController {
    private readonly logger = new Logger(AdminController.name);

    constructor(private readonly adminService: AdminService) { }

    // ─── Analytics ──────────────────────────────────────────────────────────────

    @Get('analytics/dashboard')
    async getDashboard() {
        return this.adminService.getDashboardMetrics();
    }

    @Get('analytics/infra')
    async getInfraHealth() {
        return this.adminService.getInfraHealth();
    }

    // ─── Users ──────────────────────────────────────────────────────────────────

    @Get('users')
    async getUsers(
        @Query('search') search?: string,
        @Query('page') page = '1',
        @Query('limit') limit = '20',
    ) {
        return this.adminService.getUsers(search, parseInt(page), parseInt(limit));
    }

    @Get('users/:id')
    async getUserDetail(@Param('id') id: string) {
        return this.adminService.getUserDetail(id);
    }

    // ─── Workers ────────────────────────────────────────────────────────────────

    @Get('workers')
    async getWorkers(
        @Query('search') search?: string,
        @Query('page') page = '1',
        @Query('limit') limit = '20',
    ) {
        return this.adminService.getWorkers(search, parseInt(page), parseInt(limit));
    }

    // ─── Transactions ───────────────────────────────────────────────────────────

    @Get('transactions')
    async getTransactions(
        @Query('search') search?: string,
        @Query('status') status?: string,
        @Query('type') type?: string,
        @Query('page') page = '1',
        @Query('limit') limit = '20',
    ) {
        return this.adminService.getTransactions({
            search,
            status,
            type,
            page: parseInt(page),
            limit: parseInt(limit),
        });
    }

    // ─── Payroll ────────────────────────────────────────────────────────────────

    @Get('payroll/dashboard')
    async getPayrollDashboard() {
        return this.adminService.getPayrollDashboard();
    }

    @Get('payroll/pay-periods')
    async getPayPeriods(
        @Query('search') search?: string,
        @Query('page') page = '1',
        @Query('limit') limit = '20',
    ) {
        return this.adminService.getPayPeriods(search, parseInt(page), parseInt(limit));
    }

    @Get('payroll/records/:payPeriodId')
    async getPayrollRecords(@Param('payPeriodId') payPeriodId: string) {
        return this.adminService.getPayrollRecords(payPeriodId);
    }

    // ─── Container Logs ─────────────────────────────────────────────────

    @Get('containers/logs')
    async getContainerLogs(
        @Query('container') container?: string,
        @Query('lines') lines = '100',
    ) {
        return this.adminService.getContainerLogs(container, parseInt(lines));
    }

    @Get('containers')
    async getContainers() {
        return this.adminService.getContainers();
    }
}
