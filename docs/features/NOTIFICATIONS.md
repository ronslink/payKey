# Notifications

## Overview

Multi-channel notification system supporting Email (SendGrid), SMS (Africa's Talking), and Push (Firebase FCM). Notifications are sent automatically by system events (payments, payroll, subscriptions) and manually by admins through the admin console. Campaign delivery is also handled through this system — see [CAMPAIGNS.md](./CAMPAIGNS.md).

---

## Notification Channels

| Channel | Provider | Config key | Dev fallback |
|---|---|---|---|
| Email | SendGrid | `EMAIL_PROVIDER=SENDGRID` | `EMAIL_PROVIDER=MOCK` |
| SMS | Africa's Talking | `SMS_PROVIDER=AFRICASTALKING` | `SMS_PROVIDER=MOCK` |
| Push | Firebase FCM | `FIREBASE_SERVICE_ACCOUNT_PATH` | Mock if file missing |

---

## Environment Variables

```env
# Email — SendGrid
EMAIL_PROVIDER=SENDGRID          # or MOCK for local development
SENDGRID_API_KEY=SG.xxx
SENDGRID_FROM_EMAIL=noreply@paydome.co

# SMS — Africa's Talking
SMS_PROVIDER=AFRICASTALKING      # or MOCK for local development
AFRICANSTALKING_API_KEY=xxx
AFRICANSTALKING_USERNAME=sandbox # use "sandbox" for test environment

# Push — Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

> **Mock mode:** If providers are set to `MOCK` or credentials are missing, all sends succeed silently and are logged to the NestJS console. No real messages are delivered. This is the default in local Docker development.

---

## Delivery Sources

There are three paths that trigger notifications:

### 1. Transactional (Automatic — System Events)

Fired automatically by backend business logic when specific events occur:

| Event | Channel | Trigger location |
|---|---|---|
| Payment status change (PENDING → SUCCESS/FAILED) | Push | `payments.controller.ts` — IntaSend webhook |
| Payroll disbursement per worker | SMS | `PayrollService` after processing |
| Subscription renewed successfully | Push | `subscription.processor.ts` |
| Subscription renewal failed | Push | `subscription.processor.ts` |
| Wallet top-up completed | Push | `stripe.service.ts` |
| Welcome new employer | SMS | `UsersService` on registration |
| Payroll reminder (upcoming due date) | Email | Called from payroll scheduler |
| Leave request approved/rejected | SMS | `LeaveService` |

### 2. Manual Broadcast (Admin Console)

Admins compose and send ad-hoc notifications from:

**Admin → Notifications → Send Notification**

- **Channels:** Email, SMS, or Push
- **Recipients:** All employers (broadcast) or specific selected users
- **Push:** Looks up all active `device_tokens` for each recipient and sends to every registered device
- Saved to the `notifications` table for audit history

**Note on SMS broadcast:** SMS is the only channel not supported by the Campaign system. Use manual broadcast for SMS campaigns.

### 3. Campaign Dispatch (Automatic — Scheduled)

The `CampaignScheduler` fires every 15 minutes and sends EMAIL and IN_APP_NOTIFICATION type campaigns automatically. See [CAMPAIGNS.md](./CAMPAIGNS.md) for full details.

---

## API Endpoints

### User-Facing

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/notifications` | Get the calling user's notification history |
| `POST` | `/notifications/device-token` | Register or update an FCM device token |
| `DELETE` | `/notifications/device-token/:token` | Unregister a device token (on logout) |
| `GET` | `/notifications/device-tokens` | List all active tokens for the calling user |
| `POST` | `/notifications/test` | Test endpoint — send a test notification to yourself |

### Admin-Only

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/notifications` | List all notification history (all users, paginated) |
| `POST` | `/api/admin/notifications/send` | Send a notification to selected users or broadcast |

---

## Device Token Lifecycle

The Flutter app manages FCM tokens through the following flow:

```
App starts / user logs in
    → NotificationService.init() in Flutter
    → Requests push permissions (iOS prompt, Android auto-grant)
    → Gets FCM token from Firebase
    → Sends token to POST /notifications/device-token
    → Token stored in device_tokens table with userId, platform, deviceId

Token refresh (Firebase rotates tokens periodically)
    → Flutter onTokenRefresh callback fires
    → New token sent to POST /notifications/device-token
    → Old token record updated

User logs out
    → App calls DELETE /notifications/device-token/:token
    → Token marked isActive = false

Stale token detected (Firebase rejects it)
    → CampaignScheduler or payment notification detects the error
    → Token automatically marked isActive = false in device_tokens table
```

One user can have multiple active tokens (multiple devices / reinstalls).

---

## Database Entities

### `notifications` table

Records every notification sent, with delivery outcome.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `userId` | UUID | FK → `users.id` |
| `type` | enum | EMAIL, SMS, PUSH |
| `status` | enum | PENDING, SENT, DELIVERED, FAILED |
| `recipient` | varchar | Email address, phone number, or FCM token |
| `subject` | varchar | Email subject (EMAIL only) |
| `message` | text | Message body |
| `messageId` | varchar | Provider message ID (for tracking) |
| `errorMessage` | text | Failure reason if status = FAILED |
| `sentAt` | timestamptz | When the send was attempted |
| `deliveredAt` | timestamptz | Delivery confirmation (webhook, if available) |
| `createdAt` | timestamptz | |
| `updatedAt` | timestamptz | |

### `device_tokens` table

Stores FCM device tokens for push notification delivery.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `userId` | UUID | FK → `users.id` (CASCADE DELETE) |
| `token` | varchar | FCM registration token |
| `platform` | enum | ANDROID, IOS, WEB |
| `deviceId` | varchar | Unique device identifier |
| `isActive` | boolean | False if token is stale or user logged out |
| `lastUsedAt` | timestamptz | Updated on each registration |
| `createdAt` | timestamptz | |
| `updatedAt` | timestamptz | |

---

## Pre-built Notification Methods

The `NotificationsService` exposes helper methods for common business events. Prefer these over raw `sendNotification()` calls:

| Method | Channel | When to use |
|---|---|---|
| `sendWorkerSalaryNotification(phone, name, amount, month)` | SMS | After payroll record processed |
| `sendLeaveApprovalNotification(phone, name, type, dates, approved)` | SMS | After leave decision |
| `sendPayrollReminderNotification(email, name, pendingCount, dueDate)` | Email | Scheduled reminder |
| `sendWelcomeNotification(phone, name, tier)` | SMS | New employer registration |
| `sendPaymentStatusNotification(fcmToken, workerName, amount, status, type)` | Push | Payment webhook events |
| `sendPushToDevice(token, title, body, data)` | Push | Generic push to a single device |

---

## Notification Flow Diagram

```
Business Event occurs
        ↓
NotificationsService.sendNotification({
    type: EMAIL | SMS | PUSH,
    recipientEmail | recipientPhone | recipientToken,
    subject?, message
})
        ↓
Switch on type:
    EMAIL  → sendEmailViaSendGrid()   → SendGrid API
    SMS    → sendSMSViaAfricanStalking() → Africa's Talking API
    PUSH   → sendPushNotification()   → Firebase Admin SDK → FCM
        ↓
Result: { success, messageId?, error? }
        ↓
Saved to notifications table (status: SENT | FAILED)
```

---

## Related Files

| File | Purpose |
|---|---|
| `backend/src/modules/notifications/notifications.service.ts` | Core service — all send logic |
| `backend/src/modules/notifications/notifications.controller.ts` | Device token + user notification endpoints |
| `backend/src/modules/notifications/entities/notification.entity.ts` | Notification record entity |
| `backend/src/modules/notifications/entities/device-token.entity.ts` | FCM device token entity |
| `backend/src/modules/admin/admin-notifications.controller.ts` | Admin broadcast endpoint |
| `mobile/lib/core/services/notification_service.dart` | Flutter FCM integration |

## Related Documentation

- [CAMPAIGNS.md](./CAMPAIGNS.md) — automated campaign delivery via notifications
- [SUBSCRIPTIONS.md](./SUBSCRIPTIONS.md) — subscription lifecycle and renewal notifications
- [PAYMENT_STATUS.md](./PAYMENT_STATUS.md) — payment status push notifications

## Current Status

| Feature | Status |
|---|---|
| SendGrid email | ✅ Implemented |
| Africa's Talking SMS | ✅ Implemented |
| Firebase FCM push | ✅ Implemented |
| Mock providers for dev | ✅ Implemented |
| Admin email/SMS broadcast | ✅ Implemented |
| Admin push broadcast | ✅ Implemented (device_tokens lookup wired in Feb 2026) |
| Campaign auto-dispatch | ✅ Implemented (CampaignScheduler, Feb 2026) |
| Email templates (HTML) | ⚠️ Plain text only — HTML templates not yet built |
| Delivery webhooks (read receipts) | ⚠️ Not yet implemented |
| Notification preferences (user opt-out) | ❌ Not implemented |
