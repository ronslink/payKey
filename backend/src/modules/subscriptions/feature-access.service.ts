import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UsersService } from '../users/users.service';
import { Subscription, SubscriptionStatus } from './entities/subscription.entity';
import {
    FEATURE_ACCESS_MATRIX,
    FeatureDefinition,
    SubscriptionTier,
    getFeatureByKey,
    tierHasFeature,
    getLowestTierForFeature,
    getFeaturesForTier,
    getUpgradeFeatures,
    TIER_LIMITS,
} from './feature-access.config';
import { TRIAL_PERIOD_DAYS } from './subscription-plans.config';

export interface FeatureAccessResult {
    /** Whether the user has full access to this feature */
    hasAccess: boolean;
    /** Whether the user is seeing preview/mock data */
    isPreview: boolean;
    /** If not accessible, the tier needed to access */
    requiredTier: SubscriptionTier | null;
    /** Reason for access/denial */
    reason: string;
    /** Feature details */
    feature?: FeatureDefinition;
}

export interface TrialStatus {
    isActive: boolean;
    daysRemaining: number;
    expiresAt: Date | null;
    startedAt: Date;
}

export interface SubscriptionSummary {
    tier: SubscriptionTier;
    isTrialActive: boolean;
    trialDaysRemaining: number;
    workerLimit: number;
    currentWorkerCount: number;
    accessibleFeatures: FeatureDefinition[];
    previewFeatures: FeatureDefinition[];
    lockedFeatures: FeatureDefinition[];
}

@Injectable()
export class FeatureAccessService {
    constructor(
        private usersService: UsersService,
        @InjectRepository(Subscription)
        private subscriptionRepository: Repository<Subscription>,
    ) { }

    /**
     * Check if a user has access to a specific feature
     */
    async checkFeatureAccess(userId: string, featureKey: string): Promise<FeatureAccessResult> {
        const user = await this.usersService.findOneById(userId);
        if (!user) {
            return {
                hasAccess: false,
                isPreview: false,
                requiredTier: null,
                reason: 'User not found',
            };
        }

        const feature = getFeatureByKey(featureKey);
        if (!feature) {
            // Unknown feature - allow by default
            return {
                hasAccess: true,
                isPreview: false,
                requiredTier: null,
                reason: 'Feature not in access matrix',
            };
        }

        const subscription = await this.getCurrentSubscription(userId);
        let userTier = (subscription?.tier || user.tier || 'FREE') as string;
        userTier = userTier.toUpperCase(); // Normalize
        const hasDirectAccess = tierHasFeature(userTier as SubscriptionTier, featureKey);

        if (hasDirectAccess) {
            return {
                hasAccess: true,
                isPreview: false,
                requiredTier: null,
                reason: `${userTier} tier has access to ${feature.name}`,
                feature,
            };
        }

        // Check if user is in trial period
        const trialStatus = this.calculateTrialStatus(user.createdAt);
        if (trialStatus.isActive && feature.mockDataAvailable) {
            return {
                hasAccess: true,
                isPreview: true,
                requiredTier: getLowestTierForFeature(featureKey),
                reason: `Preview mode during trial - ${trialStatus.daysRemaining} days remaining`,
                feature,
            };
        }

        // Feature is locked
        return {
            hasAccess: false,
            isPreview: false,
            requiredTier: getLowestTierForFeature(featureKey),
            reason: `Requires ${getLowestTierForFeature(featureKey)} tier or higher`,
            feature,
        };
    }

    /**
     * Get the current active subscription for a user
     */
    async getCurrentSubscription(userId: string): Promise<Subscription | null> {
        try {
            return await this.subscriptionRepository.findOne({
                where: {
                    userId,
                    status: SubscriptionStatus.ACTIVE,
                },
            });
        } catch (error) {
            // Handle case where subscriptions table doesn't exist yet
            // Fall back to user.tier instead
            return null;
        }
    }

    /**
     * Calculate trial status for a user based on account creation date
     */
    calculateTrialStatus(accountCreatedAt: Date): TrialStatus {
        const startedAt = new Date(accountCreatedAt);
        const expiresAt = new Date(accountCreatedAt);
        expiresAt.setDate(expiresAt.getDate() + TRIAL_PERIOD_DAYS);

        const now = new Date();
        const isActive = now <= expiresAt;
        const daysRemaining = isActive
            ? Math.ceil((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
            : 0;

        return {
            isActive,
            daysRemaining,
            expiresAt: isActive ? expiresAt : null,
            startedAt,
        };
    }

    /**
     * Get the trial status for a specific user
     */
    async getTrialStatus(userId: string): Promise<TrialStatus> {
        const user = await this.usersService.findOneById(userId);
        if (!user) {
            return {
                isActive: false,
                daysRemaining: 0,
                expiresAt: null,
                startedAt: new Date(),
            };
        }
        return this.calculateTrialStatus(user.createdAt);
    }

    /**
     * Get a complete subscription summary for a user
     */
    async getSubscriptionSummary(userId: string): Promise<SubscriptionSummary> {
        const user = await this.usersService.findOneById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        const subscription = await this.getCurrentSubscription(userId);
        let tier = (subscription?.tier || user.tier || 'FREE') as string;
        tier = tier.toUpperCase(); // Normalize to handle case mismatch
        const activeTier = tier as SubscriptionTier;
        const trialStatus = this.calculateTrialStatus(user.createdAt);

        // Get worker count (would need WorkersService injection)
        const currentWorkerCount = 0; // TODO: Inject WorkersService

        // Categorize features
        const accessibleFeatures: FeatureDefinition[] = [];
        const previewFeatures: FeatureDefinition[] = [];
        const lockedFeatures: FeatureDefinition[] = [];

        for (const feature of FEATURE_ACCESS_MATRIX) {
            if (tierHasFeature(activeTier, feature.key)) {
                accessibleFeatures.push(feature);
            } else if (trialStatus.isActive && feature.mockDataAvailable) {
                previewFeatures.push(feature);
            } else {
                lockedFeatures.push(feature);
            }
        }

        return {
            tier: activeTier,
            isTrialActive: trialStatus.isActive,
            trialDaysRemaining: trialStatus.daysRemaining,
            workerLimit: TIER_LIMITS[activeTier].workerLimit,
            currentWorkerCount,
            accessibleFeatures,
            previewFeatures,
            lockedFeatures,
        };
    }

    /**
     * Get features the user would gain by upgrading to a specific tier
     */
    async getUpgradeBenefits(
        userId: string,
        targetTier: SubscriptionTier,
    ): Promise<FeatureDefinition[]> {
        const summary = await this.getSubscriptionSummary(userId);
        return getUpgradeFeatures(summary.tier, targetTier);
    }

    /**
     * Check if user can add more workers based on their subscription
     */
    async canAddWorker(userId: string, currentWorkerCount: number): Promise<{
        canAdd: boolean;
        currentLimit: number;
        currentCount: number;
        upgradeMessage?: string;
    }> {
        const user = await this.usersService.findOneById(userId);
        if (!user) {
            return {
                canAdd: false,
                currentLimit: 0,
                currentCount: currentWorkerCount,
                upgradeMessage: 'User not found',
            };
        }

        const subscription = await this.getCurrentSubscription(userId);
        const tier = (subscription?.tier || user.tier || 'FREE') as SubscriptionTier;
        const limit = TIER_LIMITS[tier].workerLimit;
        const trialStatus = this.calculateTrialStatus(user.createdAt);

        // During trial, allow up to PLATINUM limit
        if (trialStatus.isActive) {
            const trialLimit = TIER_LIMITS.PLATINUM.workerLimit;
            return {
                canAdd: currentWorkerCount < trialLimit,
                currentLimit: trialLimit,
                currentCount: currentWorkerCount,
                upgradeMessage:
                    currentWorkerCount >= limit
                        ? `Trial allows up to ${trialLimit} workers. After trial, ${tier} tier allows ${limit}.`
                        : undefined,
            };
        }

        if (currentWorkerCount >= limit) {
            const nextTier = this.getNextTier(tier);
            return {
                canAdd: false,
                currentLimit: limit,
                currentCount: currentWorkerCount,
                upgradeMessage: nextTier
                    ? `Upgrade to ${nextTier} to add up to ${TIER_LIMITS[nextTier].workerLimit} workers.`
                    : 'Maximum worker limit reached.',
            };
        }

        return {
            canAdd: true,
            currentLimit: limit,
            currentCount: currentWorkerCount,
        };
    }

    private getNextTier(currentTier: SubscriptionTier): SubscriptionTier | null {
        const tierOrder: SubscriptionTier[] = ['FREE', 'BASIC', 'GOLD', 'PLATINUM'];
        const currentIndex = tierOrder.indexOf(currentTier);
        if (currentIndex < tierOrder.length - 1) {
            return tierOrder[currentIndex + 1];
        }
        return null;
    }
}
