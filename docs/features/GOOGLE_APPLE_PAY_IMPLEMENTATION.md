# Google Pay & Apple Pay Integration Plan

## Executive Summary
Add Google Pay and Apple Pay as wallet top-up options via Stripe Payment Sheet, enabling card payments and digital wallets globally.

---

## Cost Analysis

### Stripe Transaction Fees

| Fee Type | Rate | Example (KES 5,000 ≈ $38) |
|----------|------|---------------------------|
| Base processing | 2.9% + $0.30 | $1.40 |
| International card (+) | 1.5% | $0.57 |
| Currency conversion (+) | 1.0% | $0.38 |
| **Total worst case** | **5.4% + $0.30** | **$2.35 (~KES 305)** |

> [!WARNING]
> Stripe does not directly support Kenya. You must use your existing offshore Stripe account (UK/US entity).

### Comparison with M-Pesa

| Metric | M-Pesa (IntaSend) | Stripe (Card/Apple/Google Pay) |
|--------|-------------------|-------------------------------|
| Transaction fee | ~1-3% | 2.9-5.4% + $0.30 |
| User reach | Kenya + East Africa | Global |
| Settlement | Same day | 2-7 business days |
| Top-up speed | Instant | Instant |
| Chargebacks | None | Possible |
| Setup complexity | ✅ Already done | ⚠️ Certificates required |

### Pros vs Cons

| Pros | Cons |
|------|------|
| ✅ Global payment reach | ❌ Higher fees (5.4% vs 1-3%) |
| ✅ International users can top-up | ❌ Chargeback risk on cards |
| ✅ Apple Pay / Google Pay convenience | ❌ Apple certificate renewal (25 months) |
| ✅ Premium user experience | ❌ Google approval process required |
| ✅ Stripe already configured | ❌ 2-7 day settlement vs instant |

---

## Technical Requirements

### Prerequisites
- [x] Apple Developer Program enrollment
- [x] Stripe account with production keys
- [ ] Merchant ID in Apple Developer Portal
- [ ] Apple Pay Payment Processing Certificate
- [ ] Google Play Store distribution (already have)
- [ ] Google Pay production approval

---

## Implementation Steps

### Phase 1: Backend (2-3 hours)

#### 1.1 Add Payment Intent to StripeService
```typescript
// stripe.service.ts
async createPaymentIntent(userId: string, amount: number, currency = 'kes') {
  const stripe = this.ensureStripeConfigured();
  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 100), // cents
    currency,
    payment_method_types: ['card'],
    metadata: { userId, type: 'WALLET_TOPUP' },
  });
  return {
    clientSecret: paymentIntent.client_secret!,
    paymentIntentId: paymentIntent.id,
  };
}
```

#### 1.2 Add Endpoint
```typescript
// unified-payments.controller.ts
@Post('card-topup/create-intent')
async createCardTopupIntent(
  @Request() req: AuthenticatedRequest,
  @Body() body: { amount: number; currency?: string }
) {
  return this.stripeService.createPaymentIntent(
    req.user.userId,
    body.amount,
    body.currency || 'kes'
  );
}
```

#### 1.3 Handle Webhook
Add `payment_intent.succeeded` handler to credit wallet:
```typescript
case 'payment_intent.succeeded':
  await this.handlePaymentIntentSucceeded(event.data.object);
  break;
```

---

### Phase 2: iOS Configuration (1-2 hours)

#### 2.1 Create Merchant ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers)
2. Click **Identifiers** → **+** → **Merchant IDs**
3. Create: `merchant.co.paydome.app`

#### 2.2 Create Payment Processing Certificate
1. In Stripe Dashboard → **Settings** → **Payment methods** → **Apple Pay**
2. Download CSR from Stripe
3. Upload to Apple Developer Portal under your Merchant ID
4. Download certificate, upload back to Stripe

#### 2.3 Enable in Xcode
1. Open `ios/Runner.xcworkspace`
2. Select **Runner** target → **Signing & Capabilities**
3. Click **+ Capability** → **Apple Pay**
4. Select your Merchant ID

#### 2.4 Update Info.plist (if needed)
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
</array>
```

---

### Phase 3: Android Configuration (1 hour)

#### 3.1 Update AndroidManifest.xml
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
  android:name="com.google.android.gms.wallet.api.enabled"
  android:value="true" />
```

#### 3.2 Update MainActivity
Change from `FlutterActivity` to `FlutterFragmentActivity`:
```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```

#### 3.3 Google Pay Production Approval
1. Register at [Google Pay & Wallet Console](https://pay.google.com/business/console)
2. Complete business profile
3. Submit screenshots of working integration
4. Wait for approval (typically 1-2 weeks)

---

### Phase 4: Mobile Integration (2-3 hours)

#### 4.1 Add Dependency
```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^11.3.0
```

#### 4.2 Initialize Stripe
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_live_...';
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}
```

#### 4.3 Create Payment Service
```dart
// lib/integrations/stripe/stripe_payment_service.dart
class StripePaymentService {
  final Dio _dio;
  
  Future<bool> topUpWithCard(double amount) async {
    // 1. Get client secret from backend
    final response = await _dio.post('/payments/card-topup/create-intent', 
      data: {'amount': amount});
    final clientSecret = response.data['clientSecret'];
    
    // 2. Initialize Payment Sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'PayDome',
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: 'KE',
          currencyCode: 'KES',
          testEnv: false,
        ),
        applePay: PaymentSheetApplePay(
          merchantCountryCode: 'KE',
        ),
      ),
    );
    
    // 3. Present Payment Sheet
    await Stripe.instance.presentPaymentSheet();
    return true;
  }
}
```

#### 4.4 Update Wallet Top-Up UI
Add card payment option alongside M-Pesa in the top-up sheet.

---

## Timeline

| Phase | Duration | Blockers |
|-------|----------|----------|
| Backend | 2-3 hours | None |
| iOS Config | 1-2 hours | Apple certificate generation |
| Android Config | 1 hour | None |
| Mobile Integration | 2-3 hours | None |
| Google Pay Approval | 1-2 weeks | Google review process |
| Testing | 2-3 hours | Real device required |

**Total Development: 2-3 days**
**Total with Approval: 2-3 weeks**

---

## Verification Checklist

- [ ] Create payment intent returns valid client secret
- [ ] Webhook handles `payment_intent.succeeded`
- [ ] Wallet balance credited after successful payment
- [ ] Apple Pay shows on iOS simulator/device
- [ ] Google Pay shows on Android device
- [ ] Test with Stripe test cards
- [ ] Test with real Apple Pay (sandbox)
- [ ] Google Pay production approval received

---

## Recommendation

> [!TIP]
> **Start with backend + iOS first.** Apple Pay works immediately after certificate setup. Google Pay requires approval, which can take 1-2 weeks.

Given:
- M-Pesa covers 95%+ of Kenyan users
- Card fees are 2-3x higher
- Apple/Google Pay primarily benefits international users

**Recommendation**: Implement as a secondary payment option for premium/international users, not a replacement for M-Pesa.
