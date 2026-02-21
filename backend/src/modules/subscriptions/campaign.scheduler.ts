import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, LessThanOrEqual, MoreThanOrEqual, IsNull, Or } from 'typeorm';
import { Campaign, CampaignStatus, CampaignType } from './entities/campaign.entity';
import { User, UserRole } from '../users/entities/user.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { NotificationsService, NotificationType } from '../notifications/notifications.service';

/**
 * CampaignScheduler
 *
 * Runs every 15 minutes and dispatches campaigns that:
 *  - Have status = ACTIVE
 *  - Have a scheduledFrom <= NOW (or no scheduledFrom set)
 *  - Have a scheduledUntil >= NOW (or no scheduledUntil set)
 *  - Have never been dispatched (lastDispatchedAt IS NULL)
 *
 * Dispatch behaviour by campaign type:
 *  - EMAIL            → Send one email per matching employer via NotificationsService
 *  - PUSH / IN_APP    → Send one FCM push per device token belonging to matching employers
 *  - BANNER / POPUP / SIDEBAR → No dispatch (mobile app polls GET /campaigns/active)
 *
 * After dispatch, sets lastDispatchedAt = NOW and lastDispatchCount = sent count
 * so the same campaign is never sent twice.
 */
@Injectable()
export class CampaignScheduler {
    private readonly logger = new Logger(CampaignScheduler.name);

    constructor(
        @InjectRepository(Campaign)
        private readonly campaignRepo: Repository<Campaign>,
        @InjectRepository(User)
        private readonly userRepo: Repository<User>,
        @InjectRepository(DeviceToken)
        private readonly deviceTokenRepo: Repository<DeviceToken>,
        private readonly notificationsService: NotificationsService,
    ) {}

    /**
     * Main cron tick — every 15 minutes.
     * Finds campaigns due for dispatch and routes each one to the correct sender.
     */
    @Cron('0 */15 * * * *')
    async handleCampaignDispatch(): Promise<void> {
        this.logger.log('[CampaignScheduler] tick — checking for campaigns to dispatch');

        const now = new Date();

        // Find dispatchable campaigns:
        //   status = ACTIVE
        //   scheduledFrom <= now  OR  scheduledFrom IS NULL (immediate)
        //   scheduledUntil >= now  OR  scheduledUntil IS NULL (no end date)
        //   lastDispatchedAt IS NULL  (never sent before)
        //   type is EMAIL, PUSH, or IN_APP_NOTIFICATION (BANNER/POPUP/SIDEBAR don't need server dispatch)
        const campaigns = await this.campaignRepo.find({
            where: [
                {
                    status: CampaignStatus.ACTIVE,
                    type: CampaignType.EMAIL,
                    lastDispatchedAt: IsNull(),
                },
                {
                    status: CampaignStatus.ACTIVE,
                    type: CampaignType.IN_APP_NOTIFICATION,
                    lastDispatchedAt: IsNull(),
                },
            ],
        });

        // Filter by schedule window in code (TypeORM OR with nullable timestamps is verbose)
        const due = campaigns.filter((c) => {
            const afterStart = !c.scheduledFrom || c.scheduledFrom <= now;
            const beforeEnd  = !c.scheduledUntil || c.scheduledUntil >= now;
            return afterStart && beforeEnd;
        });

        if (due.length === 0) {
            this.logger.log('[CampaignScheduler] no campaigns due for dispatch');
            return;
        }

        this.logger.log(`[CampaignScheduler] dispatching ${due.length} campaign(s)`);

        for (const campaign of due) {
            try {
                await this.dispatchCampaign(campaign, now);
            } catch (err) {
                this.logger.error(
                    `[CampaignScheduler] failed to dispatch campaign ${campaign.id} (${campaign.name}):`,
                    err,
                );
            }
        }
    }

    // ─── Private Helpers ─────────────────────────────────────────────────────

    private async dispatchCampaign(campaign: Campaign, now: Date): Promise<void> {
        this.logger.log(
            `[CampaignScheduler] dispatching campaign "${campaign.name}" [${campaign.type}]`,
        );

        // Resolve the target user set
        const users = await this.resolveTargetUsers(campaign);

        if (users.length === 0) {
            this.logger.warn(
                `[CampaignScheduler] campaign "${campaign.name}" has 0 matching users — marking dispatched to avoid retry loops`,
            );
            await this.markDispatched(campaign, 0, now);
            return;
        }

        let sentCount = 0;

        switch (campaign.type) {
            case CampaignType.EMAIL:
                sentCount = await this.dispatchEmail(campaign, users);
                break;

            case CampaignType.IN_APP_NOTIFICATION:
                sentCount = await this.dispatchPush(campaign, users);
                break;

            default:
                this.logger.warn(
                    `[CampaignScheduler] campaign type ${campaign.type} does not require server dispatch`,
                );
                break;
        }

        await this.markDispatched(campaign, sentCount, now);

        this.logger.log(
            `[CampaignScheduler] campaign "${campaign.name}" dispatched to ${sentCount}/${users.length} users`,
        );
    }

    /**
     * Resolve which employer accounts should receive this campaign.
     * Respects targetAudience.tiers; falls back to ALL employers if no tiers set.
     */
    private async resolveTargetUsers(campaign: Campaign): Promise<User[]> {
        const tiers = campaign.targetAudience?.tiers;

        // Build base query — only employer/user accounts, not admin accounts
        const baseRoles = [UserRole.EMPLOYER, UserRole.USER];

        if (tiers && tiers.length > 0) {
            return this.userRepo.find({
                where: {
                    role: In(baseRoles),
                    tier: In(tiers) as any,
                },
                select: ['id', 'email', 'firstName', 'lastName', 'tier', 'phoneNumber', 'mpesaPhone'],
            });
        }

        // No tier targeting — send to all employers
        return this.userRepo.find({
            where: { role: In(baseRoles) },
            select: ['id', 'email', 'firstName', 'lastName', 'tier', 'phoneNumber', 'mpesaPhone'],
        });
    }

    /**
     * Send the campaign as an email to each user.
     * Uses the campaign title as subject and message as body.
     * If a callToAction and URL are set, appends them to the message.
     */
    private async dispatchEmail(campaign: Campaign, users: User[]): Promise<number> {
        let sentCount = 0;
        const subject = campaign.title;
        const baseMessage = this.buildEmailBody(campaign);

        const results = await Promise.allSettled(
            users.map(async (user) => {
                if (!user.email) return;

                const result = await this.notificationsService.sendNotification({
                    type: NotificationType.EMAIL,
                    recipientEmail: user.email,
                    subject,
                    message: baseMessage,
                });

                if (result.success) {
                    sentCount++;
                } else {
                    this.logger.warn(
                        `[CampaignScheduler] email failed for user ${user.id}: ${result.error}`,
                    );
                }
            }),
        );

        // Log any unexpected rejections
        results
            .filter((r) => r.status === 'rejected')
            .forEach((r) => this.logger.error('[CampaignScheduler] email promise rejected:', (r as PromiseRejectedResult).reason));

        return sentCount;
    }

    /**
     * Send the campaign as FCM push notifications.
     * Looks up all active device tokens for the matched users.
     * Sends one push per token (a user may have multiple devices).
     */
    private async dispatchPush(campaign: Campaign, users: User[]): Promise<number> {
        const userIds = users.map((u) => u.id);

        if (userIds.length === 0) return 0;

        // Fetch all active FCM device tokens for the target users
        const tokens = await this.deviceTokenRepo.find({
            where: {
                userId: In(userIds),
                isActive: true,
            },
            select: ['id', 'token', 'userId'],
        });

        if (tokens.length === 0) {
            this.logger.warn(
                `[CampaignScheduler] no active device tokens found for ${userIds.length} users`,
            );
            return 0;
        }

        let sentCount = 0;
        const pushData: Record<string, string> = {
            campaignId: campaign.id,
            type: 'CAMPAIGN',
            ...(campaign.callToActionUrl ? { url: campaign.callToActionUrl } : {}),
            ...(campaign.promotionalItemId ? { promotionalItemId: campaign.promotionalItemId } : {}),
        };

        const results = await Promise.allSettled(
            tokens.map(async (deviceToken) => {
                const result = await this.notificationsService.sendPushToDevice({
                    token: deviceToken.token,
                    title: campaign.title,
                    body: campaign.message,
                    data: pushData,
                });

                if (result.success) {
                    sentCount++;
                } else {
                    this.logger.warn(
                        `[CampaignScheduler] push failed for token ${deviceToken.token}: ${result.error}`,
                    );
                    // Mark stale token as inactive if Firebase reports it as invalid
                    if (result.error?.includes('registration-token-not-registered') ||
                        result.error?.includes('invalid-registration-token')) {
                        await this.deviceTokenRepo.update(deviceToken.id, { isActive: false });
                        this.logger.log(`[CampaignScheduler] deactivated stale token ${deviceToken.token}`);
                    }
                }
            }),
        );

        results
            .filter((r) => r.status === 'rejected')
            .forEach((r) => this.logger.error('[CampaignScheduler] push promise rejected:', (r as PromiseRejectedResult).reason));

        return sentCount;
    }

    /**
     * Build a plain-text email body from the campaign fields.
     * Appends the CTA link if present.
     */
    private buildEmailBody(campaign: Campaign): string {
        let body = campaign.message;

        if (campaign.callToAction && campaign.callToActionUrl) {
            body += `\n\n${campaign.callToAction}: ${campaign.callToActionUrl}`;
        } else if (campaign.callToActionUrl) {
            body += `\n\n${campaign.callToActionUrl}`;
        }

        if (campaign.promotionalItem) {
            body += '\n\n— The PayDome Team';
        }

        return body;
    }

    /**
     * Stamp the campaign as dispatched so it is never sent again.
     * Also increments the impressions counter by the number of users reached.
     */
    private async markDispatched(campaign: Campaign, sentCount: number, now: Date): Promise<void> {
        await this.campaignRepo.update(campaign.id, {
            lastDispatchedAt: now,
            lastDispatchCount: sentCount,
            // Increment impressions by the number of users reached
            impressions: () => `impressions + ${sentCount}`,
        });
    }
}
