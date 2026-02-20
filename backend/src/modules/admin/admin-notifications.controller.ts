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
            type: NotificationType;
            subject?: string;
            message: string;
        }
    ) {
        if (!body.broadcast && (!body.userIds || body.userIds.length === 0)) {
            throw new BadRequestException('Must provide userIds or set broadcast to true');
        }

        if (body.type === NotificationType.EMAIL && !body.subject) {
            throw new BadRequestException('Subject is required for EMAIL notifications');
        }

        let users: User[] = [];
        if (body.broadcast) {
            users = await this.userRepo.find();
        } else {
            users = await this.userRepo.find({ where: { id: In(body.userIds!) } });
        }

        let sentCount = 0;
        let failCount = 0;

        // Perform parallel sends
        const promises = users.map(async (user) => {
            try {
                let toSend: any = {
                    type: body.type,
                    subject: body.subject,
                    message: body.message,
                };

                if (body.type === NotificationType.EMAIL) {
                    if (!user.email) throw new Error('No email found');
                    toSend.recipientEmail = user.email;
                } else if (body.type === NotificationType.SMS) {
                    if (!user.phoneNumber && !user.mpesaPhone) throw new Error('No phone found');
                    toSend.recipientPhone = user.phoneNumber || user.mpesaPhone;
                } else if (body.type === NotificationType.PUSH) {
                    // Requires user to have registered an FCM token which may be on another entity
                    // For now, Push notifications might fail if FCM token is not passed,
                    // depending on how they are architected. If they are stored somewhere else, we need to fetch them.
                    // The system config mentions 'recipientToken'. We will skip push if no token logic is in user.
                    // Assuming for MVP we can log it.
                    throw new Error('Push through admin console requires user device token registry (not fully implemented)');
                }

                const res = await this.notificationsService.sendNotification(toSend);

                // Save to DB
                await this.notificationRepo.save({
                    userId: user.id,
                    type: body.type,
                    status: res.success ? NotificationStatus.SENT : NotificationStatus.FAILED,
                    recipient: toSend.recipientEmail || toSend.recipientPhone,
                    subject: body.subject,
                    message: body.message,
                    messageId: res.messageId,
                    errorMessage: res.error,
                    sentAt: res.success ? new Date() : undefined,
                });

                if (res.success) sentCount++;
                else failCount++;
            } catch (err: any) {
                failCount++;
                // Save failed to DB
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
            newValues: { sent: sentCount, failed: failCount, type: body.type, subject: body.subject },
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
