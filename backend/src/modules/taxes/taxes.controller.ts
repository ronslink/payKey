import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { TaxesService } from './taxes.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { TaxTable } from './entities/tax-table.entity';

class CalculateTaxDto {
  grossSalary: number;
}

class CalculateGrossUpDto {
  targetNet: number;
}

@Controller('taxes')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TaxesController {
  constructor(private readonly taxesService: TaxesService) { }

  @Post('calculate')
  calculateTaxes(@Body() dto: CalculateTaxDto) {
    return this.taxesService.calculateTaxes(dto.grossSalary);
  }

  @Post('gross-up')
  async calculateGrossFromNet(@Body() dto: CalculateGrossUpDto) {
    const targetNet = Number(dto.targetNet);
    if (!isFinite(targetNet) || targetNet <= 0) {
      throw new BadRequestException('targetNet must be a positive number');
    }
    const grossSalary = await this.taxesService.calculateGrossFromNet(targetNet);
    const taxBreakdown = await this.taxesService.calculateTaxes(grossSalary);

    return {
      targetNet,
      grossSalary,
      taxBreakdown,
    };
  }

  @Post('tables')
  @Roles(UserRole.ADMIN)
  async createTaxTable(@Body() taxTableData: Partial<TaxTable>) {
    return this.taxesService.createTaxTable(taxTableData);
  }

  @Get('compliance')
  getComplianceStatus(@Request() req: any) {
    return this.taxesService.getComplianceStatus(req.user.userId);
  }

  @Get('deadlines')
  getUpcomingDeadlines() {
    return this.taxesService.getUpcomingDeadlines();
  }

  @Get('tables')
  @Roles(UserRole.ADMIN)
  async getTaxTables() {
    return this.taxesService.getTaxTables();
  }

  @Get('submissions')
  getSubmissions(@Request() req: any) {
    return this.taxesService.getSubmissions(req.user.userId);
  }

  @Get('submissions/monthly')
  getMonthlySummaries(@Request() req: any) {
    return this.taxesService.getMonthlySummaries(req.user.userId);
  }

  @Post('submissions/monthly/file')
  markMonthAsFiled(
    @Request() req: any,
    @Body() body: { year: number; month: number },
  ) {
    return this.taxesService.markMonthAsFiled(
      req.user.userId,
      body.year,
      body.month,
    );
  }

  @Post('submissions/generate/:payPeriodId')
  generateTaxSubmission(
    @Request() req: any,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.taxesService.generateTaxSubmission(
      payPeriodId,
      req.user.userId,
    );
  }

  @Get('submissions/period/:payPeriodId')
  getTaxSubmissionByPeriod(
    @Request() req: any,
    @Param('payPeriodId') payPeriodId: string,
  ) {
    return this.taxesService.getTaxSubmissionByPeriod(
      payPeriodId,
      req.user.userId,
    );
  }

  @Patch('submissions/:id/file')
  markAsFiled(@Request() req: any, @Param('id') id: string) {
    return this.taxesService.markAsFiled(id, req.user.userId);
  }

  @Get('current')
  async getCurrentTaxTable() {
    return this.taxesService.getTaxTable(new Date());
  }
}
