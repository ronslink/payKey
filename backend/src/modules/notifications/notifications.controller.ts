import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceToken, DevicePlatform } from './entities/device-token.entity';
import {
  Notification,
  NotificationStatus,
} from './entities/notification.entity';

interface RegisterDeviceTokenDto {
  token: string;
  platform: DevicePlatform;
  deviceId?: string;
}

interface SendTestNotificationDto {
  type: 'SMS' | 'EMAIL' | 'PUSH';
  recipient?: string; // Phone for SMS, email for EMAIL, token for PUSH
  message: string;
  subject?: string;
}

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    @InjectRepository(DeviceToken)
    private readonly deviceTokenRepository: Repository<DeviceToken>,
    @InjectRepository(Notification)
    private readonly notificationRepository: Repository<Notification>,
  ) {}

  // ==========================================================================
  // Device Token Management
  // ==========================================================================

  @Post('device-token')
  @HttpCode(HttpStatus.OK)
  async registerDeviceToken(
    @Request() req: { user: { userId: string } },
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    const userId = req.user.userId;

    // Check if token already exists for this user
    let deviceToken = await this.deviceTokenRepository.findOne({
      where: { userId, token: dto.token },
    });

    if (deviceToken) {
      // Update existing token
      deviceToken.isActive = true;
      deviceToken.lastUsedAt = new Date();
      deviceToken.platform = dto.platform;
      if (dto.deviceId) deviceToken.deviceId = dto.deviceId;
    } else {
      // Check if this device already has a different token (replace old one)
      if (dto.deviceId) {
        await this.deviceTokenRepository.update(
          { userId, deviceId: dto.deviceId },
          { isActive: false },
        );
      }

      // Create new token
      deviceToken = this.deviceTokenRepository.create({
        userId,
        token: dto.token,
        platform: dto.platform,
        deviceId: dto.deviceId,
        isActive: true,
        lastUsedAt: new Date(),
      });
    }

    await this.deviceTokenRepository.save(deviceToken);

    return {
      success: true,
      message: 'Device token registered successfully',
    };
  }

  @Delete('device-token/:token')
  async unregisterDeviceToken(
    @Request() req: { user: { userId: string } },
    @Param('token') token: string,
  ) {
    const userId = req.user.userId;

    await this.deviceTokenRepository.update(
      { userId, token },
      { isActive: false },
    );

    return {
      success: true,
      message: 'Device token unregistered',
    };
  }

  @Get('device-tokens')
  async getDeviceTokens(@Request() req: { user: { userId: string } }) {
    const tokens = await this.deviceTokenRepository.find({
      where: { userId: req.user.userId, isActive: true },
      select: ['id', 'platform', 'deviceId', 'lastUsedAt', 'createdAt'],
    });

    return { tokens };
  }

  // ==========================================================================
  // Notification History
  // ==========================================================================

  @Get()
  async getNotifications(
    @Request() req: { user: { userId: string } },
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('status') status?: NotificationStatus,
  ) {
    const queryBuilder = this.notificationRepository
      .createQueryBuilder('notification')
      .where('notification.userId = :userId', { userId: req.user.userId })
      .orderBy('notification.createdAt', 'DESC');

    if (status) {
      queryBuilder.andWhere('notification.status = :status', { status });
    }

    const total = await queryBuilder.getCount();

    const notifications = await queryBuilder
      .take(parseInt(limit || '20', 10))
      .skip(parseInt(offset || '0', 10))
      .getMany();

    return {
      notifications,
      total,
      limit: parseInt(limit || '20', 10),
      offset: parseInt(offset || '0', 10),
    };
  }

  @Get(':id')
  async getNotification(
    @Request() req: { user: { userId: string } },
    @Param('id') id: string,
  ) {
    const notification = await this.notificationRepository.findOne({
      where: { id, userId: req.user.userId },
    });

    if (!notification) {
      return { error: 'Notification not found' };
    }

    return notification;
  }

  // ==========================================================================
  // Test Endpoint (for development)
  // ==========================================================================

  @Post('test')
  async sendTestNotification(
    @Request() req: { user: { userId: string } },
    @Body() dto: SendTestNotificationDto,
  ) {
    const { type, recipient, message, subject } = dto;

    let result;

    switch (type) {
      case 'SMS':
        if (!recipient) {
          return { success: false, error: 'Recipient phone required for SMS' };
        }
        result = await this.notificationsService.sendNotification({
          recipientPhone: recipient,
          message,
          type: 'SMS' as any,
        });
        break;

      case 'EMAIL':
        if (!recipient || !subject) {
          return {
            success: false,
            error: 'Recipient email and subject required',
          };
        }
        result = await this.notificationsService.sendNotification({
          recipientEmail: recipient,
          subject,
          message,
          type: 'EMAIL' as any,
        });
        break;

      case 'PUSH':
        // Get user's FCM token if no recipient specified
        let token = recipient;
        if (!token) {
          const deviceToken = await this.deviceTokenRepository.findOne({
            where: { userId: req.user.userId, isActive: true },
            order: { lastUsedAt: 'DESC' },
          });
          token = deviceToken?.token;
        }

        if (!token) {
          return { success: false, error: 'No device token found' };
        }

        result = await this.notificationsService.sendPushToDevice({
          token,
          title: subject || 'PayDome',
          body: message,
        });
        break;

      default:
        return { success: false, error: 'Invalid notification type' };
    }

    // Save notification to history
    const notification = this.notificationRepository.create({
      userId: req.user.userId,
      type: type as any,
      status: result.success
        ? NotificationStatus.SENT
        : NotificationStatus.FAILED,
      recipient,
      subject,
      message,
      messageId: result.messageId,
      errorMessage: result.error,
      sentAt: result.success ? new Date() : undefined,
    });
    await this.notificationRepository.save(notification);

    return {
      success: result.success,
      messageId: result.messageId,
      error: result.error,
      notificationId: notification.id,
    };
  }
}
