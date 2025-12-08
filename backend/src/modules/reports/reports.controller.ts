import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) { }

  @Get('payroll')
  async getMonthlyPayrollReport(
    @Request() req: any,
    @Query('year') year: string,
    @Query('month') month: string,
  ) {
    return this.reportsService.getMonthlyPayrollReport(
      req.user.userId,
      parseInt(year),
      parseInt(month),
    );
  }

  @Get('workers')
  async getWorkersSummary(@Request() req: any) {
    return this.reportsService.getWorkersSummary(req.user.userId);
  }

  @Get('leave')
  async getLeaveReport(@Request() req: any, @Query('year') year: string) {
    return this.reportsService.getLeaveReport(req.user.userId, parseInt(year));
  }

  @Get('tax')
  async getTaxSummary(@Request() req: any, @Query('year') year: string) {
    return this.reportsService.getTaxSummary(req.user.userId, parseInt(year));
  }

  @Get('payroll-summary')
  async getPayrollSummary(
    @Request() req: any,
    @Query('payPeriodId') payPeriodId: string,
  ) {
    return this.reportsService.getPayrollSummaryByPeriod(
      req.user.userId,
      payPeriodId,
    );
  }

  @Get('statutory')
  async getStatutoryReport(
    @Request() req: any,
    @Query('payPeriodId') payPeriodId: string,
  ) {
    return this.reportsService.getStatutoryReport(
      req.user.userId,
      payPeriodId,
    );
  }

  @Get('muster-roll')
  async getMasterRoll(
    @Request() req: any,
    @Query('payPeriodId') payPeriodId: string,
  ) {
    return this.reportsService.getMasterRoll(
      req.user.userId,
      payPeriodId,
    );
  }

  @Get('dashboard')
  async getDashboardMetrics(@Request() req: any) {
    return this.reportsService.getDashboardMetrics(req.user.userId);
  }
}
