# Notifications Feature

## Overview
Multi-channel notification system supporting Email (SendGrid), SMS (Africa's Talking), and Push (Firebase).

## Environment Variables
```env
# Email - SendGrid
EMAIL_PROVIDER=SENDGRID  # or MOCK for testing
SENDGRID_API_KEY=SG.xxx
SENDGRID_FROM_EMAIL=noreply@paydome.co

# SMS - Africa's Talking
SMS_PROVIDER=AFRICASTALKING  # or MOCK for testing
AFRICANSTALKING_API_KEY=xxx
AFRICANSTALKING_USERNAME=sandbox

# Push - Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | Get user notifications |
| POST | `/notifications/send` | Send notification |
| POST | `/notifications/register-device` | Register FCM token |
| PATCH | `/notifications/:id/read` | Mark as read |

## Notification Types
- Payment confirmations
- Payroll processing complete
- Leave request updates
- Subscription reminders

## Mobile UI
- Push notification handling in `mobile/lib/core/services/notification_service.dart`

## Database Entities
- `Notification` - `backend/src/modules/notifications/entities/notification.entity.ts`
- `DeviceToken` - `backend/src/modules/notifications/entities/device-token.entity.ts`

## Current Configuration Status
- ✅ SendGrid email integration
- ✅ Africa's Talking SMS integration
- ✅ Firebase push notifications
- ✅ Mock providers for testing

## Known Gaps
| Gap | Status |
|-----|--------|
| Notification Settings UI | ❌ Coming soon message |
| Email templates | ⚠️ Basic text only |
