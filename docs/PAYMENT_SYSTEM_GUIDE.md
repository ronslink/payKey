# PayKey Payment System - Complete Implementation Guide

## Overview

The PayKey payment system provides a comprehensive, unified solution for handling **subscriptions**, **M-Pesa employee payments**, and **tax payments**. The system follows best practices for security, scalability, and user experience.

## 🏗️ Architecture

### Core Components

1. **Stripe Service** - Handles subscription billing and payments
2. **M-Pesa Service** - Manages employee salary payments and wallet top-ups
3. **Tax Payment Service** - Automated tax calculations and payment tracking
4. **Unified Payment Controller** - Single dashboard for all payment operations
5. **Subscription Payments Controller** - Dedicated subscription management

### Payment Flow Diagram

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  FRONTEND   │    │   BACKEND   │    │   PAYMENT   │
│             │    │             │    │   GATEWAYS  │
│ User clicks │───▶│ API Gateway │───▶│             │
│ Checkout    │    │             │    │  Stripe     │
└─────────────┘    └─────────────┘    └─────────────┘
                        │                       │
                        ▼                       ▼
               ┌─────────────┐          ┌─────────────┐
               │   UNIFIED   │          │   WEBHOOKS  │
               │ DASHBOARD   │          │             │
               │             │◀─────────│   Payment   │
               └─────────────┘          │   Status    │
                        │               └─────────────┘
                        ▼
               ┌─────────────┐
               │  DATABASE   │
               │             │
               │ Transactions│
               │ Subscriptions│
               │ Tax Records │
               └─────────────┘
```

## 💳 Payment Types Supported

### 1. Subscription Payments (Stripe)

**Plans Available:**
- **FREE**: 1 worker, basic features
- **BASIC**: $9.99/month, 5 workers, M-Pesa payments
- **GOLD**: $29.99/month, 10 workers, advanced reporting
- **PLATINUM**: $49.99/month, 15 workers, full feature set

**Features:**
- Automatic billing cycle
- Webhook integration for real-time updates
- Customer portal for self-service
- Multiple payment methods
- Trial periods support

### 2. Employee Payments (M-Pesa)

**Operations:**
- **STK Push**: Employee wallet top-ups
- **B2C Payments**: Salary distribution to employees
- **Bulk Payments**: Mass salary processing

**Security Features:**
- OAuth authentication with Safaricom
- Transaction status tracking
- Error handling and retries
- Audit logging

### 3. Tax Payments

**Tax Types Supported:**
- PAYE (Pay As You Earn)
- SHIF (Social Health Insurance Fund)
- NSSF (National Social Security Fund)
- Housing Levy

**Features:**
- Automatic calculations from payroll
- Payment tracking and compliance
- Integration with KRA systems
- Payment reminders and deadlines

## 🔌 API Endpoints

### Unified Payment Dashboard
```
GET    /payments/unified/dashboard           - Get payment overview
GET    /payments/unified/methods            - Get payment method status
POST   /payments/unified/subscribe          - Create subscription
PUT    /payments/unified/subscriptions/:id/cancel - Cancel subscription
POST   /payments/unified/mpesa/topup        - M-Pesa wallet top-up
POST   /payments/unified/tax-payments/record - Record tax payment
GET    /payments/unified/tax-payments/summary - Get tax summary
```

### Subscription Management
```
GET    /payments/subscriptions/plans         - Get available plans
GET    /payments/subscriptions/current       - Get current subscription
POST   /payments/subscriptions/checkout      - Create checkout session
GET    /payments/subscriptions/payment-history - Get payment history
GET    /payments/subscriptions/usage         - Get usage statistics
POST   /payments/subscriptions/webhook       - Stripe webhook handler
```

## 🚀 Implementation Examples

### Frontend Integration

#### 1. Subscription Checkout
```javascript
// Create subscription checkout
const response = await fetch('/payments/subscriptions/checkout', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    planId: 'basic'
  })
});

const { checkoutUrl } = await response.json();
window.location.href = checkoutUrl;
```

#### 2. Payment Dashboard
```javascript
// Get payment dashboard data
const dashboard = await fetch('/payments/unified/dashboard', {
  headers: { 'Authorization': `Bearer ${token}` }
});

const {
  overview,
  recentTransactions,
  paymentMethods,
  subscription,
  taxPayments
} = await dashboard.json();
```

#### 3. M-Pesa Top-up
```javascript
// Initiate M-Pesa STK Push
const response = await fetch('/payments/unified/mpesa/topup', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    phoneNumber: '+254700000000',
    amount: 1000
  })
});

const result = await response.json();
// result.checkoutRequestId for tracking
```

### Backend Service Integration

#### 1. Payment Status Updates
```typescript
// Handle payment status changes
export class PaymentStatusService {
  async handlePaymentUpdate(paymentId: string, status: PaymentStatus) {
    await this.notificationService.sendPaymentUpdate(paymentId, status);
    await this.auditService.logPaymentChange(paymentId, status);
    
    if (status === PaymentStatus.FAILED) {
      await this.alertService.sendPaymentFailureAlert(paymentId);
    }
  }
}
```

#### 2. Subscription Validation
```typescript
// Validate subscription before allowing operations
export class SubscriptionGuard {
  async canAccessFeature(userId: string, feature: string): Promise<boolean> {
    const subscription = await this.subscriptionService.getActive(userId);
    
    if (!subscription) return feature === 'free_tier';
    
    const plan = SUBSCRIPTION_PLANS.find(p => p.tier === subscription.tier);
    return plan?.features.includes(feature) || false;
  }
}
```

## 📊 Dashboard Components

### Payment Overview Card
```jsx
const PaymentOverview = ({ dashboard }) => (
  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
    <div className="bg-blue-50 p-4 rounded-lg">
      <h3 className="text-lg font-semibold text-blue-800">Total Transactions</h3>
      <p className="text-2xl font-bold">{dashboard.overview.totalTransactions}</p>
    </div>
    <div className="bg-green-50 p-4 rounded-lg">
      <h3 className="text-lg font-semibold text-green-800">Success Rate</h3>
      <p className="text-2xl font-bold">
        {Math.round((dashboard.overview.successfulTransactions / 
        dashboard.overview.totalTransactions) * 100)}%
      </p>
    </div>
    <div className="bg-yellow-50 p-4 rounded-lg">
      <h3 className="text-lg font-semibold text-yellow-800">Pending</h3>
      <p className="text-2xl font-bold">{dashboard.overview.pendingTransactions}</p>
    </div>
    <div className="bg-purple-50 p-4 rounded-lg">
      <h3 className="text-lg font-semibold text-purple-800">Active Subs</h3>
      <p className="text-2xl font-bold">{dashboard.overview.subscriptionsActive}</p>
    </div>
  </div>
);
```

### Payment Methods Status
```jsx
const PaymentMethodsStatus = ({ methods }) => (
  <div className="space-y-4">
    <div className="flex items-center justify-between p-4 bg-gray-50 rounded">
      <div>
        <h4 className="font-semibold">M-Pesa</h4>
        <p className="text-sm text-gray-600">
          Status: {methods.mpesa.configured ? 'Connected' : 'Not Configured'}
        </p>
      </div>
      <div className={`w-3 h-3 rounded-full ${
        methods.mpesa.configured ? 'bg-green-500' : 'bg-red-500'
      }`} />
    </div>
    
    <div className="flex items-center justify-between p-4 bg-gray-50 rounded">
      <div>
        <h4 className="font-semibold">Stripe</h4>
        <p className="text-sm text-gray-600">
          Status: {methods.stripe.configured ? 'Connected' : 'Not Configured'}
        </p>
      </div>
      <div className={`w-3 h-3 rounded-full ${
        methods.stripe.configured ? 'bg-green-500' : 'bg-red-500'
      }`} />
    </div>
  </div>
);
```

## 🔧 Configuration

### Environment Variables
```bash
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# M-Pesa Configuration
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_PASSKEY=your_passkey
MPESA_SHORTCODE=174379
MPESA_CALLBACK_URL=https://your-domain.com/callback

# Application
FRONTEND_URL=http://localhost:3000
```

### Database Schema

#### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  userId UUID NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'KES',
  type VARCHAR(20) NOT NULL, -- SUBSCRIPTION, SALARY_PAYOUT, TOPUP
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, SUCCESS, FAILED
  providerRef VARCHAR(255),
  metadata JSONB,
  createdAt TIMESTAMPTZ DEFAULT NOW()
);
```

#### Subscriptions Table
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  userId UUID NOT NULL,
  tier VARCHAR(20) NOT NULL, -- FREE, BASIC, GOLD, PLATINUM
  status VARCHAR(20) NOT NULL, -- ACTIVE, CANCELLED, EXPIRED, PAST_DUE
  amount DECIMAL(10,2),
  currency VARCHAR(3) DEFAULT 'USD',
  startDate TIMESTAMPTZ,
  endDate TIMESTAMPTZ,
  nextBillingDate TIMESTAMPTZ,
  stripeSubscriptionId VARCHAR(255),
  createdAt TIMESTAMPTZ DEFAULT NOW(),
  updatedAt TIMESTAMPTZ DEFAULT NOW()
);
```

## 🧪 Testing

### Unit Tests
```typescript
describe('StripeService', () => {
  it('should create checkout session', async () => {
    const session = await stripeService.createCheckoutSession(
      'user123',
      'BASIC',
      'user@example.com',
      'John Doe'
    );
    
    expect(session.url).toBeDefined();
    expect(session.sessionId).toBeDefined();
  });
  
  it('should handle webhook events', async () => {
    const mockEvent = {
      type: 'checkout.session.completed',
      data: { object: { id: 'cs_test_123' } }
    };
    
    await stripeService.handleWebhook(mockEvent);
    // Verify subscription was created
  });
});
```

### Integration Tests
```typescript
describe('Payment Integration', () => {
  it('should complete full subscription flow', async () => {
    // 1. Create checkout session
    const checkout = await createCheckoutSession('basic');
    
    // 2. Simulate successful payment (via webhook)
    await simulateWebhook('checkout.session.completed', checkout.sessionId);
    
    // 3. Verify subscription status
    const subscription = await getCurrentSubscription();
    expect(subscription.status).toBe('ACTIVE');
  });
});
```

## 🔐 Security Best Practices

### 1. Payment Security
- **PCI Compliance**: Never store credit card details
- **Tokenization**: Use payment provider tokens only
- **HTTPS**: All payment flows must use HTTPS
- **Webhook Verification**: Verify webhook signatures

### 2. Access Control
```typescript
// Role-based access to payment features
export class PaymentGuard {
  async canAccessPayment(userId: string, feature: string): Promise<boolean> {
    const subscription = await this.getUserSubscription(userId);
    
    switch (feature) {
      case 'bulk_payments':
        return ['GOLD', 'PLATINUM'].includes(subscription?.tier);
      case 'advanced_reporting':
        return ['GOLD', 'PLATINUM'].includes(subscription?.tier);
      default:
        return true;
    }
  }
}
```

### 3. Audit Logging
```typescript
export class PaymentAuditService {
  async logPaymentAction(
    userId: string,
    action: string,
    amount: number,
    metadata: any
  ) {
    await this.auditRepository.save({
      userId,
      action,
      amount,
      metadata,
      timestamp: new Date(),
      ipAddress: this.getClientIP(),
      userAgent: this.getUserAgent()
    });
  }
}
```

## 📈 Monitoring and Analytics

### Key Metrics to Track
- Payment success/failure rates
- Revenue by subscription tier
- M-Pesa transaction volumes
- Tax payment compliance rates
- User churn and retention

### Dashboard Alerts
```typescript
export class PaymentAlerts {
  async checkPaymentHealth() {
    const failedPayments = await this.getFailedPaymentsLast24h();
    if (failedPayments > 10) {
      await this.sendAlert('High payment failure rate detected');
    }
    
    const lowMpesaBalance = await this.checkMpesaBalance();
    if (lowMpesaBalance) {
      await this.sendAlert('M-Pesa account balance is low');
    }
  }
}
```

## 🚀 Deployment Checklist

### Pre-deployment
- [ ] Configure production Stripe keys
- [ ] Set up M-Pesa production credentials
- [ ] Configure webhook endpoints
- [ ] Set up monitoring and alerting
- [ ] Test payment flows in staging

### Post-deployment
- [ ] Monitor payment success rates
- [ ] Check webhook delivery
- [ ] Verify subscription renewals
- [ ] Test tax payment calculations
- [ ] Review error logs

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Review failed payment reports
- **Monthly**: Analyze subscription metrics
- **Quarterly**: Update tax calculations
- **Annually**: Review pricing and features

### Performance Optimization
- Cache payment method status
- Batch M-Pesa operations
- Optimize database queries
- Use CDN for static assets

## 📞 Support and Troubleshooting

### Common Issues

1. **Stripe Webhook Failures**
   - Check webhook endpoint URL
   - Verify webhook secret
   - Monitor webhook delivery logs

2. **M-Pesa STK Push Issues**
   - Verify M-Pesa credentials
   - Check phone number format
   - Monitor API rate limits

3. **Subscription Renewal Failures**
   - Check payment method validity
   - Verify Stripe account status
   - Monitor failed payment notifications

### Debug Mode
```typescript
// Enable detailed logging for payments
export class DebugPaymentService {
  async processPayment(paymentData: any) {
    console.log('Processing payment:', paymentData);
    
    try {
      const result = await this.executePayment(paymentData);
      console.log('Payment result:', result);
      return result;
    } catch (error) {
      console.error('Payment failed:', error);
      throw error;
    }
  }
}
```

---

This comprehensive payment system provides a robust foundation for managing subscriptions, employee payments, and tax compliance with Stripe and M-Pesa integration, following industry best practices for security and user experience.