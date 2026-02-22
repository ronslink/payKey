Release Notes - Version 1.1.2 (Build 12)

## Bug Fixes

### Leave Management
- Fixed crash on the Requests tab: "String is not a subtype of num" error when loading leave requests
- Leave requests with a daily pay rate now display correctly
- Approve and Reject buttons now appear correctly for pending requests
- Rejection reason is now properly saved when rejecting a leave request

### Worker Invite & Login
- Fixed invite code not working: worker phone numbers stored in different formats
  (e.g. 0712345678 vs +254712345678) are now matched correctly
- Employee login via phone number is more reliable across all Kenyan number formats

### Terminations
- Fixed "Unable to calculate final payment" error on termination
- Final payment is now always zero or positive (no more negative values)

### Subscriptions
- Stripe subscription payments are no longer duplicated in payment history
- Subscription tier, amount, and next billing date now populate correctly after checkout

## Previous Build (1.1.1 / Build 11)

- Finance page and profile bank/M-Pesa sync
- Updated app icon (PayDome logo)
- Connected to Production environment
