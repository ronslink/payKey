# IntaSend/M-Pesa Payments

## Overview
M-Pesa payment integration via IntaSend for salary payouts and wallet funding.

> **Detailed Architecture**: For a comprehensive view of the system interaction, funds flow, and security, please read [INTASEND_SYSTEM_ARCHITECTURE.md](../guides/INTASEND_SYSTEM_ARCHITECTURE.md).

## Environment Variables
```env
# IntaSend Configuration
INTASEND_PUBLISHABLE_KEY=ISPubKey_...
INTASEND_SECRET_KEY=ISSecretKey_...
INTASEND_PUBLISHABLE_KEY_TEST=ISPubKeyTest_...
INTASEND_SECRET_KEY_TEST=ISSecretKeyTest_...
INTASEND_IS_LIVE=true
INTASEND_SIMULATE=true

# M-Pesa Direct (if used)
MPESA_CONSUMER_KEY=your-key
MPESA_CONSUMER_SECRET=your-secret
MPESA_SHORTCODE=174379
MPESA_PASSKEY=your-passkey
MPESA_CALLBACK_URL=http://localhost:3000/payments/callback
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/payments/initiate-stk` | STK Push for wallet top-up |
| POST | `/payments/send-b2c` | B2C Payout (single or bulk) |
| GET | `/payments/intasend/status/:trackingId` | Check payout status |
| POST | `/payments/intasend/webhook` | IntaSend webhook handler |
| GET | `/payments/unified/wallet` | Get wallet balance |

## STK Push Flow
1. User initiates payment
2. Backend calls IntaSend API (`/v1/payment/mpesa-stk-push/`)
3. User receives M-Pesa prompt on phone
4. User enters PIN
5. Webhook confirms payment
6. Transaction recorded and wallet credited

## B2C Payout Flow (Bulk Supported)
```typescript
// Single payment
intaSendService.sendMoney([{
  account: '254700000000',
  amount: 5000,
  narrative: 'Salary Payment',
  name: 'John Doe'
}]);

// Bulk payments supported
intaSendService.sendMoney([
  { account: '254700000001', amount: 5000, narrative: 'Salary', name: 'Worker 1' },
  { account: '254700000002', amount: 6000, narrative: 'Salary', name: 'Worker 2' },
]);
```

## Sandbox vs Production
| Mode | Phone Number | Amount | Keys |
|------|--------------|--------|------|
| Sandbox | 254708374149 (B2C) | Any | TEST keys preferred |
| Sandbox Simulation | Any | Any | `INTASEND_SIMULATE=true` |
| Production | Real numbers | Real amounts | Standard keys |

## Mobile UI
- **Payments**: `mobile/lib/features/payments/presentation/pages/`
- **Wallet**: Fund wallet via STK push
- **Transactions**: View payment history

## Database Entities
- `Transaction` - `backend/src/modules/payments/entities/transaction.entity.ts`

## Current Configuration Status
- ✅ IntaSend integration working
- ✅ STK push for wallet top-up
- ✅ B2C payouts with bulk support
- ✅ Transaction tracking
- ✅ Sandbox mode for testing
- ✅ Webhook signature verification
- ✅ Payout status checking
- ✅ Idempotent webhook handling
- ✅ Payment status push notifications
- ✅ Per-worker status API endpoint

## Recent Updates
- ✅ **Bulk B2C Payments** - [`sendMoney()`](backend/src/modules/payments/intasend.service.ts:190) now accepts array of transactions
- ✅ **Payout Status Check** - [`checkPayoutStatus()`](backend/src/modules/payments/intasend.service.ts:249) endpoint added at `/payments/intasend/status/:trackingId`
- ✅ **Idempotent Webhooks** - Webhook handler checks existing status before processing
- ✅ **Bulk Transaction Matching** - Webhook now finds ALL transactions matching `invoice_id` or `tracking_id`
- ✅ **Backward Compatibility** - Legacy `/payments/send-b2c` still works with single transactions
- ✅ **Payment Status Notifications** - Push notifications sent on status changes (CLEARING, SUCCESS, FAILED). See [PAYMENT_STATUS.md](./PAYMENT_STATUS.md)
- ✅ **Working Wallets** - Each employer has a segregated IntaSend sub-account (`intasend_wallet_id`)

