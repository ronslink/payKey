import { Controller, Get, Query, UseGuards, Request, Res, StreamableFile } from '@nestjs/common';
import type { Response } from 'express';
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

  @Get('p9')
  async getP9Report(
    @Request() req: any,
    @Query('year') year: string,
    @Query('workerId') workerId?: string,
  ) {
    return this.reportsService.getP9Report(req.user.userId, parseInt(year), workerId);
  }

  @Get('p10')
  async getP10Report(@Request() req: any, @Query('year') year: string) {
    return this.reportsService.getP10Report(req.user.userId, parseInt(year));
  }

  @Get('my-p9')
  async getEmployeeP9Report(@Request() req: any, @Query('year') year: string) {
    return this.reportsService.getEmployeeP9Report(req.user.userId, parseInt(year));
  }

  @Get('my-p9/pdf')
  async getEmployeeP9Pdf(
    @Request() req: any,
    @Query('year') year: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const reports = await this.reportsService.getEmployeeP9Report(
      req.user.userId,
      parseInt(year),
    );
    const buffer = await this.reportsService.generateP9Pdf(reports[0]);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="P9_${year}.pdf"`,
    });

    return new StreamableFile(buffer);
  }

  @Get('p9/zip')
  async getP9Zip(
    @Request() req: any,
    @Query('year') year: string,
    @Res() res: Response,
  ) {
    const { stream, filename } = await this.reportsService.generateP9Zip(
      req.user.userId,
      parseInt(year),
    );

    res.set({
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename="${filename}"`,
    });

    stream.pipe(res);
  }
}
