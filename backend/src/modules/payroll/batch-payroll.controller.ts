import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { BatchPayrollService } from './batch-payroll.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('payroll/batch')
@UseGuards(JwtAuthGuard)
export class BatchPayrollController {
  constructor(private readonly batchPayrollService: BatchPayrollService) {}

  @Post('process')
  async processBatchPayroll(
    @Request() req: AuthenticatedRequest,
    @Body() body: { workerIds: string[]; processDate?: string },
  ) {
    const processDate = body.processDate
      ? new Date(body.processDate)
      : new Date();
    return this.batchPayrollService.processBatchPayroll(req.user.userId, {
      workerIds: body.workerIds,
      processDate,
    });
  }

  @Get('status/:batchId')
  async getBatchStatus(
    @Request() req: AuthenticatedRequest,
    @Param('batchId') batchId: string,
  ) {
    return this.batchPayrollService.getBatchPayrollStatus(
      batchId,
      req.user.userId,
    );
  }

  @Get('history')
  async getPayrollHistory(@Request() req: AuthenticatedRequest) {
    return this.batchPayrollService.getUserPayrollHistory(req.user.userId);
  }
}
