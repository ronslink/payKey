import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
export declare enum NotificationType {
    SMS = "SMS",
    EMAIL = "EMAIL",
    PUSH = "PUSH"
}
export declare enum NotificationStatus {
    PENDING = "PENDING",
    SENT = "SENT",
    DELIVERED = "DELIVERED",
    FAILED = "FAILED"
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
export declare class NotificationsService {
    private configService;
    private httpService;
    private readonly logger;
    constructor(configService: ConfigService, httpService: HttpService);
    sendNotification(notificationRequest: NotificationRequest): Promise<{
        success: boolean;
        messageId?: string;
        error?: string;
    }>;
    private sendSMS;
    private sendSMSViaAfricanStalking;
    private sendSMSViaTwilio;
    private sendEmail;
    private sendPushNotification;
    sendWorkerSalaryNotification(workerPhone: string, workerName: string, netSalary: number, month: string): Promise<{
        success: boolean;
        error?: string;
    }>;
    sendLeaveApprovalNotification(workerPhone: string, workerName: string, leaveType: string, startDate: Date, endDate: Date, approved: boolean, reason?: string): Promise<{
        success: boolean;
        error?: string;
    }>;
    sendPayrollReminderNotification(employerEmail: string, employerName: string, pendingWorkers: number, dueDate: Date): Promise<{
        success: boolean;
        error?: string;
    }>;
    sendWelcomeNotification(recipientPhone: string, recipientName: string, tier: string): Promise<{
        success: boolean;
        error?: string;
    }>;
}
export {};
