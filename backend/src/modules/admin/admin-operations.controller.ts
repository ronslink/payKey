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
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { DeletionRequest, DeletionStatus } from '../data-deletion/entities/deletion-request.entity';
import { DataDeletionService } from '../data-deletion/data-deletion.service';
import { AdminService } from './admin.service';

// ─── Cron job metadata (static — NestJS doesn't expose runtime state) ─────────

const CRON_JOBS = [
    {
        name: 'Exchange Rate Sync',
        description: 'Fetches latest KES/USD exchange rates from the Central Bank of Kenya API',
        schedule: 'Every 4 hours',
        cronExpr: 'EVERY_4_HOURS',
        service: 'ExchangeRateService',
    },
    {
        name: 'Wallet Balance Sync',
        description: 'Reconciles wallet balances against M-Pesa transaction records',
        schedule: 'Every hour',
        cronExpr: 'EVERY_HOUR',
        service: 'BalanceSyncTask',
    },
    {
        name: 'Campaign Dispatch',
        description: 'Dispatches scheduled EMAIL and IN_APP_NOTIFICATION campaigns that are due',
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
        description: 'Processes pending GDPR account deletion requests in FK-ordered sequence',
        schedule: 'Every hour',
        cronExpr: 'EVERY_HOUR',
        service: 'DataDeletionScheduler',
    },
];

@Controller('api/admin/operations')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminOperationsController {
    constructor(
        @InjectRepository(DeletionRequest)
        private readonly deletionRepo: Repository<DeletionRequest>,
        private readonly dataDeletionService: DataDeletionService,
        private readonly adminService: AdminService,
        @InjectQueue('wallets') private readonly walletsQueue: Queue,
        @InjectQueue('subscriptions') private readonly subscriptionsQueue: Queue,
        @InjectQueue('payroll-processing') private readonly payrollQueue: Queue,
    ) { }

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

        const summary = Object.fromEntries(counts.map((r) => [r.status, parseInt(r.count)]));

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
            where: { email: body.email.toLowerCase(), status: DeletionStatus.PENDING },
        });

        if (existing) {
            throw new BadRequestException('A pending deletion request already exists for this email');
        }

        const request = await this.dataDeletionService.createRequest({
            email: body.email,
            reason: body.reason || 'Admin-initiated account deletion',
        });

        this.adminService.logAction({
            adminUserId: req.user.id,
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
        request.errorMessage = null;
        await this.deletionRepo.save(request);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'UPDATE',
            entityType: 'DELETION_REQUEST',
            entityId: request.id,
            oldValues: { status: DeletionStatus.FAILED },
            newValues: { status: DeletionStatus.PENDING },
            ipAddress: req.ip,
        });

        return { success: true, message: 'Request reset to PENDING for next scheduler run' };
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
            adminUserId: req.user.id,
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
            adminUserId: req.user.id,
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
            adminUserId: req.user.id,
            action: 'UPDATE',
            entityType: 'QUEUE',
            entityId: name,
            oldValues: null,
            newValues: { drained: true },
            ipAddress: req.ip,
        });

        return { success: true, message: `Queue "${name}" drained (waiting jobs removed)` };
    }

    // ─── Cron Jobs ─────────────────────────────────────────────────────────────

    @Get('cron-jobs')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    getCronJobs() {
        return CRON_JOBS;
    }

    // ─── Private Helpers ───────────────────────────────────────────────────────

    private async getQueueStats(queue: Queue, name: string) {
        const [waiting, active, completed, failed, delayed, paused] = await Promise.all([
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
            case 'wallets': return this.walletsQueue;
            case 'subscriptions': return this.subscriptionsQueue;
            case 'payroll-processing': return this.payrollQueue;
            default: throw new BadRequestException(`Unknown queue: ${name}`);
        }
    }
}
