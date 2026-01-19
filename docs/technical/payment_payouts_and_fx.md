# Payment Payouts & FX Logic

This document outlines the implementation details for Automated Payroll Payouts (Bank/Mobile) and Currency Conversion (FX) logic within the PayKey backend.

## 1. Automated Payouts (IntaSend)

The `PayrollPaymentService` handles the disbursement of funds to workers after a payroll run is finalized.

### Supported Methods
1.  **Mobile (M-Pesa B2C)**: Direct transfer to worker's mobile number.
2.  **Bank (PesaLink)**: Real-time bank transfer via IntaSend.

### Implementation Details

#### Bank Payouts (`processBankBatch`)
*   **Provider**: IntaSend (`provider: 'PESALINK'`).
*   **Wallet Source**: Funds are deducted from the **Employer's IntaSend Wallet**.
    *   *Critical*: The `wallet_id` of the employer is explicitly passed to `IntaSendService.sendToBank`.
    *   If `wallet_id` is missing, IntaSend may default to the master account or fail if sub-wallets are enforced.
*   **Batching**: Requests are batched (default size: 10) to avoid timeouts and ensure reliable processing.
*   **Flow**:
    1.  Validate worker bank details (`bankAccount`, `bankCode`).
    2.  Deduct total batch amount from Employer's local `walletBalance`.
    3.  Create PENDING `Transaction` records.
    4.  Initiate IntaSend API call.
    5.  Update records to `processing` (or `paid` in Sandbox).
    6.  **Error Handling**: If the API call fails, funds are refunded to the Employer's wallet and transactions are marked `FAILED`.

## 2. Stripe Top-Ups & FX Logic

Users can top up their wallets using Stripe (Card or SEPA Direct Debit). Since the primary system currency is **KES**, functionality exists to handle **EUR** deposits.

### FX Flow (`StripeService`)
1.  **Payment Intent**: Created with `currency: 'eur'` (or user selection).
2.  **Webhook** (`payment_intent.succeeded`):
    *   Receives payload with `amount_received` (in Cents, e.g., EUR).
    *   **Conversion**:
        *   Checks `ExchangeRateService` for latest `EUR -> KES` rate.
        *   Calculates `creditedAmount = amountReceived * rate`.
    *   **Metadata**: Saves the applied rate and breakdown in `Transaction.metadata.fxApplied`.
3.  **Credit**: The user's `walletBalance` is incremented by the **KES** amount.

### Notifications
*   Upon successful top-up, a Push Notification is sent to the user's active device (`DeviceToken`).

## 3. SEPA Integration Status

### Supported: SEPA Pay-ins (Top-Ups)
*   Users can fund their wallets using SEPA Direct Debit via Stripe.
*   Handled via standard `PaymentIntent` flow.

### Not Supported: SEPA Payouts
*   **Decision**: We currently **do not** support paying out workers via SEPA Transfer.
*   **Reason**: Payouts to third-party SEPA bank accounts require **Stripe Connect** (onboarding workers as Connected Accounts), which is a significant architectural change.
*   **Workaround**: Workers with European bank accounts cannot be paid directly via the system currently; this feature is restricted to Kenyan (IntaSend) corridors.
