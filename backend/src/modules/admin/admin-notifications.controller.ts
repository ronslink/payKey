import {
    Controller,
    Get,
    Post,
    Body,
    Query,
    UseGuards,
    Req,
    BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole, User } from '../users/entities/user.entity';
import { Notification, NotificationType, NotificationStatus } from '../notifications/entities/notification.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';
import { Subscription, SubscriptionStatus } from '../subscriptions/entities/subscription.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { AdminService } from './admin.service';

@Controller('api/admin/notifications')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminNotificationsController {
    constructor(
        @InjectRepository(Notification)
        private readonly notificationRepo: Repository<Notification>,
        @InjectRepository(User)
        private readonly userRepo: Repository<User>,
        @InjectRepository(DeviceToken)
        private readonly deviceTokenRepo: Repository<DeviceToken>,
        @InjectRepository(Subscription)
        private readonly subscriptionRepo: Repository<Subscription>,
        private readonly notificationsService: NotificationsService,
        private readonly adminService: AdminService,
    ) { }

    @Get()
    async getNotifications(
        @Query('page') page = '1',
        @Query('limit') limit = '20',
        @Query('type') type?: NotificationType,
    ) {
        const qb = this.notificationRepo.createQueryBuilder('n')
            .leftJoinAndSelect('n.user', 'user')
            .orderBy('n.createdAt', 'DESC')
            .skip((parseInt(page) - 1) * parseInt(limit))
            .take(parseInt(limit));

        if (type) {
            qb.andWhere('n.type = :type', { type });
        }

        const [data, total] = await qb.getManyAndCount();

        return {
            data,
            total,
            page: parseInt(page),
            limit: parseInt(limit),
        };
    }

    @Post('send')
    @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
    async sendNotification(
        @Req() req: any,
        @Body() body: {
            userIds?: string[];
            broadcast?: boolean;
            /** Tier-group targeting — send to all users on these subscription tiers */
            tiers?: string[];
            /**
             * Maintenance mode — targets every user with an ACTIVE subscription.
             * Use for scheduled downtime, upgrade notices, etc.
             */
            maintenance?: boolean;
            /** Optional maintenance window timestamps (ISO strings) embedded in notification metadata */
            maintenanceWindow?: { startsAt?: string; endsAt?: string };
            type: NotificationType;
            subject?: string;
            message: string;
        }
    ) {
        const hasTiers = body.tiers && body.tiers.length > 0;
        const hasUsers = body.userIds && body.userIds.length > 0;

        if (!body.broadcast && !body.maintenance && !hasTiers && !hasUsers) {
            throw new BadRequestException('Must provide tiers, userIds, maintenance, or set broadcast to true');
        }

        if (body.type === NotificationType.EMAIL && !body.subject) {
            throw new BadRequestException('Subject is required for EMAIL notifications');
        }

        // Fetch target users
        let users: User[] = [];
        if (body.broadcast) {
            // Broadcast: all employer accounts, exclude admins
            users = await this.userRepo.find({
                where: { role: In([UserRole.EMPLOYER, UserRole.USER]) },
            });
        } else if (body.maintenance) {
            // Maintenance: all users who currently hold an ACTIVE subscription (any paid tier)
            const activeSubs = await this.subscriptionRepo.find({
                where: { status: SubscriptionStatus.ACTIVE },
                select: ['userId'],
            });
            const activeUserIds = [...new Set(activeSubs.map((s) => s.userId))];
            if (activeUserIds.length > 0) {
                users = await this.userRepo.find({
                    where: { id: In(activeUserIds), role: In([UserRole.EMPLOYER, UserRole.USER]) },
                });
            }
        } else if (hasTiers) {
            // Tier group: all employers on the specified subscription tier(s)
            users = await this.userRepo
                .createQueryBuilder('u')
                .where('u.role IN (:...roles)', { roles: [UserRole.EMPLOYER, UserRole.USER] })
                .andWhere('u.tier IN (:...tiers)', { tiers: body.tiers })
                .getMany();
        } else {
            // Hand-picked individual users
            users = await this.userRepo.find({ where: { id: In(body.userIds!) } });
        }

        // For PUSH: pre-fetch all active device tokens for the target users in one query
        let deviceTokenMap: Map<string, string[]> = new Map();
        if (body.type === NotificationType.PUSH) {
            const userIds = users.map((u) => u.id);
            if (userIds.length > 0) {
                const tokens = await this.deviceTokenRepo.find({
                    where: { userId: In(userIds), isActive: true },
                    select: ['userId', 'token'],
                });
                tokens.forEach((dt) => {
                    const existing = deviceTokenMap.get(dt.userId) || [];
                    existing.push(dt.token);
                    deviceTokenMap.set(dt.userId, existing);
                });
            }
        }

        let sentCount = 0;
        let failCount = 0;

        // Build shared metadata stamped on every notification record for this send
        const notifMeta: Record<string, any> = {};
        if (body.maintenance) {
            notifMeta.notificationType = 'MAINTENANCE';
            if (body.maintenanceWindow?.startsAt) notifMeta.maintenanceStartsAt = body.maintenanceWindow.startsAt;
            if (body.maintenanceWindow?.endsAt)   notifMeta.maintenanceEndsAt   = body.maintenanceWindow.endsAt;
        }

        // Perform parallel sends
        const promises = users.map(async (user) => {
            try {
                if (body.type === NotificationType.EMAIL) {
                    if (!user.email) throw new Error('No email address on record');

                    const res = await this.notificationsService.sendNotification({
                        type: NotificationType.EMAIL,
                        recipientEmail: user.email,
                        subject: body.subject,
                        message: body.message,
                    });

                    await this.notificationRepo.save({
                        userId: user.id,
                        type: body.type,
                        status: res.success ? NotificationStatus.SENT : NotificationStatus.FAILED,
                        recipient: user.email,
                        subject: body.subject,
                        message: body.message,
                        messageId: res.messageId,
                        errorMessage: res.error,
                        sentAt: res.success ? new Date() : undefined,
                        metadata: Object.keys(notifMeta).length ? notifMeta : undefined,
                    });

                    if (res.success) sentCount++;
                    else failCount++;

                } else if (body.type === NotificationType.SMS) {
                    const phone = user.phoneNumber || user.mpesaPhone;
                    if (!phone) throw new Error('No phone number on record');

                    const res = await this.notificationsService.sendNotification({
                        type: NotificationType.SMS,
                        recipientPhone: phone,
                        message: body.message,
                    });

                    await this.notificationRepo.save({
                        userId: user.id,
                        type: body.type,
                        status: res.success ? NotificationStatus.SENT : NotificationStatus.FAILED,
                        recipient: phone,
                        message: body.message,
                        messageId: res.messageId,
                        errorMessage: res.error,
                        sentAt: res.success ? new Date() : undefined,
                        metadata: Object.keys(notifMeta).length ? notifMeta : undefined,
                    });

                    if (res.success) sentCount++;
                    else failCount++;

                } else if (body.type === NotificationType.PUSH) {
                    // Send one push per registered device token for this user
                    const tokens = deviceTokenMap.get(user.id) || [];

                    if (tokens.length === 0) {
                        // No device tokens registered — log and count as skipped
                        await this.notificationRepo.save({
                            userId: user.id,
                            type: body.type,
                            status: NotificationStatus.FAILED,
                            message: body.message,
                            subject: body.subject,
                            errorMessage: 'No active device tokens registered for this user',
                            metadata: Object.keys(notifMeta).length ? notifMeta : undefined,
                        });
                        failCount++;
                        return;
                    }

                    // Send to all the user's devices; count success if at least one succeeds
                    let userSent = false;
                    for (const token of tokens) {
                        const res = await this.notificationsService.sendPushToDevice({
                            token,
                            title: body.subject || 'PayDome',
                            body: body.message,
                        });

                        await this.notificationRepo.save({
                            userId: user.id,
                            type: body.type,
                            status: res.success ? NotificationStatus.SENT : NotificationStatus.FAILED,
                            recipient: token,
                            subject: body.subject,
                            message: body.message,
                            messageId: res.messageId,
                            errorMessage: res.error,
                            sentAt: res.success ? new Date() : undefined,
                            metadata: Object.keys(notifMeta).length ? notifMeta : undefined,
                        });

                        if (res.success) userSent = true;
                    }

                    if (userSent) sentCount++;
                    else failCount++;
                }

            } catch (err: any) {
                failCount++;
                await this.notificationRepo.save({
                    userId: user.id,
                    type: body.type,
                    status: NotificationStatus.FAILED,
                    subject: body.subject,
                    message: body.message,
                    errorMessage: err?.message || 'Unknown error',
                });
            }
        });

        await Promise.allSettled(promises);

        this.adminService.logAction({
            adminUserId: req.user.id,
            action: 'SEND_NOTIFICATION',
            entityType: 'NOTIFICATION',
            oldValues: null,
            newValues: { sent: sentCount, failed: failCount, type: body.type, subject: body.subject, tiers: body.tiers ?? null, broadcast: body.broadcast ?? false, maintenance: body.maintenance ?? false, maintenanceWindow: body.maintenanceWindow ?? null },
            ipAddress: req.ip,
        });

        return {
            success: true,
            message: `Notification dispatch complete. Sent: ${sentCount}, Failed: ${failCount}`,
            sentCount,
            failCount,
        };
    }
}
