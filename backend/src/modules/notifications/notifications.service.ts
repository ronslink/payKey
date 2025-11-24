import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';

export enum NotificationType {
  SMS = 'SMS',
  EMAIL = 'EMAIL',
  PUSH = 'PUSH',
}

export enum NotificationStatus {
  PENDING = 'PENDING',
  SENT = 'SENT',
  DELIVERED = 'DELIVERED',
  FAILED = 'FAILED',
}

interface NotificationRequest {
  recipientPhone?: string;
  recipientEmail?: string;
  subject?: string;
  message: string;
  type: NotificationType;
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';
  metadata?: Record<string, any>;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
  ) {}

  async sendNotification(notificationRequest: NotificationRequest): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    try {
      switch (notificationRequest.type) {
        case NotificationType.SMS:
          return await this.sendSMS(notificationRequest);
        case NotificationType.EMAIL:
          return await this.sendEmail(notificationRequest);
        case NotificationType.PUSH:
          return await this.sendPushNotification(notificationRequest);
        default:
          throw new Error(
            `Unsupported notification type: ${notificationRequest.type}`,
          );
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(
        `Failed to send ${notificationRequest.type} notification:`,
        error,
      );
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  private async sendSMS(notificationRequest: NotificationRequest): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    if (!notificationRequest.recipientPhone) {
      throw new Error(
        'Recipient phone number is required for SMS notifications',
      );
    }

    // Simulate SMS sending (replace with actual SMS provider integration)
    const smsProvider =
      (this.configService.get('SMS_PROVIDER') as string) || 'MOCK';

    const provider = smsProvider.toUpperCase();
    switch (provider) {
      case 'MOCK':
        this.logger.log(
          `MOCK SMS sent to ${notificationRequest.recipientPhone}: ${notificationRequest.message}`,
        );
        return {
          success: true,
          messageId: `sms_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        };

      case 'AFRICANSTALKING':
        return await this.sendSMSViaAfricanStalking(notificationRequest);

      case 'TWILIO':
        return await this.sendSMSViaTwilio(notificationRequest);

      default:
        throw new Error(`Unsupported SMS provider: ${smsProvider}`);
    }
  }

  private async sendSMSViaAfricanStalking(
    notificationRequest: NotificationRequest,
  ): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    const apiKey = this.configService.get('AFRICANSTALKING_API_KEY') as string;
    const username = this.configService.get(
      'AFRICANSTALKING_USERNAME',
    ) as string;

    if (!apiKey || !username) {
      throw new Error('African Stalking credentials not configured');
    }

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          'https://api.africastalking.com/version1/messaging',
          {
            username,
            to: notificationRequest.recipientPhone,
            message: notificationRequest.message,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          },
        ),
      );

      const result = response.data as {
        status: string;
        message: string;
        messages: Array<{ messageId: string }>;
      };
      if (result.status === 'Success') {
        return {
          success: true,
          messageId: result.messages[0].messageId,
        };
      } else {
        return {
          success: false,
          error: result.message || 'Failed to send SMS',
        };
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to send SMS';
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  private async sendSMSViaTwilio(
    _notificationRequest: NotificationRequest,
  ): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    // Implementation for Twilio SMS
    // This would require Twilio SDK and credentials
    throw new Error('Twilio SMS implementation not configured');
  }

  private async sendEmail(notificationRequest: NotificationRequest): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    if (!notificationRequest.recipientEmail || !notificationRequest.subject) {
      throw new Error(
        'Recipient email and subject are required for email notifications',
      );
    }

    // For MVP, we'll simulate email sending
    // In production, integrate with services like SendGrid, AWS SES, or similar
    this.logger.log(`MOCK EMAIL sent to ${notificationRequest.recipientEmail}`);
    this.logger.log(`Subject: ${notificationRequest.subject}`);
    this.logger.log(`Message: ${notificationRequest.message}`);

    return {
      success: true,
      messageId: `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  private async sendPushNotification(
    notificationRequest: NotificationRequest,
  ): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    // Implementation for push notifications (Firebase, etc.)
    // For MVP, we'll simulate this as well
    this.logger.log(
      `MOCK PUSH notification sent: ${notificationRequest.message}`,
    );

    return {
      success: true,
      messageId: `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };
  }

  // Helper methods for common notifications

  async sendWorkerSalaryNotification(
    workerPhone: string,
    workerName: string,
    netSalary: number,
    month: string,
  ): Promise<{ success: boolean; error?: string }> {
    const message = `Hi ${workerName}, your salary for ${month} has been processed. Net amount: KES ${netSalary.toFixed(2)}. Thank you!`;

    const result = await this.sendNotification({
      recipientPhone: workerPhone,
      message,
      type: NotificationType.SMS,
      priority: 'MEDIUM',
    });

    return { success: result.success, error: result.error };
  }

  async sendLeaveApprovalNotification(
    workerPhone: string,
    workerName: string,
    leaveType: string,
    startDate: Date,
    endDate: Date,
    approved: boolean,
    reason?: string,
  ): Promise<{ success: boolean; error?: string }> {
    const dateRange = `${startDate.toDateString()} to ${endDate.toDateString()}`;
    const status = approved ? 'APPROVED' : 'REJECTED';

    let message = `Hi ${workerName}, your ${leaveType} leave request from ${dateRange} has been ${status}.`;

    if (!approved && reason) {
      message += ` Reason: ${reason}`;
    }

    const result = await this.sendNotification({
      recipientPhone: workerPhone,
      message,
      type: NotificationType.SMS,
      priority: 'MEDIUM',
    });

    return { success: result.success, error: result.error };
  }

  async sendPayrollReminderNotification(
    employerEmail: string,
    employerName: string,
    pendingWorkers: number,
    dueDate: Date,
  ): Promise<{ success: boolean; error?: string }> {
    const subject = 'PayKey - Payroll Processing Reminder';
    const message = `Hi ${employerName}, you have ${pendingWorkers} workers pending payroll processing. Due date: ${dueDate.toDateString()}. Please process payments to avoid delays.`;

    const result = await this.sendNotification({
      recipientEmail: employerEmail,
      subject,
      message,
      type: NotificationType.EMAIL,
      priority: 'HIGH',
    });

    return { success: result.success, error: result.error };
  }

  async sendWelcomeNotification(
    recipientPhone: string,
    recipientName: string,
    tier: string,
  ): Promise<{ success: boolean; error?: string }> {
    const message = `Welcome to PayKey, ${recipientName}! You're now on the ${tier} plan. Start by adding your first worker.`;

    const result = await this.sendNotification({
      recipientPhone,
      message,
      type: NotificationType.SMS,
      priority: 'LOW',
    });

    return { success: result.success, error: result.error };
  }
}
