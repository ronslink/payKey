import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Param,
  UseGuards,
  Req,
  BadRequestException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, IsNull, Not } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import {
  DeletionRequest,
  DeletionStatus,
} from '../data-deletion/entities/deletion-request.entity';
import { DataDeletionService } from '../data-deletion/data-deletion.service';
import { AdminService } from './admin.service';
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from '../payments/entities/transaction.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { IntaSendService } from '../payments/intasend.service';

// ─── Cron job metadata (static — NestJS doesn't expose runtime state) ─────────

const CRON_JOBS = [
  {
    name: 'Exchange Rate Sync',
    description:
      'Fetches latest KES/USD exchange rates from the Central Bank of Kenya API',
    schedule: 'Every 4 hours',
    cronExpr: 'EVERY_4_HOURS',
    service: 'ExchangeRateService',
  },
  {
    name: 'Wallet Balance Sync',
    description:
      'Reconciles wallet balances against M-Pesa transaction records',
    schedule: 'Every hour',
    cronExpr: 'EVERY_HOUR',
    service: 'BalanceSyncTask',
  },
  {
    name: 'Campaign Dispatch',
    description:
      'Dispatches scheduled EMAIL and IN_APP_NOTIFICATION campaigns that are due',
    schedule: 'Every 15 minutes',
    cronExpr: '0 */15 * * * *',
    service: 'CampaignScheduler',
  },
  {
    name: 'Subscription Renewal',
    description: 'Queues renewal jobs for expired non-Stripe subscriptions',
    schedule: 'Daily at midnight',
    cronExpr: 'EVERY_DAY_AT_MIDNIGHT',
    service: 'SubscriptionScheduler',
  },
  {
    name: 'Account Deletion Processing',
    description:
      'Processes pending GDPR account deletion requests in FK-ordered sequence',
    schedule: 'Every hour',
    cronExpr: 'EVERY_HOUR',
    service: 'DataDeletionScheduler',
  },
];

@Controller('api/admin/operations')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminOperationsController {
  private readonly logger = new Logger(AdminOperationsController.name);

  constructor(
    @InjectRepository(DeletionRequest)
    private readonly deletionRepo: Repository<DeletionRequest>,
    @InjectRepository(Transaction)
    private readonly transactionRepo: Repository<Transaction>,
    @InjectRepository(PayrollRecord)
    private readonly payrollRecordRepo: Repository<PayrollRecord>,
    private readonly dataDeletionService: DataDeletionService,
    private readonly adminService: AdminService,
    private readonly intaSendService: IntaSendService,
    @InjectQueue('wallets') private readonly walletsQueue: Queue,
    @InjectQueue('subscriptions') private readonly subscriptionsQueue: Queue,
    @InjectQueue('payroll-processing') private readonly payrollQueue: Queue,
  ) {}

  // ─── Deletion Requests ──────────────────────────────────────────────────────

  @Get('deletion-requests')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async getDeletionRequests(
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('status') status?: DeletionStatus,
  ) {
    const qb = this.deletionRepo
      .createQueryBuilder('dr')
      .orderBy('dr.requestedAt', 'DESC')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit));

    if (status) {
      qb.where('dr.status = :status', { status });
    }

    const [data, total] = await qb.getManyAndCount();

    // Summary counts
    const counts = await this.deletionRepo
      .createQueryBuilder('dr')
      .select('dr.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .groupBy('dr.status')
      .getRawMany();

    const summary = Object.fromEntries(
      counts.map((r) => [r.status, parseInt(r.count)]),
    );

    return {
      data,
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      summary: {
        PENDING: summary.PENDING || 0,
        PROCESSING: summary.PROCESSING || 0,
        COMPLETED: summary.COMPLETED || 0,
        FAILED: summary.FAILED || 0,
      },
    };
  }

  @Post('deletion-requests')
  @Roles(UserRole.SUPER_ADMIN)
  async triggerDeletion(
    @Body() body: { email: string; reason?: string },
    @Req() req: any,
  ) {
    if (!body.email) {
      throw new BadRequestException('email is required');
    }

    const existing = await this.deletionRepo.findOne({
      where: {
        email: body.email.toLowerCase(),
        status: DeletionStatus.PENDING,
      },
    });

    if (existing) {
      throw new BadRequestException(
        'A pending deletion request already exists for this email',
      );
    }

    const request = await this.dataDeletionService.createRequest({
      email: body.email,
      reason: body.reason || 'Admin-initiated account deletion',
    });

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'CREATE',
      entityType: 'DELETION_REQUEST',
      entityId: request.id,
      oldValues: null,
      newValues: { email: body.email, reason: request.reason },
      ipAddress: req.ip,
    });

    return request;
  }

  @Post('deletion-requests/:id/retry')
  @Roles(UserRole.SUPER_ADMIN)
  async retryDeletion(@Param('id') id: string, @Req() req: any) {
    const request = await this.deletionRepo.findOne({ where: { id } });

    if (!request) {
      throw new NotFoundException('Deletion request not found');
    }

    if (request.status !== DeletionStatus.FAILED) {
      throw new BadRequestException('Only FAILED requests can be retried');
    }

    request.status = DeletionStatus.PENDING;
    request.errorMessage = '';
    await this.deletionRepo.save(request);

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'UPDATE',
      entityType: 'DELETION_REQUEST',
      entityId: request.id,
      oldValues: { status: DeletionStatus.FAILED },
      newValues: { status: DeletionStatus.PENDING },
      ipAddress: req.ip,
    });

    return {
      success: true,
      message: 'Request reset to PENDING for next scheduler run',
    };
  }

  // ─── Queue Monitor ─────────────────────────────────────────────────────────

  @Get('queues')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async getQueues() {
    const [walletsStats, subsStats, payrollStats] = await Promise.all([
      this.getQueueStats(this.walletsQueue, 'wallets'),
      this.getQueueStats(this.subscriptionsQueue, 'subscriptions'),
      this.getQueueStats(this.payrollQueue, 'payroll-processing'),
    ]);

    return [walletsStats, subsStats, payrollStats];
  }

  @Post('queues/:name/pause')
  @Roles(UserRole.SUPER_ADMIN)
  async pauseQueue(@Param('name') name: string, @Req() req: any) {
    const queue = this.resolveQueue(name);
    await queue.pause();

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'UPDATE',
      entityType: 'QUEUE',
      entityId: name,
      oldValues: { paused: false },
      newValues: { paused: true },
      ipAddress: req.ip,
    });

    return { success: true, message: `Queue "${name}" paused` };
  }

  @Post('queues/:name/resume')
  @Roles(UserRole.SUPER_ADMIN)
  async resumeQueue(@Param('name') name: string, @Req() req: any) {
    const queue = this.resolveQueue(name);
    await queue.resume();

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'UPDATE',
      entityType: 'QUEUE',
      entityId: name,
      oldValues: { paused: true },
      newValues: { paused: false },
      ipAddress: req.ip,
    });

    return { success: true, message: `Queue "${name}" resumed` };
  }

  @Post('queues/:name/drain')
  @Roles(UserRole.SUPER_ADMIN)
  async drainQueue(@Param('name') name: string, @Req() req: any) {
    const queue = this.resolveQueue(name);
    await queue.drain();

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'UPDATE',
      entityType: 'QUEUE',
      entityId: name,
      oldValues: null,
      newValues: { drained: true },
      ipAddress: req.ip,
    });

    return {
      success: true,
      message: `Queue "${name}" drained (waiting jobs removed)`,
    };
  }

  // ─── Cron Jobs ─────────────────────────────────────────────────────────────

  @Get('cron-jobs')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  getCronJobs() {
    return CRON_JOBS;
  }

  // ─── Transaction Sync ──────────────────────────────────────────────────────

  /**
   * GET /api/admin/operations/transactions/pending
   * Returns all transactions stuck in PENDING state for admin review.
   */
  @Get('transactions/pending')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  async getPendingTransactions() {
    const pending = await this.transactionRepo.find({
      where: { status: TransactionStatus.PENDING },
      order: { createdAt: 'DESC' },
    });

    const summary = {
      total: pending.length,
      salaryPayouts: pending.filter((t) => t.type === TransactionType.SALARY_PAYOUT).length,
      deposits: pending.filter((t) => t.type === TransactionType.DEPOSIT).length,
      withProviderRef: pending.filter((t) => !!t.providerRef).length,
      simulationOrTest: pending.filter(
        (t) =>
          t.providerRef?.startsWith('MR_SIM_') ||
          t.providerRef?.startsWith('TRK_SIM_') ||
          t.providerRef?.startsWith('TEST_'),
      ).length,
    };

    return { summary, transactions: pending };
  }

  /**
   * POST /api/admin/operations/transactions/sync
   * Syncs all PENDING SALARY_PAYOUT transactions with IntaSend API.
   * For each unique trackingId, queries IntaSend and updates status.
   * Also marks simulation/test deposits as FAILED (they will never resolve).
   */
  @Post('transactions/sync')
  @Roles(UserRole.SUPER_ADMIN)
  async syncPendingTransactions(@Req() req: any) {
    const results = {
      synced: [] as any[],
      cleaned: [] as any[],
      errors: [] as any[],
      skipped: [] as any[],
    };

    // 1. Find all PENDING transactions
    const pendingTransactions = await this.transactionRepo.find({
      where: { status: TransactionStatus.PENDING },
    });

    this.logger.log(`Found ${pendingTransactions.length} PENDING transactions to process`);

    // 2. Clean up simulation/test deposits (will never resolve via webhook)
    const staleTestTxns = pendingTransactions.filter(
      (t) =>
        t.providerRef?.startsWith('MR_SIM_') ||
        t.providerRef?.startsWith('TRK_SIM_') ||
        t.providerRef?.startsWith('INV_SIM_') ||
        t.providerRef?.startsWith('TEST_') ||
        (!t.providerRef && t.type === TransactionType.DEPOSIT),
    );

    if (staleTestTxns.length > 0) {
      await this.transactionRepo.update(
        { id: In(staleTestTxns.map((t) => t.id)) },
        { status: TransactionStatus.FAILED, metadata: () => `metadata || '{"cleanedBy":"admin-sync","reason":"stale_test_or_no_ref"}'::jsonb` },
      );
      results.cleaned = staleTestTxns.map((t) => ({
        id: t.id,
        type: t.type,
        amount: t.amount,
        providerRef: t.providerRef,
        reason: 'stale_test_or_no_ref',
      }));
      this.logger.log(`Cleaned ${staleTestTxns.length} stale test/simulation transactions`);
    }

    // 3. Sync real SALARY_PAYOUT transactions via IntaSend API
    const realPayoutTxns = pendingTransactions.filter(
      (t) =>
        t.type === TransactionType.SALARY_PAYOUT &&
        t.providerRef &&
        !t.providerRef.startsWith('TRK_SIM_'),
    );

    // Group by providerRef (trackingId) to avoid duplicate API calls
    const byTrackingId = new Map<string, Transaction[]>();
    for (const tx of realPayoutTxns) {
      const existing = byTrackingId.get(tx.providerRef) || [];
      existing.push(tx);
      byTrackingId.set(tx.providerRef, existing);
    }

    for (const [trackingId, txns] of byTrackingId.entries()) {
      try {
        const intaSendStatus = await this.intaSendService.checkPayoutStatus(trackingId);
        const batchStatus = (
          intaSendStatus?.file_status ||
          intaSendStatus?.status ||
          'unknown'
        ).toLowerCase();

        this.logger.log(`IntaSend status for ${trackingId}: ${batchStatus}`);

        let newStatus: TransactionStatus | null = null;
        let newPaymentStatus: string | null = null;

        if (batchStatus === 'completed' || batchStatus === 'successful') {
          newStatus = TransactionStatus.SUCCESS;
          newPaymentStatus = 'paid';
        } else if (batchStatus === 'failed' || batchStatus === 'cancelled') {
          newStatus = TransactionStatus.FAILED;
          newPaymentStatus = 'failed';
        } else {
          // Still processing — check individual transactions within the batch
          const transactions = intaSendStatus?.transactions || [];
          const allDone = transactions.length > 0 &&
            transactions.every((t: any) =>
              ['successful', 'completed'].includes((t.status || '').toLowerCase()),
            );
          if (allDone) {
            newStatus = TransactionStatus.SUCCESS;
            newPaymentStatus = 'paid';
          }
        }

        if (newStatus) {
          // Update transactions
          await this.transactionRepo.update(
            { id: In(txns.map((t) => t.id)) },
            {
              status: newStatus,
              metadata: () => `metadata || '{"syncedBy":"admin-sync","intaSendStatus":"${batchStatus}"}'::jsonb`,
            },
          );

          // Update associated payroll records
          const payrollRecordIds = txns
            .map((t) => t.metadata?.payrollRecordId)
            .filter(Boolean);

          if (payrollRecordIds.length > 0 && newPaymentStatus) {
            await this.payrollRecordRepo.update(
              { id: In(payrollRecordIds) },
              {
                paymentStatus: newPaymentStatus,
                ...(newPaymentStatus === 'paid' ? { paymentDate: new Date() } : {}),
              },
            );
          }

          results.synced.push({
            trackingId,
            transactionCount: txns.length,
            newStatus,
            newPaymentStatus,
            intaSendStatus: batchStatus,
          });
        } else {
          results.skipped.push({
            trackingId,
            transactionCount: txns.length,
            reason: `Still processing (status: ${batchStatus})`,
            intaSendStatus: batchStatus,
          });
        }
      } catch (error) {
        this.logger.error(`Failed to sync ${trackingId}: ${error.message}`);
        results.errors.push({
          trackingId,
          transactionCount: txns.length,
          error: error.message,
        });
      }
    }

    // 4. Sync real DEPOSIT transactions with a providerRef (non-simulation)
    const realDepositTxns = pendingTransactions.filter(
      (t) =>
        t.type === TransactionType.DEPOSIT &&
        t.providerRef &&
        !t.providerRef.startsWith('MR_SIM_') &&
        !t.providerRef.startsWith('TRK_SIM_') &&
        !t.providerRef.startsWith('TEST_'),
    );

    for (const tx of realDepositTxns) {
      try {
        // For deposits, check STK push status via the invoice/tracking ID
        const intaSendStatus = await this.intaSendService.checkPayoutStatus(tx.providerRef);
        const rawStatus = (intaSendStatus?.status || intaSendStatus?.invoice?.state || 'unknown').toLowerCase();

        if (['completed', 'successful', 'complete'].includes(rawStatus)) {
          await this.transactionRepo.update(
            { id: tx.id },
            { status: TransactionStatus.SUCCESS },
          );
          results.synced.push({
            trackingId: tx.providerRef,
            type: 'DEPOSIT',
            newStatus: TransactionStatus.SUCCESS,
            intaSendStatus: rawStatus,
          });
        } else if (['failed', 'cancelled'].includes(rawStatus)) {
          await this.transactionRepo.update(
            { id: tx.id },
            { status: TransactionStatus.FAILED },
          );
          results.synced.push({
            trackingId: tx.providerRef,
            type: 'DEPOSIT',
            newStatus: TransactionStatus.FAILED,
            intaSendStatus: rawStatus,
          });
        } else {
          results.skipped.push({
            trackingId: tx.providerRef,
            type: 'DEPOSIT',
            reason: `Status: ${rawStatus}`,
          });
        }
      } catch (error) {
        results.errors.push({
          trackingId: tx.providerRef,
          type: 'DEPOSIT',
          error: error.message,
        });
      }
    }

    this.adminService.logAction({
      adminUserId: req.user.userId,
      action: 'UPDATE',
      entityType: 'TRANSACTION',
      entityId: 'bulk-sync',
      oldValues: null,
      newValues: {
        synced: results.synced.length,
        cleaned: results.cleaned.length,
        errors: results.errors.length,
        skipped: results.skipped.length,
      },
      ipAddress: req.ip,
    });

    return {
      success: true,
      summary: {
        synced: results.synced.length,
        cleaned: results.cleaned.length,
        errors: results.errors.length,
        skipped: results.skipped.length,
      },
      details: results,
    };
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  private async getQueueStats(queue: Queue, name: string) {
    const [waiting, active, completed, failed, delayed, paused] =
      await Promise.all([
        queue.getWaitingCount(),
        queue.getActiveCount(),
        queue.getCompletedCount(),
        queue.getFailedCount(),
        queue.getDelayedCount(),
        queue.isPaused(),
      ]);

    return {
      name,
      waiting,
      active,
      completed,
      failed,
      delayed,
      paused,
    };
  }

  private resolveQueue(name: string): Queue {
    switch (name) {
      case 'wallets':
        return this.walletsQueue;
      case 'subscriptions':
        return this.subscriptionsQueue;
      case 'payroll-processing':
        return this.payrollQueue;
      default:
        throw new BadRequestException(`Unknown queue: ${name}`);
    }
  }
}
