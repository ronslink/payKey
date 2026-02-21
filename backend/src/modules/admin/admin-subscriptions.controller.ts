import {
    Controller,
    Get,
    Put,
    Post,
    Delete,
    Body,
    Param,
    UseGuards,
    Req,
    Query,
    Inject,
} from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { SubscriptionPlan } from '../subscriptions/entities/subscription-plan.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { PromotionalItem, PromoStatus } from '../subscriptions/entities/promotional-item.entity';
import { Campaign, CampaignStatus } from '../subscriptions/entities/campaign.entity';
import { DataSource } from 'typeorm';
import { AdminService } from './admin.service';

@Controller('api/admin/subscription-plans')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminSubscriptionsController {
    constructor(
        @InjectRepository(SubscriptionPlan)
        private readonly planRepo: Repository<SubscriptionPlan>,
        @InjectRepository(Subscription)
        private readonly subscriptionRepo: Repository<Subscription>,
        @InjectRepository(PromotionalItem)
        private readonly promoItemRepo: Repository<PromotionalItem>,
        @InjectRepository(Campaign)
        private readonly campaignRepo: Repository<Campaign>,
        private readonly dataSource: DataSource,
        private readonly adminService: AdminService,
        @Inject(CACHE_MANAGER) private cacheManager: Cache,
    ) { }

    @Get()
    getPlans() {
        return this.planRepo.find({ order: { priceUSD: 'ASC' } });
    }

    @Put(':id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async updatePlan(
        @Param('id') id: string,
        @Body() body: Partial<SubscriptionPlan>,
        @Req() req: any,
    ) {
        const oldPlan = await this.planRepo.findOne({ where: { id } });

        // Prevent changing tier (primary key semantics)
        delete (body as any).tier;
        delete (body as any).id;
        await this.planRepo.update(id, body);

        const newPlan = await this.planRepo.findOne({ where: { id } });

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'UPDATE',
            entityType: 'SUBSCRIPTION_PLAN',
            entityId: id,
            oldValues: oldPlan,
            newValues: newPlan,
            ipAddress: req.ip,
        });

        return newPlan;
    }

    @Get('stats')
    async getTierStats() {
        return this.dataSource.query(`
            SELECT * FROM subscription_tier_stats
            ORDER BY total_mrr DESC
        `);
    }

    @Get('dashboard')
    async getSubscriptionDashboard() {
        const cacheKey = 'admin_subscription_dashboard';
        const cached = await this.cacheManager.get(cacheKey);
        if (cached) {
            return cached;
        }

        const now = new Date();
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

        const [
            totalSubscriptions,
            activeSubscriptions,
            newSubscriptions30Days,
            newSubscriptions7Days,
            tierBreakdown,
            billingPeriodBreakdown,
            churnRate,
            mrrData,
        ] = await Promise.all([
            this.subscriptionRepo.count(),
            this.subscriptionRepo.count({ where: { status: 'ACTIVE' as any } }),
            this.subscriptionRepo
                .createQueryBuilder('s')
                .where('s.createdAt >= :thirtyDaysAgo', { thirtyDaysAgo })
                .getCount(),
            this.subscriptionRepo
                .createQueryBuilder('s')
                .where('s.createdAt >= :sevenDaysAgo', { sevenDaysAgo })
                .getCount(),
            this.dataSource.query(`
                SELECT tier, COUNT(*) as count
                FROM subscriptions
                WHERE status = 'ACTIVE'
                GROUP BY tier
                ORDER BY count DESC
            `),
            this.dataSource.query(`
                SELECT "billingPeriod", COUNT(*) as count
                FROM subscriptions
                WHERE status = 'ACTIVE'
                GROUP BY "billingPeriod"
            `),
            this.dataSource.query(`
                SELECT
                    COUNT(*) FILTER (WHERE status = 'CANCELLED' AND "updatedAt" >= $1) as cancelled,
                    COUNT(*) FILTER (WHERE status = 'ACTIVE') as active
                FROM subscriptions
            `, [thirtyDaysAgo]),
            this.dataSource.query(`
                SELECT tier, SUM(amount) as total_mrr, COUNT(*) as subscribers
                FROM subscriptions
                WHERE status = 'ACTIVE' AND currency = 'USD'
                GROUP BY tier
            `),
        ]);

        const churn = churnRate[0];
        const churnPercentage = churn.active > 0
            ? ((churn.cancelled / churn.active) * 100).toFixed(2)
            : '0.00';

        const result = {
            overview: {
                totalSubscriptions,
                activeSubscriptions,
                newSubscriptions30Days,
                newSubscriptions7Days,
                churnRate: parseFloat(churnPercentage),
            },
            tierBreakdown: tierBreakdown.map((t: any) => ({
                tier: t.tier,
                count: parseInt(t.count),
            })),
            billingPeriodBreakdown: billingPeriodBreakdown.map((b: any) => ({
                period: b.billingPeriod,
                count: parseInt(b.count),
            })),
            mrrByTier: mrrData.map((m: any) => ({
                tier: m.tier,
                mrr: parseFloat(m.total_mrr) || 0,
                subscribers: parseInt(m.subscribers) || 0,
            })),
        };

        // Cache for 15 minutes (900000 milliseconds)
        await this.cacheManager.set(cacheKey, result, 900000);
        return result;
    }

    @Get('subscribers')
    async getSubscribers() {
        return this.dataSource.query(`
      SELECT
        s.id,
        s.tier,
        s.status,
        s."billingPeriod",
        s.amount,
        s.currency,
        s."nextBillingDate",
        s."createdAt",
        COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
        u.email,
        u.id as user_id,
        COUNT(w.id) as worker_count
      FROM subscriptions s
      JOIN users u ON u.id = s."userId"
      LEFT JOIN workers w ON w."userId" = u.id AND w."isActive" = true
      WHERE s.status = 'ACTIVE'
      GROUP BY s.id, u.id
      ORDER BY s."createdAt" DESC
    `);
    }

    // ─── Promotional Items ─────────────────────────────────────────────────────

    @Get('promotional-items')
    async getPromotionalItems() {
        return this.promoItemRepo.find({
            order: { createdAt: 'DESC' },
        });
    }

    @Get('promotional-items/:id')
    async getPromotionalItem(@Param('id') id: string) {
        return this.promoItemRepo.findOne({ where: { id } });
    }

    @Post('promotional-items')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async createPromotionalItem(@Body() body: Partial<PromotionalItem>, @Req() req: any) {
        const item = this.promoItemRepo.create(body);
        const saved = await this.promoItemRepo.save(item);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'CREATE',
            entityType: 'PROMOTIONAL_ITEM',
            entityId: saved.id,
            oldValues: null,
            newValues: saved,
            ipAddress: req.ip,
        });

        return saved;
    }

    @Put('promotional-items/:id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async updatePromotionalItem(
        @Param('id') id: string,
        @Body() body: Partial<PromotionalItem>,
        @Req() req: any,
    ) {
        const oldItem = await this.promoItemRepo.findOne({ where: { id } });
        await this.promoItemRepo.update(id, body);
        const newItem = await this.promoItemRepo.findOne({ where: { id } });

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'UPDATE',
            entityType: 'PROMOTIONAL_ITEM',
            entityId: id,
            oldValues: oldItem,
            newValues: newItem,
            ipAddress: req.ip,
        });

        return newItem;
    }

    @Delete('promotional-items/:id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async deletePromotionalItem(@Param('id') id: string, @Req() req: any) {
        const item = await this.promoItemRepo.findOne({ where: { id } });
        await this.promoItemRepo.delete(id);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'DELETE',
            entityType: 'PROMOTIONAL_ITEM',
            entityId: id,
            oldValues: item,
            newValues: null,
            ipAddress: req.ip,
        });

        return { success: true };
    }

    // ─── Campaigns ─────────────────────────────────────────────────────────────

    @Get('campaigns')
    async getCampaigns() {
        return this.campaignRepo.find({
            relations: ['promotionalItem'],
            order: { createdAt: 'DESC' },
        });
    }

    @Get('campaigns/:id')
    async getCampaign(@Param('id') id: string) {
        return this.campaignRepo.findOne({
            where: { id },
            relations: ['promotionalItem'],
        });
    }

    @Get('campaigns/active')
    async getActiveCampaigns() {
        const now = new Date();
        return this.campaignRepo.find({
            where: {
                status: CampaignStatus.ACTIVE,
                scheduledFrom: { $lte: now } as any,
                scheduledUntil: { $gte: now } as any,
            },
            relations: ['promotionalItem'],
            order: { priority: 'DESC' },
        });
    }

    @Post('campaigns')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async createCampaign(@Body() body: Partial<Campaign>, @Req() req: any) {
        const campaign = this.campaignRepo.create(body);
        const saved = await this.campaignRepo.save(campaign);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'CREATE',
            entityType: 'CAMPAIGN',
            entityId: saved.id,
            oldValues: null,
            newValues: saved,
            ipAddress: req.ip,
        });

        return saved;
    }

    @Put('campaigns/:id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async updateCampaign(
        @Param('id') id: string,
        @Body() body: Partial<Campaign>,
        @Req() req: any,
    ) {
        const oldCampaign = await this.campaignRepo.findOne({ where: { id } });
        await this.campaignRepo.update(id, body);
        const newCampaign = await this.campaignRepo.findOne({
            where: { id },
            relations: ['promotionalItem'],
        });

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'UPDATE',
            entityType: 'CAMPAIGN',
            entityId: id,
            oldValues: oldCampaign,
            newValues: newCampaign,
            ipAddress: req.ip,
        });

        return newCampaign;
    }

    @Put('campaigns/:id/status')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async updateCampaignStatus(
        @Param('id') id: string,
        @Body() body: { status: CampaignStatus },
        @Req() req: any,
    ) {
        const oldCampaign = await this.campaignRepo.findOne({ where: { id } });
        await this.campaignRepo.update(id, { status: body.status });
        const newCampaign = await this.campaignRepo.findOne({
            where: { id },
            relations: ['promotionalItem'],
        });

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'UPDATE_STATUS',
            entityType: 'CAMPAIGN',
            entityId: id,
            oldValues: oldCampaign,
            newValues: newCampaign,
            ipAddress: req.ip,
        });

        return newCampaign;
    }

    @Delete('campaigns/:id')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async deleteCampaign(@Param('id') id: string, @Req() req: any) {
        const campaign = await this.campaignRepo.findOne({ where: { id } });
        await this.campaignRepo.delete(id);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'DELETE',
            entityType: 'CAMPAIGN',
            entityId: id,
            oldValues: campaign,
            newValues: null,
            ipAddress: req.ip,
        });

        return { success: true };
    }

    @Post('campaigns/:id/impression')
    async trackImpression(@Param('id') id: string) {
        await this.campaignRepo.increment({ id }, 'impressions', 1);
        return { success: true };
    }

    @Post('campaigns/:id/click')
    async trackClick(@Param('id') id: string) {
        await this.campaignRepo.increment({ id }, 'clicks', 1);
        return { success: true };
    }

    @Post('campaigns/:id/conversion')
    async trackConversion(@Param('id') id: string) {
        await this.campaignRepo.increment({ id }, 'conversions', 1);
        return { success: true };
    }
}
