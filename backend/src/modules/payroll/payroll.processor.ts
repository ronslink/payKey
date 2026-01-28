import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PayrollService } from './payroll.service';

export interface PayrollJobData {
  userId: string;
  payPeriodId: string;
  skipPayout: boolean;
}

@Processor('payroll-processing')
export class PayrollProcessor extends WorkerHost {
  private readonly logger = new Logger(PayrollProcessor.name);

  constructor(private readonly payrollService: PayrollService) {
    super();
  }

  async process(job: Job<PayrollJobData>): Promise<any> {
    this.logger.log(
      `Processing payroll job ${job.id} for period ${job.data.payPeriodId}`,
    );

    try {
      switch (job.name) {
        case 'finalize-payroll':
          return await this.handlePayrollFinalization(job);
        case 'check-payout-status':
          return await this.handlePayoutStatusCheck(job);
        default:
          this.logger.warn(`Unknown job type: ${job.name}`);
          return { status: 'ignored', reason: `Unknown job type: ${job.name}` };
      }
    } catch (error) {
      this.logger.error(`Payroll job ${job.id} failed:`, error.message);
      throw error; // Let BullMQ handle retries
    }
  }

  private async handlePayrollFinalization(job: Job<PayrollJobData>) {
    await job.updateProgress(10);

    const result = await this.payrollService.executePayrollFinalization(
      job.data.userId,
      job.data.payPeriodId,
      job.data.skipPayout,
    );

    await job.updateProgress(100);
    this.logger.log(`Payroll job ${job.id} completed successfully`);

    return result;
  }

  private async handlePayoutStatusCheck(job: Job<any>) {
    const { trackingId, payPeriodId, userId } = job.data;
    this.logger.log(`Checking payout status for tracking ID: ${trackingId}`);

    // This will be wired to IntaSendService.checkPayoutStatus
    // For now, return that status check is delegated to webhook
    return {
      status: 'delegated',
      message: 'Payout status updates handled via webhook',
      trackingId,
    };
  }
}
