import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { PayrollService } from './payroll.service';

@Processor('payouts')
export class PayrollProcessor {
  private readonly logger = new Logger(PayrollProcessor.name);

  constructor(private readonly payrollService: PayrollService) {}

  @Process('process-payout')
  async handlePayrollProcessing(
    job: Job<{ userId: string; payPeriodId: string; skipPayout: boolean }>,
  ) {
    this.logger.log(
      `Processing payroll job ${job.id} for period ${job.data.payPeriodId}`,
    );

    try {
      await this.payrollService.executePayrollFinalization(
        job.data.userId,
        job.data.payPeriodId,
        job.data.skipPayout,
      );
      this.logger.log(`Payroll job ${job.id} completed successfully`);
    } catch (error) {
      this.logger.error(`Payroll job ${job.id} failed:`, error.message);
      throw error; // Let Bull handle retries if configured
    }
  }
}
