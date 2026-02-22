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
import {
  PromotionalItem,
  PromoStatus,
} from '../subscriptions/entities/promotional-item.entity';
import {
  Campaign,
  CampaignStatus,
} from '../subscriptions/entities/campaign.entity';
import { DataSource } from 'typeorm';
import { AdminService } from './admin.service';
import { ExchangeRateService } from '../payments/exchange-rate.service';

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
    private readonly exchangeRateService: ExchangeRateService,
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
  ) {}

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
  async getSubscriptionDashboard(
    @Query('currency') currency?: string,
  ) {
    const displayCurrency = currency || 'USD';
    const cacheKey = `admin_subscription_dashboard_${displayCurrency}`;
    const cached = await this.cacheManager.get(cacheKey);
    if (cached) {
      return { ...cached, displayCurrency };
    }

    // Get exchange rate for conversions
    let exchangeRate = 1;
    try {
      if (displayCurrency === 'KES') {
        exchangeRate = await this.exchangeRateService.getLatestRate('USD', 'KES');
      } else if (displayCurrency === 'EUR') {
        exchangeRate = await this.exchangeRateService.getLatestRate('USD', 'EUR');
      }
    } catch (e) {
      // Use 1:1 if rate not available
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
      this.dataSource.query(
        `
                SELECT
                    COUNT(*) FILTER (WHERE status = 'CANCELLED' AND "updatedAt" >= $1) as cancelled,
                    COUNT(*) FILTER (WHERE status = 'ACTIVE') as active
                FROM subscriptions
            `,
        [thirtyDaysAgo],
      ),
      this.dataSource.query(`
                SELECT
                  s.tier,
                  COUNT(*) as subscribers,
                  COALESCE(SUM(
                    CASE s."billingPeriod"
                      WHEN 'yearly' THEN sp."priceUSDYearly" / 12
                      ELSE sp."priceUSD"
                    END
                  ), 0) as total_mrr
                FROM subscriptions s
                JOIN subscription_plans sp ON sp.tier::text = s.tier::text
                WHERE s.status = 'ACTIVE'
                GROUP BY s.tier
                ORDER BY total_mrr DESC
            `),
    ]);

    const churn = churnRate[0];
    const churnPercentage =
      churn.active > 0
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
        mrr: (parseFloat(m.total_mrr) || 0) * exchangeRate,
        mrrOriginal: parseFloat(m.total_mrr) || 0,
        subscribers: parseInt(m.subscribers) || 0,
      })),
    };

    // Cache for 15 minutes (900000 milliseconds)
    await this.cacheManager.set(cacheKey, result, 900000);
    return { ...result, displayCurrency, exchangeRate };
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

  @Get('upgrades')
  async getTierUpgrades(
    @Query('days') days?: string,
    @Query('currency') currency?: string,
  ) {
    const lookbackDays = parseInt(days || '30', 10);
    const displayCurrency = currency || 'USD';

    // Get exchange rate for conversions
    let exchangeRate = 1;
    try {
      if (displayCurrency === 'KES') {
        exchangeRate = await this.exchangeRateService.getLatestRate('USD', 'KES');
      } else if (displayCurrency === 'EUR') {
        exchangeRate = await this.exchangeRateService.getLatestRate('USD', 'EUR');
      }
    } catch (e) {
      // Use 1:1 if rate not available
    }

    // Identify users who upgraded: their subscription was modified (updatedAt > createdAt)
    // after initial creation and their current tier is above FREE.
    // We join with SUBSCRIPTION transactions to capture any upgrade revenue.
    const upgrades = await this.dataSource.query(
      `
      SELECT
        s.id as subscription_id,
        s.tier as current_tier,
        s."createdAt" as subscribed_at,
        s."updatedAt" as upgraded_at,
        s.amount,
        s.currency,
        s."billingPeriod",
        COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
        u.email,
        u.id as user_id,
        u.tier as user_tier,
        COALESCE(
          (SELECT SUM(sp.amount)
           FROM subscription_payments sp
           WHERE sp."userId" = u.id
             AND sp.status = 'COMPLETED'),
          0
        ) as total_subscription_revenue,
        COUNT(DISTINCT w.id) as worker_count
      FROM subscriptions s
      JOIN users u ON u.id = s."userId"
      LEFT JOIN workers w ON w."userId" = u.id AND w."isActive" = true
      WHERE s.status = 'ACTIVE'
        AND s.tier != 'FREE'
        AND EXTRACT(EPOCH FROM (s."updatedAt" - s."createdAt")) > 60
        AND s."updatedAt" >= NOW() - ($1 * INTERVAL '1 day')
      GROUP BY s.id, u.id
      ORDER BY s."updatedAt" DESC
      `,
      [lookbackDays],
    );

    // Tier upgrade revenue summary
    const summary = await this.dataSource.query(
      `
      SELECT
        s.tier,
        COUNT(*) as upgrade_count,
        COALESCE(SUM(t_rev.total), 0) as tier_revenue
      FROM subscriptions s
      JOIN users u ON u.id = s."userId"
      LEFT JOIN LATERAL (
        SELECT COALESCE(SUM(sp.amount), 0) as total
        FROM subscription_payments sp
        WHERE sp."userId" = u.id
          AND sp.status = 'COMPLETED'
      ) t_rev ON true
      WHERE s.status = 'ACTIVE'
        AND s.tier != 'FREE'
        AND EXTRACT(EPOCH FROM (s."updatedAt" - s."createdAt")) > 60
        AND s."updatedAt" >= NOW() - ($1 * INTERVAL '1 day')
      GROUP BY s.tier
      ORDER BY upgrade_count DESC
      `,
      [lookbackDays],
    );

    return {
      lookbackDays,
      displayCurrency,
      exchangeRate,
      summary: summary.map((r: any) => ({
        tier: r.tier,
        upgradeCount: parseInt(r.upgrade_count),
        tierRevenue: (parseFloat(r.tier_revenue) || 0) * exchangeRate,
        tierRevenueOriginal: parseFloat(r.tier_revenue) || 0,
      })),
      upgrades: upgrades.map((r: any) => ({
        subscriptionId: r.subscription_id,
        userId: r.user_id,
        employerName: r.employer_name,
        email: r.email,
        currentTier: r.current_tier,
        userTier: r.user_tier,
        subscribedAt: r.subscribed_at,
        upgradedAt: r.upgraded_at,
        billingPeriod: r.billing_period,
        amount: parseFloat(r.amount) || 0,
        currency: r.currency,
        totalSubscriptionRevenue: (parseFloat(r.total_subscription_revenue) || 0) * exchangeRate,
        totalSubscriptionRevenueOriginal: parseFloat(r.total_subscription_revenue) || 0,
        workerCount: parseInt(r.worker_count) || 0,
      })),
    };
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
  async createPromotionalItem(
    @Body() body: Partial<PromotionalItem>,
    @Req() req: any,
  ) {
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
