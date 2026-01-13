import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

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
  recipientToken?: string; // FCM device token for push
  subject?: string;
  message: string;
  type: NotificationType;
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';
  metadata?: Record<string, any>;
}

interface PushNotificationRequest {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
  ) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    try {
      const serviceAccountPath = this.configService.get<string>(
        'FIREBASE_SERVICE_ACCOUNT_PATH',
        './firebase-service-account.json',
      );

      const absolutePath = path.resolve(serviceAccountPath);

      if (fs.existsSync(absolutePath)) {
        const serviceAccount = JSON.parse(
          fs.readFileSync(absolutePath, 'utf8'),
        );

        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
          this.firebaseInitialized = true;
          this.logger.log('Firebase Admin SDK initialized successfully');
        }
      } else {
        this.logger.warn(
          `Firebase service account file not found at ${absolutePath}. Push notifications will be mocked.`,
        );
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK:', error);
    }
  }

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
      throw new Error("Africa's Talking credentials not configured");
    }

    try {
      // Use sandbox endpoint if username is 'sandbox'
      const isSandbox = username.toLowerCase() === 'sandbox';
      const apiUrl = isSandbox
        ? 'https://api.sandbox.africastalking.com/version1/messaging'
        : 'https://api.africastalking.com/version1/messaging';

      const response = await lastValueFrom(
        this.httpService.post(
          apiUrl,
          new URLSearchParams({
            username,
            to: notificationRequest.recipientPhone!,
            message: notificationRequest.message,
          }).toString(),
          {
            headers: {
              apiKey: apiKey,
              'Content-Type': 'application/x-www-form-urlencoded',
              Accept: 'application/json',
            },
          },
        ),
      );

      const result = response.data as {
        SMSMessageData: {
          Message: string;
          Recipients: Array<{ messageId: string; status: string }>;
        };
      };

      if (result.SMSMessageData?.Recipients?.[0]?.status === 'Success') {
        return {
          success: true,
          messageId: result.SMSMessageData.Recipients[0].messageId,
        };
      } else {
        return {
          success: false,
          error: result.SMSMessageData?.Message || 'Failed to send SMS',
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

    const emailProvider =
      (this.configService.get('EMAIL_PROVIDER') as string) || 'MOCK';

    switch (emailProvider.toUpperCase()) {
      case 'SENDGRID':
        return await this.sendEmailViaSendGrid(notificationRequest);

      case 'MOCK':
      default:
        this.logger.log(
          `MOCK EMAIL sent to ${notificationRequest.recipientEmail}`,
        );
        this.logger.log(`Subject: ${notificationRequest.subject}`);
        this.logger.log(`Message: ${notificationRequest.message}`);
        return {
          success: true,
          messageId: `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        };
    }
  }

  private async sendEmailViaSendGrid(
    notificationRequest: NotificationRequest,
  ): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    const apiKey = this.configService.get('SENDGRID_API_KEY') as string;
    const fromEmail = this.configService.get(
      'SENDGRID_FROM_EMAIL',
      'noreply@paydome.co',
    );

    if (!apiKey) {
      throw new Error('SendGrid API key not configured');
    }

    try {
      const response = await lastValueFrom(
        this.httpService.post(
          'https://api.sendgrid.com/v3/mail/send',
          {
            personalizations: [
              {
                to: [{ email: notificationRequest.recipientEmail }],
              },
            ],
            from: { email: fromEmail },
            subject: notificationRequest.subject,
            content: [
              {
                type: 'text/plain',
                value: notificationRequest.message,
              },
            ],
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
            },
          },
        ),
      );

      return {
        success: true,
        messageId: response.headers['x-message-id'] || `sendgrid_${Date.now()}`,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to send email';
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  private async sendPushNotification(
    notificationRequest: NotificationRequest,
  ): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    if (!notificationRequest.recipientToken) {
      this.logger.warn('No FCM token provided for push notification');
      return {
        success: false,
        error: 'No FCM token provided',
      };
    }

    if (!this.firebaseInitialized) {
      this.logger.log(
        `MOCK PUSH notification sent: ${notificationRequest.message}`,
      );
      return {
        success: true,
        messageId: `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      };
    }

    try {
      const message: admin.messaging.Message = {
        token: notificationRequest.recipientToken,
        notification: {
          title: notificationRequest.subject || 'PayDome',
          body: notificationRequest.message,
        },
        data: notificationRequest.metadata as
          | Record<string, string>
          | undefined,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Push notification sent successfully: ${response}`);

      return {
        success: true,
        messageId: response,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error
          ? error.message
          : 'Failed to send push notification';
      this.logger.error('Push notification failed:', error);
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  // Public method for sending push to a specific device token
  async sendPushToDevice(request: PushNotificationRequest): Promise<{
    success: boolean;
    messageId?: string;
    error?: string;
  }> {
    return this.sendNotification({
      recipientToken: request.token,
      subject: request.title,
      message: request.body,
      type: NotificationType.PUSH,
      metadata: request.data,
    });
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
    const subject = 'PayDome - Payroll Processing Reminder';
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
    const message = `Welcome to PayDome, ${recipientName}! You're now on the ${tier} plan. Start by adding your first worker.`;

    const result = await this.sendNotification({
      recipientPhone,
      message,
      type: NotificationType.SMS,
      priority: 'LOW',
    });

    return { success: result.success, error: result.error };
  }
}
