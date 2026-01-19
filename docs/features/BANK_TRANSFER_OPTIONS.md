# Alternative Payment Methods: PesaLink & SEPA

## Overview
Lower-cost alternatives to card payments (Apple/Google Pay) for wallet top-up.

---

## Option 1: PesaLink (Kenya Bank Transfers)

### What is PesaLink?
Instant bank-to-bank transfers within Kenya. Works 24/7 across 80+ banks.

### Integration Status
| Aspect | Status |
|--------|--------|
| Provider | IntaSend (already integrated) |
| API Available | ✅ Yes |
| Implementation | ~4-6 hours |

### Specs
| Parameter | Value |
|-----------|-------|
| Min amount | KES 100 |
| Max amount | KES 999,999 |
| Speed | Instant (<10 seconds) |
| Fee (IntaSend) | ~1% or flat fee |
| Availability | 24/7 |

### Cost Comparison (KES 20,000 salary, 12 months)

| Method | Fee Rate | Annual Cost |
|--------|----------|-------------|
| **PesaLink** | ~1% | **KES 2,400** (~€16) |
| M-Pesa | ~2.5% | KES 6,000 (~€40) |
| Apple/Google Pay | ~5.6% | KES 13,440 (~€90) |

### API Flow
```
POST /api/v1/send-money/bank/
{
  "provider": "pesalink",
  "account_number": "1234567890",
  "bank_code": "01",
  "amount": 20000,
  "narrative": "Salary Payment"
}
```

### Implementation Steps
1. Enable bank transfers in IntaSend dashboard
2. Add `sendPesaLink()` method to `intasend.service.ts`
3. Add endpoint `/payments/pesalink/send`
4. Update mobile UI with bank transfer option

---

## Option 2: SEPA (European Bank Transfers)

### What is SEPA?
Single Euro Payments Area - Eurozone bank transfers with low fees.

### Best Providers for NestJS + Flutter

| Provider | SEPA Fee | Integration | Notes |
|----------|----------|-------------|-------|
| **Stripe** | €0.35/tx | ✅ Already have | SEPA Direct Debit |
| **GoCardless** | 1% + €0.25 (max €10) | New integration | Specializes in bank debits |
| **Adyen** | ~€0.10/tx | Complex | Enterprise-focused |

### Recommended: Stripe SEPA Direct Debit
Since you already have Stripe configured, adding SEPA is straightforward.

#### How it Works
1. User provides IBAN
2. Stripe creates mandate (one-time authorization)
3. Funds pulled from user's bank account
4. Webhook confirms success (takes 5-7 business days first time)

#### Cost Comparison (€133 payment, 12 months)

| Method | Fee | Annual Cost |
|--------|-----|-------------|
| **SEPA** | €0.35/tx | **€4.20** |
| Apple/Google Pay | €7.48/tx | €89.76 |

**Savings: €85.56/year per European user!**

### Implementation Steps (Stripe SEPA)
1. Enable SEPA in Stripe Dashboard
2. Add SEPA mandate creation endpoint
3. Add SEPA payment confirmation endpoint
4. Handle webhook `payment_intent.succeeded`
5. Mobile: Add IBAN input UI

---

## Comparison Matrix

| Feature | PesaLink | SEPA | M-Pesa | Apple/Google Pay |
|---------|----------|------|--------|------------------|
| Region | 🇰🇪 Kenya | 🇪🇺 Europe | 🇰🇪 Kenya | 🌍 Global |
| Fee | ~1% | ~€0.35 flat | ~2.5% | ~5.6% |
| Speed | Instant | 1-7 days | Instant | Instant |
| Already integrated | ✅ IntaSend | ⚠️ Stripe exists | ✅ Yes | ❌ No |
| Setup effort | Low | Low | Done | Medium |
| User convenience | Medium | Medium | High | High |

---

## Recommendation

### Priority Order
1. **PesaLink** (Low effort, IntaSend ready) - For Kenya B2B/bank users
2. **SEPA via Stripe** (Low effort, Stripe ready) - For European users
3. **Apple/Google Pay** (Medium effort) - For premium/international UX

### Implementation Timeline
| Phase | Effort | Savings vs Cards |
|-------|--------|------------------|
| PesaLink | 4-6 hours | 4.6% per tx |
| SEPA | 1-2 days | 5.2% per tx |
| Apple/Google Pay | 2-3 days | N/A (most expensive) |

---

## Next Steps
1. Decide on priority (PesaLink vs SEPA vs both)
2. Review IntaSend bank transfer documentation
3. Enable SEPA in Stripe Dashboard
4. Begin implementation
