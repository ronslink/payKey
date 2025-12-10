import { Controller, Get, Param, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FeatureAccessService } from './feature-access.service';
import { MockDataService } from './mock-data.service';
import { FEATURE_ACCESS_MATRIX, getFeaturesForTier, SubscriptionTier } from './feature-access.config';

@Controller('features')
@UseGuards(JwtAuthGuard)
export class FeatureAccessController {
    constructor(
        private featureAccessService: FeatureAccessService,
        private mockDataService: MockDataService,
    ) { }

    /**
     * Get all features and their access levels for the current user
     */
    @Get()
    async getAllFeatures(@Request() req: any) {
        const summary = await this.featureAccessService.getSubscriptionSummary(
            req.user.userId,
        );

        return {
            tier: summary.tier,
            isTrialActive: summary.isTrialActive,
            trialDaysRemaining: summary.trialDaysRemaining,
            workerLimit: summary.workerLimit,
            features: {
                accessible: summary.accessibleFeatures,
                preview: summary.previewFeatures,
                locked: summary.lockedFeatures,
            },
            allFeatures: FEATURE_ACCESS_MATRIX,
        };
    }

    /**
     * Check access to a specific feature
     */
    @Get('access/:featureKey')
    async checkFeatureAccess(
        @Request() req: any,
        @Param('featureKey') featureKey: string,
    ) {
        return this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            featureKey,
        );
    }

    /**
     * Get trial status for the current user
     */
    @Get('trial-status')
    async getTrialStatus(@Request() req: any) {
        return this.featureAccessService.getTrialStatus(req.user.userId);
    }

    /**
     * Get features that would be unlocked by upgrading to a specific tier
     */
    @Get('upgrade-benefits/:targetTier')
    async getUpgradeBenefits(
        @Request() req: any,
        @Param('targetTier') targetTier: string,
    ) {
        const benefits = await this.featureAccessService.getUpgradeBenefits(
            req.user.userId,
            targetTier.toUpperCase() as SubscriptionTier,
        );

        // Get tier-specific features
        const tierFeatures = getFeaturesForTier(
            targetTier.toUpperCase() as SubscriptionTier,
        );

        return {
            targetTier: targetTier.toUpperCase(),
            newFeatures: benefits,
            allTierFeatures: tierFeatures,
        };
    }

    /**
     * Check if user can add more workers
     */
    @Get('can-add-worker')
    async canAddWorker(@Request() req: any) {
        // TODO: Get actual worker count from WorkersService
        const currentWorkerCount = 0; // Placeholder - inject WorkersService

        return this.featureAccessService.canAddWorker(
            req.user.userId,
            currentWorkerCount,
        );
    }

    // ==================== Mock Data Endpoints ====================
    // These return mock data for trial users to preview premium features

    /**
     * Get mock/real payroll report data based on access
     */
    @Get('data/reports')
    async getReportsData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'advanced_reports',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            // Return mock data during trial
            return {
                ...this.mockDataService.generatePayrollReport(),
                accessLevel: 'preview',
            };
        }

        // User has full access - return real data placeholder
        // (Actual implementation would fetch real data from reports service)
        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real reports data from reports service',
        };
    }

    /**
     * Get mock/real time tracking data based on access
     */
    @Get('data/time-tracking')
    async getTimeTrackingData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'time_tracking',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateTimeTrackingData(),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real time tracking data from time service',
        };
    }

    /**
     * Get mock/real leave management data based on access
     */
    @Get('data/leave')
    async getLeaveData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'leave_management',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateLeaveData(),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real leave data from leave service',
        };
    }

    /**
     * Get mock/real multi-property data based on access
     */
    @Get('data/properties')
    async getPropertiesData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'multi_property',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateMultiPropertyData(),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real property data from properties service',
        };
    }

    /**
     * Get mock/real accounting integration data based on access
     */
    @Get('data/accounting')
    async getAccountingData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'accounting_integration',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateAccountingData(),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real accounting data from accounting service',
        };
    }

    /**
     * Get mock/real P9 tax card data based on access
     */
    @Get(['data/p9', 'data/p9/:year'])
    async getP9Data(@Request() req: any, @Param('year') year?: string) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'p9_tax_cards',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        const yearNum = year ? parseInt(year, 10) : new Date().getFullYear();

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateP9Data(yearNum),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real P9 data from tax service',
        };
    }

    /**
     * Get mock advanced reports data based on access
     */
    @Get('data/advanced-reports')
    async getAdvancedReportsData(@Request() req: any) {
        const access = await this.featureAccessService.checkFeatureAccess(
            req.user.userId,
            'advanced_reports',
        );

        if (!access.hasAccess) {
            return {
                hasAccess: false,
                requiredTier: access.requiredTier,
                message: access.reason,
            };
        }

        if (access.isPreview) {
            return {
                ...this.mockDataService.generateAdvancedReports(),
                accessLevel: 'preview',
            };
        }

        return {
            hasAccess: true,
            accessLevel: 'full',
            message: 'Fetch real advanced reports from reports service',
        };
    }
}
