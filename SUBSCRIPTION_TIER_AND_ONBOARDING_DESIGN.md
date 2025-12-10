# PayKey Subscription Tiers & User Onboarding Design

**Date:** December 10, 2025  
**Objective:** Design a user-friendly subscription tier system with free trial mock data and guided onboarding  

---

## 📊 Executive Summary

This document outlines a comprehensive strategy to:
1. **Distribute features** across subscription tiers (FREE, BASIC, GOLD, PLATINUM)
2. **Implement a 14-day free trial** with mock data for premium features
3. **Create a guided onboarding experience** for first-time users

The goal is to let users **experience the full potential of PayKey** during trial, understand the value of each tier, and make upgrading feel natural—not forced.

---

## 🎯 Current App Features Analysis

### Complete Feature Inventory

Based on the codebase analysis, here are all the features in PayKey:

| Feature | Current Module | Complexity |
|---------|---------------|------------|
| **Worker Management** | `/workers` | Core |
| **Basic Payroll** | `/payroll` | Core |
| **Tax Calculations** | Automatic in payroll | Core |
| **Pay Periods** | `/pay_periods` | Core |
| **Leave Management** | `/leave_management` | Standard |
| **Time Tracking** | `/time_tracking` | Standard |
| **Employee Portal** | `/employee_portal` | Standard |
| **Reports** | `/reports` | Premium |
| **P9 Tax Cards** | `/taxes` | Premium |
| **Automatic Tax Filing** | `/taxes` | Premium |
| **Properties Management** | `/properties` | Premium |
| **Accounting Integration** | `/accounting` | Premium |
| **M-Pesa Payments** | `/payments` | Premium |
| **Multi-organization** | Planned | Enterprise |

---

## 💰 Proposed Subscription Tier Distribution

### Tier 1: FREE (1 Worker)
**Target:** Solo entrepreneurs, testing the app

| Feature | Access Level |
|---------|-------------|
| ✅ Add up to 1 worker | Full |
| ✅ Basic payroll calculation | Full |
| ✅ Automatic PAYE, NSSF, NHIF calculations | Full |
| ✅ View payslips | Full |
| ⚡ Reports | **Preview only (mock data)** |
| ⚡ P9 Tax Cards | **Preview only (mock data)** |
| ⚡ Leave Management | **Preview only (mock data)** |
| ❌ Time Tracking | Locked |
| ❌ M-Pesa Payments | Locked |
| ❌ Multi-property | Locked |
| ❌ Accounting Integration | Locked |
| ❌ Auto Tax Filing | Locked |

### Tier 2: BASIC (5 Workers) - KES 1,200/month
**Target:** Small households, 1-5 workers

| Feature | Access Level |
|---------|-------------|
| ✅ Up to 5 workers | Full |
| ✅ Basic payroll | Full |
| ✅ Tax calculations | Full |
| ✅ M-Pesa payments | Full |
| ✅ Leave Management | Full |
| ✅ Basic Reports | Full |
| ✅ P9 Tax Cards | Full |
| ⚡ Time Tracking | **Preview only (mock data)** |
| ⚡ Advanced Reports | **Preview only (mock data)** |
| ❌ Multi-property | Locked |
| ❌ Accounting Integration | Locked |
| ❌ Auto Tax Filing | Locked |

### Tier 3: GOLD (10 Workers) - KES 3,600/month
**Target:** Growing households, property managers

| Feature | Access Level |
|---------|-------------|
| ✅ Up to 10 workers | Full |
| ✅ All BASIC features | Full |
| ✅ Time Tracking | Full |
| ✅ Advanced Reports | Full |
| ✅ Priority Support | Full |
| ⚡ Multi-property | **Preview only (mock data)** |
| ⚡ Accounting Integration | **Preview only (mock data)** |
| ❌ Auto Tax Filing | Locked |

### Tier 4: PLATINUM (15 Workers) - KES 6,000/month
**Target:** Property managers, small agencies

| Feature | Access Level |
|---------|-------------|
| ✅ Up to 15 workers | Full |
| ✅ All GOLD features | Full |
| ✅ Multi-property management | Full |
| ✅ Accounting/Finance integration | Full |
| ✅ Automatic KRA tax filing | Full |
| ✅ Dedicated support | Full |

---

## 🎮 Free Trial Strategy: Mock Data Experience

### Concept: "Try Before You Buy"

During the **14-day trial**, users get access to **all PLATINUM features** with **mock data** for features beyond their eventual tier. This helps them:
1. Understand the full capability of PayKey
2. See what they'd get by upgrading
3. Make informed decisions about which tier fits their needs

### Mock Data Implementation

#### 1. Mock Data Service Architecture

```typescript
// backend/src/modules/mock-data/mock-data.service.ts

export interface MockDataConfig {
  feature: string;
  userTier: string;
  isTrialActive: boolean;
}

export class MockDataService {
  // Returns real data if user has access, mock data otherwise
  async getDataWithMockFallback<T>(
    config: MockDataConfig,
    realDataFetcher: () => Promise<T>,
    mockDataGenerator: () => T,
  ): Promise<{ data: T; isMock: boolean }> {
    // User has access to this feature
    if (this.hasFeatureAccess(config.feature, config.userTier)) {
      return { data: await realDataFetcher(), isMock: false };
    }
    
    // User is in trial - show mock data with preview badge
    if (config.isTrialActive) {
      return { data: mockDataGenerator(), isMock: true };
    }
    
    // Feature locked - return null or upgrade prompt
    throw new FeatureLockedError(config.feature, config.userTier);
  }
}
```

#### 2. Mock Data Examples by Feature

**Reports (Mock for FREE tier):**
```json
{
  "isMock": true,
  "data": {
    "payrollSummary": {
      "totalPaid": 245000,
      "totalDeductions": 48500,
      "monthlyTrend": [210000, 225000, 235000, 245000],
      "workerBreakdown": [
        { "name": "John Kamau", "grossPay": 85000, "netPay": 72500 },
        { "name": "Mary Wanjiku", "grossPay": 65000, "netPay": 55200 },
        { "name": "Peter Otieno", "grossPay": 95000, "netPay": 78800 }
      ]
    }
  }
}
```

**Time Tracking (Mock for BASIC tier):**
```json
{
  "isMock": true,
  "data": {
    "weeklyOverview": {
      "totalHours": 184,
      "overtime": 12,
      "attendance": 95.2,
      "entries": [
        { "worker": "Jane Akinyi", "checkIn": "08:15", "checkOut": "17:30", "hours": 9.25 }
      ]
    }
  }
}
```

**Multi-Property (Mock for GOLD tier):**
```json
{
  "isMock": true,
  "data": {
    "properties": [
      { "name": "Kilimani Residence", "workers": 3, "monthlyPayroll": 125000 },
      { "name": "Westlands Office", "workers": 5, "monthlyPayroll": 285000 },
      { "name": "Karen Villa", "workers": 2, "monthlyPayroll": 95000 }
    ],
    "consolidatedTotal": 505000
  }
}
```

---

## 📱 Frontend Mock Data Display

### Visual Design: "Preview Mode" Banner

When showing mock data, display a subtle but clear indicator:

```dart
// lib/core/widgets/preview_banner.dart

class PreviewBanner extends StatelessWidget {
  final String featureName;
  final String requiredTier;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFBBF24)),
      ),
      child: Row(
        children: [
          Icon(Icons.preview, color: Color(0xFFD97706)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                ),
                Text(
                  'Sample data shown. Upgrade to $requiredTier for real $featureName.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            child: Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
```

### Page Wrapper for Mock Data Features

```dart
// lib/core/widgets/feature_gate.dart

class FeatureGate extends ConsumerWidget {
  final String featureKey;
  final Widget child;
  final Widget? lockedWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final trialStatus = ref.watch(trialStatusProvider);
    
    return subscription.when(
      data: (sub) {
        final hasAccess = _checkFeatureAccess(sub.plan.tier, featureKey);
        final isTrialActive = trialStatus.isActive;
        
        if (hasAccess) {
          return child; // Full access
        } else if (isTrialActive) {
          return Column(
            children: [
              PreviewBanner(
                featureName: _getFeatureName(featureKey),
                requiredTier: _getRequiredTier(featureKey),
                onUpgrade: () => context.go('/subscription'),
              ),
              Expanded(child: child), // Show with mock data
            ],
          );
        } else {
          return lockedWidget ?? FeatureLockedPage(featureKey: featureKey);
        }
      },
      loading: () => LoadingIndicator(),
      error: (e, _) => ErrorWidget(e),
    );
  }
}
```

---

## 🎓 User Onboarding & Guided Tours

### Design Philosophy: Progressive Disclosure

Instead of overwhelming users with all features, we'll use **progressive disclosure**:
1. **First Time:** Essential setup only (current 4-step onboarding)
2. **First Home Visit:** Dashboard tour
3. **First Feature Use:** Contextual tooltips
4. **Ongoing:** Feature spotlights as they become relevant

### Implementation: Feature Tours

#### 1. Tour Tracking Model

```dart
// lib/features/onboarding/data/models/tour_progress.dart

class TourProgress {
  final bool hasSeenDashboardTour;
  final bool hasSeenPayrollTour;
  final bool hasSeenWorkersTour;
  final bool hasSeenReportsTour;
  final Map<String, bool> featureTooltipsShown;
  final DateTime? lastTourShown;
  
  // Don't show more than one tour per session
  bool get canShowTour => 
    lastTourShown == null || 
    DateTime.now().difference(lastTourShown!).inHours > 24;
}
```

#### 2. Dashboard Welcome Tour

**When:** First visit to home page after completing onboarding

```dart
class DashboardTour extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CoachMarkOverlay(
      steps: [
        CoachMarkStep(
          targetKey: 'business_snapshot',
          title: 'Your Business at a Glance',
          description: 'See your next payroll date, active workers, and estimated costs here.',
          position: CoachMarkPosition.below,
        ),
        CoachMarkStep(
          targetKey: 'quick_actions',
          title: 'Quick Actions',
          description: 'Jump to common tasks like running payroll or adding workers.',
          position: CoachMarkPosition.above,
        ),
        CoachMarkStep(
          targetKey: 'activity_feed',
          title: 'Recent Activity',
          description: 'Track all payroll runs, worker updates, and tax filings here.',
          position: CoachMarkPosition.above,
        ),
        CoachMarkStep(
          targetKey: 'bottom_nav',
          title: 'Navigation',
          description: 'Switch between Home, Workers, Payroll, and Finance from here.',
          position: CoachMarkPosition.above,
          isLast: true,
        ),
      ],
      onComplete: () => ref.read(tourProgressProvider.notifier).markDashboardTourComplete(),
    );
  }
}
```

#### 3. Contextual Feature Tips

**When:** User navigates to a feature for the first time

```dart
class FeatureTip extends StatelessWidget {
  final String featureKey;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeenTip = ref.watch(featureTipSeenProvider(featureKey));
    
    if (hasSeenTip) return child;
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            onTap: () => ref.read(featureTipSeenProvider(featureKey).notifier).markSeen(),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: TipCard(
                  title: title,
                  description: description,
                  onDismiss: () => ref.read(featureTipSeenProvider(featureKey).notifier).markSeen(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### Feature Tips Content

| Feature | Title | Description |
|---------|-------|-------------|
| **Workers** | "Add Your First Worker" | "Start by adding your domestic workers. You'll need their name, ID, and salary details." |
| **Payroll** | "Run Payroll in 3 Steps" | "1. Review workers → 2. Confirm calculations → 3. Process payments. It's that simple!" |
| **Time Tracking** | "Track Attendance" | "Enable clock-in/clock-out for your workers to track working hours automatically." |
| **Leave** | "Manage Time Off" | "Track vacation days, sick leave, and other time off for each worker." |
| **Reports** | "Insights & Analytics" | "View payroll trends, tax summaries, and generate PDF reports for your records." |
| **Tax Filing** | "Automatic Tax Compliance" | "PayKey calculates and can auto-file your taxes with KRA. No more manual forms!" |

---

## 🛠 Implementation Plan

### Phase 1: Backend Feature Gating (Week 1)

1. **Update Subscription Plans Config**
   - Add detailed feature list per tier
   - Define feature access matrix

2. **Create Feature Access Service**
   - `hasFeatureAccess(userId, featureKey)`
   - `getAccessibleFeatures(userId)`
   - `isInTrialPeriod(userId)`

3. **Create Mock Data Service**
   - Mock data generators for each premium feature
   - API endpoints return `{ data, isMock }` format

### Phase 2: Frontend Feature Gates (Week 2)

1. **Create FeatureGate Widget**
   - Wraps feature pages
   - Shows preview banner for mock data
   - Shows upgrade prompt for locked features

2. **Update All Feature Pages**
   - Wrap Reports, Time Tracking, Properties, Accounting
   - Handle mock data display

3. **Create Upgrade Prompts**
   - Inline upgrade buttons
   - Full-page locked feature screens

### Phase 3: Guided Tours (Week 3)

1. **Create Tour Infrastructure**
   - CoachMarkOverlay widget
   - TourProgress tracking
   - Feature tip system

2. **Implement Tours**
   - Dashboard welcome tour
   - Per-feature contextual tips

3. **Persist Tour Progress**
   - Local storage for tour state
   - Sync with backend for cross-device

### Phase 4: Polish & Testing (Week 4)

1. **UX Testing**
   - Test trial flow end-to-end
   - Gather feedback on mock data clarity

2. **Analytics Integration**
   - Track feature access attempts
   - Track upgrade funnel conversion

3. **Documentation**
   - Update user guides
   - Create upgrade comparison page

---

## 📐 Technical Implementation Details

### 1. Updated Subscription Plans Config

```typescript
// backend/src/modules/subscriptions/subscription-plans.config.ts

export interface FeatureAccess {
  key: string;
  name: string;
  description: string;
  tiers: ('FREE' | 'BASIC' | 'GOLD' | 'PLATINUM')[];
  mockDataAvailable: boolean;
}

export const FEATURE_ACCESS_MATRIX: FeatureAccess[] = [
  {
    key: 'workers',
    name: 'Worker Management',
    description: 'Add and manage domestic workers',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
  },
  {
    key: 'basic_payroll',
    name: 'Basic Payroll',
    description: 'Run payroll with automatic tax calculations',
    tiers: ['FREE', 'BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: false,
  },
  {
    key: 'leave_management',
    name: 'Leave Management',
    description: 'Track vacation and sick days',
    tiers: ['BASIC', 'GOLD', 'PLATINUM'],
    mockDataAvailable: true,
  },
  {
    key: 'time_tracking',
    name: 'Time Tracking',
    description: 'Clock in/out and attendance tracking',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: true,
  },
  {
    key: 'advanced_reports',
    name: 'Advanced Reports',
    description: 'Detailed analytics and PDF exports',
    tiers: ['GOLD', 'PLATINUM'],
    mockDataAvailable: true,
  },
  {
    key: 'multi_property',
    name: 'Multi-Property Management',
    description: 'Manage workers across multiple properties',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
  },
  {
    key: 'accounting_integration',
    name: 'Accounting Integration',
    description: 'Connect with finance software',
    tiers: ['PLATINUM'],
    mockDataAvailable: true,
  },
  {
    key: 'auto_tax_filing',
    name: 'Automatic Tax Filing',
    description: 'Auto-file taxes with KRA',
    tiers: ['PLATINUM'],
    mockDataAvailable: false, // Too sensitive for mock
  },
];
```

### 2. Feature Access Check Service

```typescript
// backend/src/modules/subscriptions/feature-access.service.ts

@Injectable()
export class FeatureAccessService {
  constructor(
    private usersService: UsersService,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
  ) {}

  async checkAccess(userId: string, featureKey: string): Promise<{
    hasAccess: boolean;
    isPreview: boolean;
    requiredTier: string | null;
  }> {
    const user = await this.usersService.findOneById(userId);
    const subscription = await this.getCurrentSubscription(userId);
    
    const feature = FEATURE_ACCESS_MATRIX.find(f => f.key === featureKey);
    if (!feature) {
      return { hasAccess: true, isPreview: false, requiredTier: null };
    }
    
    const userTier = subscription?.tier || 'FREE';
    const hasAccess = feature.tiers.includes(userTier as any);
    
    if (hasAccess) {
      return { hasAccess: true, isPreview: false, requiredTier: null };
    }
    
    // Check if in trial period
    const isInTrial = this.isInTrialPeriod(user.createdAt);
    if (isInTrial && feature.mockDataAvailable) {
      return { 
        hasAccess: true, 
        isPreview: true, 
        requiredTier: this.getLowestTierWithAccess(feature),
      };
    }
    
    return {
      hasAccess: false,
      isPreview: false,
      requiredTier: this.getLowestTierWithAccess(feature),
    };
  }

  private isInTrialPeriod(createdAt: Date): boolean {
    const trialEnd = new Date(createdAt);
    trialEnd.setDate(trialEnd.getDate() + TRIAL_PERIOD_DAYS);
    return new Date() <= trialEnd;
  }

  private getLowestTierWithAccess(feature: FeatureAccess): string {
    const tierOrder = ['FREE', 'BASIC', 'GOLD', 'PLATINUM'];
    for (const tier of tierOrder) {
      if (feature.tiers.includes(tier as any)) {
        return tier;
      }
    }
    return 'PLATINUM';
  }
}
```

### 3. Frontend Providers

```dart
// lib/features/subscriptions/presentation/providers/feature_access_provider.dart

final featureAccessProvider = FutureProvider.family<FeatureAccess, String>((ref, featureKey) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.checkFeatureAccess(featureKey);
});

final trialStatusProvider = FutureProvider<TrialStatus>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getTrialStatus();
});

class TrialStatus {
  final bool isActive;
  final int daysRemaining;
  final DateTime? expiresAt;
  
  bool get isExpiringSoon => isActive && daysRemaining <= 3;
}
```

---

## 🎨 UI/UX Considerations

### 1. Never Use Aggressive Upgrade Popups

Instead of interrupting the user, use:
- Inline banners at the top of feature pages
- Subtle "Upgrade" buttons in the toolbar
- Feature comparison when user attempts locked action

### 2. Make Mock Data Clearly Distinguishable

- Yellow/amber tinted preview banner
- Watermark on mock reports
- "Sample Data" label on mock entries

### 3. Trial Countdown (Non-Intrusive)

Show trial status in:
- Profile/Settings page
- Subscription management page
- Small badge in app header (last 3 days only)

### 4. Upgrade Path Clarity

Create a simple comparison page:
```
Your Current Plan: FREE
│
├── ✅ 1 Worker
├── ✅ Basic Payroll
├── ✅ Tax Calculations
│
What you'd get with BASIC (KES 1,200/mo):
│
├── 🆕 Up to 5 workers (+4)
├── 🆕 M-Pesa payments
├── 🆕 Leave management
├── 🆕 P9 Tax Cards
│
[Upgrade Now]
```

---

## 📊 Success Metrics

Track these to measure effectiveness:

| Metric | Target |
|--------|--------|
| Trial-to-paid conversion rate | > 15% |
| Feature discovery rate | > 80% try 3+ features |
| Upgrade funnel completion | > 25% click upgrade |
| Onboarding completion rate | > 90% |
| Time to first payroll run | < 10 minutes |
| Feature tip dismissal rate | < 50% (want users to read them) |

---

## 🔄 Next Steps

1. **Review this plan** with stakeholders
2. **Prioritize features** for Phase 1
3. **Design mockups** for preview banners and locked states
4. **Begin backend implementation** of feature access service
5. **Create mock data generators** for each feature

---

## 📚 Related Documents

- `/SUBSCRIPTION_REFACTORING_CHANGELOG.md` - Previous subscription work
- `/onboarding_enhancement_plan.md` - Onboarding field requirements
- `/backend/src/modules/subscriptions/subscription-plans.config.ts` - Current tier config

---

**Document Author:** Antigravity AI Assistant  
**Last Updated:** December 10, 2025
