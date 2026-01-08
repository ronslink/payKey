import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DataDeletionService } from './data-deletion.service';

@Injectable()
export class DataDeletionScheduler {
  private readonly logger = new Logger(DataDeletionScheduler.name);

  constructor(private readonly dataDeletionService: DataDeletionService) {}

  /**
   * Process pending deletion requests every hour
   */
  @Cron(CronExpression.EVERY_HOUR)
  async handlePendingDeletions() {
    this.logger.log('Running scheduled deletion request processing...');
    try {
      await this.dataDeletionService.processPendingRequests();
      this.logger.log('Scheduled deletion processing completed');
    } catch (error) {
      this.logger.error(
        `Scheduled deletion processing failed: ${error.message}`,
      );
    }
  }
}
