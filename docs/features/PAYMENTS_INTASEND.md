# IntaSend/M-Pesa Payments

## Overview
M-Pesa payment integration via IntaSend for salary payouts and wallet funding.

## Environment Variables
```env
# IntaSend Configuration
INTASEND_PUBLISHABLE_KEY=ISPubKey_...
INTASEND_SECRET_KEY=ISSecretKey_...
INTASEND_SANDBOX=true

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
| POST | `/payments/unified/mpesa/topup` | STK Push for wallet |
| POST | `/payments/process` | Process payroll payment |
| GET | `/transactions` | Get transaction history |
| GET | `/transactions/:id` | Get transaction details |

## STK Push Flow
1. User initiates payment
2. Backend calls IntaSend API
3. User receives M-Pesa prompt on phone
4. User enters PIN
5. Webhook confirms payment
6. Transaction recorded

## Sandbox vs Production
| Mode | Phone Number | Amount |
|------|--------------|--------|
| Sandbox | 254708374149 | Any |
| Sandbox Simulation | Any | 10 KES |
| Production | Real numbers | Real amounts |

## Mobile UI
- **Payments**: `mobile/lib/features/payments/presentation/pages/`
- **Wallet**: Fund wallet via STK push
- **Transactions**: View payment history

## Database Entities
- `Transaction` - `backend/src/modules/payments/entities/transaction.entity.ts`

## Current Configuration Status
- ✅ IntaSend integration working
- ✅ STK push for wallet top-up
- ✅ Transaction tracking
- ✅ Sandbox mode for testing

## Known Gaps
| Gap | Status |
|-----|--------|
| IntaSend Signature Verification | ⚠️ TODO in intasend.service.ts |
| B2C Bulk Payments | ⚠️ Implemented, needs more testing |
