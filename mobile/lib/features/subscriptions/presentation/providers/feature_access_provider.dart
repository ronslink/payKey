import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';

// ============================================================================
// Feature Access Models
// ============================================================================

/// Access level for a feature
enum FeatureAccessLevel {
  /// User has full access to this feature
  full,
  /// User can preview with mock data (trial)
  preview,
  /// User cannot access this feature
  locked,
}

/// Result of checking feature access
class FeatureAccessResult {
  final bool hasAccess;
  final FeatureAccessLevel accessLevel;
  final bool isPreview;
  final String? requiredTier;
  final String? reason;
  final String? mockNotice;

  const FeatureAccessResult({
    required this.hasAccess,
    required this.accessLevel,
    this.isPreview = false,
    this.requiredTier,
    this.reason,
    this.mockNotice,
  });

  factory FeatureAccessResult.full() => const FeatureAccessResult(
        hasAccess: true,
        accessLevel: FeatureAccessLevel.full,
      );

  factory FeatureAccessResult.preview({String? mockNotice}) => FeatureAccessResult(
        hasAccess: true,
        accessLevel: FeatureAccessLevel.preview,
        isPreview: true,
        mockNotice: mockNotice,
      );

  factory FeatureAccessResult.locked(String requiredTier, String reason) =>
      FeatureAccessResult(
        hasAccess: false,
        accessLevel: FeatureAccessLevel.locked,
        requiredTier: requiredTier,
        reason: reason,
      );
}

/// Trial status information
class TrialStatus {
  final bool isInTrial;
  final int daysRemaining;
  final DateTime? trialEndDate;
  final bool isExpired;

  const TrialStatus({
    required this.isInTrial,
    required this.daysRemaining,
    this.trialEndDate,
    this.isExpired = false,
  });

  factory TrialStatus.active(int daysRemaining, DateTime endDate) => TrialStatus(
        isInTrial: true,
        daysRemaining: daysRemaining,
        trialEndDate: endDate,
      );

  factory TrialStatus.expired() => const TrialStatus(
        isInTrial: false,
        daysRemaining: 0,
        isExpired: true,
      );

  factory TrialStatus.noTrial() => const TrialStatus(
        isInTrial: false,
        daysRemaining: 0,
      );
}

/// Full subscription summary
class SubscriptionSummary {
  final String tier;
  final bool isTrialActive;
  final int trialDaysRemaining;
  final int workerLimit;
  final int currentWorkerCount;
  final List<String> accessibleFeatures;
  final List<String> previewFeatures;
  final List<String> lockedFeatures;

  const SubscriptionSummary({
    required this.tier,
    required this.isTrialActive,
    required this.trialDaysRemaining,
    required this.workerLimit,
    required this.currentWorkerCount,
    required this.accessibleFeatures,
    required this.previewFeatures,
    required this.lockedFeatures,
  });

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    return SubscriptionSummary(
      tier: json['tier'] ?? 'FREE',
      isTrialActive: json['isTrialActive'] ?? false,
      trialDaysRemaining: json['trialDaysRemaining'] ?? 0,
      workerLimit: json['workerLimit'] ?? 1,
      currentWorkerCount: json['currentWorkerCount'] ?? 0,
      accessibleFeatures: List<String>.from(features['accessible'] ?? []),
      previewFeatures: List<String>.from(features['preview'] ?? []),
      lockedFeatures: List<String>.from(features['locked'] ?? []),
    );
  }

  /// Check if a feature is accessible (full or preview)
  bool canAccess(String featureKey) {
    return accessibleFeatures.contains(featureKey) ||
        previewFeatures.contains(featureKey);
  }

  /// Check if a feature requires preview mode
  bool isPreview(String featureKey) {
    return previewFeatures.contains(featureKey);
  }

  /// Check if a feature is completely locked
  bool isLocked(String featureKey) {
    return lockedFeatures.contains(featureKey);
  }
}

// ============================================================================
// Feature Access Service
// ============================================================================

class FeatureAccessService {
  final ApiService _apiService = ApiService();

  /// Get the current user's subscription summary including feature access
  Future<SubscriptionSummary> getSubscriptionSummary() async {
    try {
      final response = await _apiService.dio.get('/features');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return SubscriptionSummary.fromJson(response.data);
      }
      // Return default FREE tier if API doesn't respond
      return _getDefaultSummary();
    } catch (e) {
      // Return default on error - user can still use app
      return _getDefaultSummary();
    }
  }

  /// Check access to a specific feature
  Future<FeatureAccessResult> checkFeatureAccess(String featureKey) async {
    try {
      final response = await _apiService.dio.get('/features/access/$featureKey');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final hasAccess = data['hasAccess'] ?? false;
        final isPreview = data['isPreview'] ?? false;

        if (!hasAccess) {
          return FeatureAccessResult.locked(
            data['requiredTier'] ?? 'BASIC',
            data['reason'] ?? 'Upgrade to access this feature',
          );
        }

        if (isPreview) {
          return FeatureAccessResult.preview(
            mockNotice: data['mockNotice'],
          );
        }

        return FeatureAccessResult.full();
      }
      return FeatureAccessResult.full(); // Default to allow
    } catch (e) {
      // On error, default to allowing access (fail open for UX)
      return FeatureAccessResult.full();
    }
  }

  /// Get trial status
  Future<TrialStatus> getTrialStatus() async {
    try {
      final response = await _apiService.dio.get('/features/trial-status');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final isInTrial = data['isTrialActive'] ?? false;
        final daysRemaining = data['daysRemaining'] ?? 0;

        if (isInTrial && daysRemaining > 0) {
          return TrialStatus.active(
            daysRemaining,
            DateTime.now().add(Duration(days: daysRemaining)),
          );
        } else if (data['isExpired'] == true) {
          return TrialStatus.expired();
        }
      }
      return TrialStatus.noTrial();
    } catch (e) {
      return TrialStatus.noTrial();
    }
  }

  SubscriptionSummary _getDefaultSummary() {
    return const SubscriptionSummary(
      tier: 'FREE',
      isTrialActive: false,
      trialDaysRemaining: 0,
      workerLimit: 1,
      currentWorkerCount: 0,
      accessibleFeatures: ['workers', 'basic_payroll', 'tax_calculations', 'payslips'],
      previewFeatures: [],
      lockedFeatures: [
        'leave_management',
        'mpesa_payments',
        'basic_reports',
        'time_tracking',
        'advanced_reports',
        'accounting_integration',
      ],
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for the feature access service
final featureAccessServiceProvider = Provider<FeatureAccessService>((ref) {
  return FeatureAccessService();
});

/// Provider for subscription summary - caches the result
final subscriptionSummaryProvider = FutureProvider<SubscriptionSummary>((ref) async {
  final service = ref.read(featureAccessServiceProvider);
  return service.getSubscriptionSummary();
});

/// Provider for trial status
final trialStatusProvider = FutureProvider<TrialStatus>((ref) async {
  final service = ref.read(featureAccessServiceProvider);
  return service.getTrialStatus();
});

/// Family provider to check access to a specific feature
final featureAccessProvider =
    FutureProvider.family<FeatureAccessResult, String>((ref, featureKey) async {
  // First try to use cached summary
  final summaryAsync = ref.watch(subscriptionSummaryProvider);
  
  return summaryAsync.when(
    data: (summary) {
      if (summary.lockedFeatures.contains(featureKey)) {
        return FeatureAccessResult.locked(
          _getRequiredTierForFeature(featureKey),
          'Upgrade to ${_getRequiredTierForFeature(featureKey)} to access this feature',
        );
      }
      if (summary.previewFeatures.contains(featureKey)) {
        return FeatureAccessResult.preview(
          mockNotice: 'This is sample data. Upgrade to see your real data.',
        );
      }
      return FeatureAccessResult.full();
    },
    loading: () => FeatureAccessResult.full(), // Default to allow while loading
    error: (_, _) => FeatureAccessResult.full(), // Default to allow on error
  );
});

/// Helper to get minimum tier for a feature
String _getRequiredTierForFeature(String featureKey) {
  const tierMap = {
    // BASIC tier features
    'mpesa_payments': 'BASIC',
    'p9_tax_cards': 'BASIC',
    'basic_reports': 'BASIC',
    // GOLD tier features
    'time_tracking': 'GOLD',
    'advanced_reports': 'GOLD',
    'accounting_integration': 'GOLD',
    'geofencing': 'GOLD',
    // PLATINUM tier features
    'leave_management': 'PLATINUM',
    'employee_portal': 'PLATINUM',
    'auto_tax_filing': 'PLATINUM',
  };
  return tierMap[featureKey] ?? 'BASIC';
}

/// Provider to check if user can add more workers
final canAddWorkerProvider = FutureProvider<bool>((ref) async {
  final summaryAsync = ref.watch(subscriptionSummaryProvider);
  
  return summaryAsync.when(
    data: (summary) => summary.currentWorkerCount < summary.workerLimit,
    loading: () => true,
    error: (_, _) => true,
  );
});

/// Provider for remaining worker slots
final remainingWorkerSlotsProvider = Provider<int>((ref) {
  final summaryAsync = ref.watch(subscriptionSummaryProvider);
  
  return summaryAsync.when(
    data: (summary) => summary.workerLimit - summary.currentWorkerCount,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
