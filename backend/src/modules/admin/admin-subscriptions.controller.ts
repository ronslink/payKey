import {
    Controller,
    Get,
    Put,
    Body,
    Param,
    UseGuards,
    Req,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { SubscriptionPlan } from '../subscriptions/entities/subscription-plan.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
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
        private readonly dataSource: DataSource,
        private readonly adminService: AdminService,
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
}
