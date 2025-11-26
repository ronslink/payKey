"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var NotificationsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsService = exports.NotificationStatus = exports.NotificationType = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const axios_1 = require("@nestjs/axios");
const rxjs_1 = require("rxjs");
var NotificationType;
(function (NotificationType) {
    NotificationType["SMS"] = "SMS";
    NotificationType["EMAIL"] = "EMAIL";
    NotificationType["PUSH"] = "PUSH";
})(NotificationType || (exports.NotificationType = NotificationType = {}));
var NotificationStatus;
(function (NotificationStatus) {
    NotificationStatus["PENDING"] = "PENDING";
    NotificationStatus["SENT"] = "SENT";
    NotificationStatus["DELIVERED"] = "DELIVERED";
    NotificationStatus["FAILED"] = "FAILED";
})(NotificationStatus || (exports.NotificationStatus = NotificationStatus = {}));
let NotificationsService = NotificationsService_1 = class NotificationsService {
    configService;
    httpService;
    logger = new common_1.Logger(NotificationsService_1.name);
    constructor(configService, httpService) {
        this.configService = configService;
        this.httpService = httpService;
    }
    async sendNotification(notificationRequest) {
        try {
            switch (notificationRequest.type) {
                case NotificationType.SMS:
                    return await this.sendSMS(notificationRequest);
                case NotificationType.EMAIL:
                    return await this.sendEmail(notificationRequest);
                case NotificationType.PUSH:
                    return await this.sendPushNotification(notificationRequest);
                default:
                    throw new Error(`Unsupported notification type: ${notificationRequest.type}`);
            }
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            this.logger.error(`Failed to send ${notificationRequest.type} notification:`, error);
            return {
                success: false,
                error: errorMessage,
            };
        }
    }
    async sendSMS(notificationRequest) {
        if (!notificationRequest.recipientPhone) {
            throw new Error('Recipient phone number is required for SMS notifications');
        }
        const smsProvider = this.configService.get('SMS_PROVIDER') || 'MOCK';
        const provider = smsProvider.toUpperCase();
        switch (provider) {
            case 'MOCK':
                this.logger.log(`MOCK SMS sent to ${notificationRequest.recipientPhone}: ${notificationRequest.message}`);
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
    async sendSMSViaAfricanStalking(notificationRequest) {
        const apiKey = this.configService.get('AFRICANSTALKING_API_KEY');
        const username = this.configService.get('AFRICANSTALKING_USERNAME');
        if (!apiKey || !username) {
            throw new Error('African Stalking credentials not configured');
        }
        try {
            const response = await (0, rxjs_1.lastValueFrom)(this.httpService.post('https://api.africastalking.com/version1/messaging', {
                username,
                to: notificationRequest.recipientPhone,
                message: notificationRequest.message,
            }, {
                headers: {
                    Authorization: `Bearer ${apiKey}`,
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
            }));
            const result = response.data;
            if (result.status === 'Success') {
                return {
                    success: true,
                    messageId: result.messages[0].messageId,
                };
            }
            else {
                return {
                    success: false,
                    error: result.message || 'Failed to send SMS',
                };
            }
        }
        catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Failed to send SMS';
            return {
                success: false,
                error: errorMessage,
            };
        }
    }
    async sendSMSViaTwilio(_notificationRequest) {
        throw new Error('Twilio SMS implementation not configured');
    }
    async sendEmail(notificationRequest) {
        if (!notificationRequest.recipientEmail || !notificationRequest.subject) {
            throw new Error('Recipient email and subject are required for email notifications');
        }
        this.logger.log(`MOCK EMAIL sent to ${notificationRequest.recipientEmail}`);
        this.logger.log(`Subject: ${notificationRequest.subject}`);
        this.logger.log(`Message: ${notificationRequest.message}`);
        return {
            success: true,
            messageId: `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        };
    }
    async sendPushNotification(notificationRequest) {
        this.logger.log(`MOCK PUSH notification sent: ${notificationRequest.message}`);
        return {
            success: true,
            messageId: `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        };
    }
    async sendWorkerSalaryNotification(workerPhone, workerName, netSalary, month) {
        const message = `Hi ${workerName}, your salary for ${month} has been processed. Net amount: KES ${netSalary.toFixed(2)}. Thank you!`;
        const result = await this.sendNotification({
            recipientPhone: workerPhone,
            message,
            type: NotificationType.SMS,
            priority: 'MEDIUM',
        });
        return { success: result.success, error: result.error };
    }
    async sendLeaveApprovalNotification(workerPhone, workerName, leaveType, startDate, endDate, approved, reason) {
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
    async sendPayrollReminderNotification(employerEmail, employerName, pendingWorkers, dueDate) {
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
    async sendWelcomeNotification(recipientPhone, recipientName, tier) {
        const message = `Welcome to PayKey, ${recipientName}! You're now on the ${tier} plan. Start by adding your first worker.`;
        const result = await this.sendNotification({
            recipientPhone,
            message,
            type: NotificationType.SMS,
            priority: 'LOW',
        });
        return { success: result.success, error: result.error };
    }
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = NotificationsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService,
        axios_1.HttpService])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map