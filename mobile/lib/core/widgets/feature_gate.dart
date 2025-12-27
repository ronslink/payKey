import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/subscriptions/presentation/providers/feature_access_provider.dart';

/// Access level for a feature (internal to this widget)
enum FeatureAccessLevelLocal {
  /// Full access to the feature
  fullAccess,
  /// Preview mode with mock data (during trial)
  preview,
  /// Feature is locked
  locked,
}

/// Model representing feature access status
class FeatureAccess {
  final bool hasAccess;
  final bool isPreview;
  final String? requiredTier;
  final String? reason;
  final String? featureName;

  const FeatureAccess({
    required this.hasAccess,
    required this.isPreview,
    this.requiredTier,
    this.reason,
    this.featureName,
  });

  FeatureAccessLevelLocal get accessLevel {
    if (hasAccess && !isPreview) return FeatureAccessLevelLocal.fullAccess;
    if (hasAccess && isPreview) return FeatureAccessLevelLocal.preview;
    return FeatureAccessLevelLocal.locked;
  }

  factory FeatureAccess.fullAccess() => const FeatureAccess(
        hasAccess: true,
        isPreview: false,
      );

  factory FeatureAccess.preview({String? requiredTier, String? featureName}) =>
      FeatureAccess(
        hasAccess: true,
        isPreview: true,
        requiredTier: requiredTier,
        featureName: featureName,
      );

  factory FeatureAccess.locked({String? requiredTier, String? reason}) =>
      FeatureAccess(
        hasAccess: false,
        isPreview: false,
        requiredTier: requiredTier,
        reason: reason,
      );

  factory FeatureAccess.fromResult(FeatureAccessResult result) => FeatureAccess(
        hasAccess: result.hasAccess,
        isPreview: result.isPreview,
        requiredTier: result.requiredTier,
        reason: result.reason,
      );
}

/// A widget that gates access to features based on subscription tier
///
/// Shows the child widget with a preview banner if in preview mode,
/// or shows a locked screen if the feature is not accessible.
class FeatureGate extends ConsumerWidget {
  /// The feature key to check access for
  final String featureKey;

  /// The child widget to display if access is granted
  final Widget child;

  /// Optional custom widget to show when feature is locked
  final Widget? lockedWidget;

  /// Whether to show the preview banner at the top (default: true)
  final bool showPreviewBanner;

  /// Optional callback when upgrade is tapped
  final VoidCallback? onUpgrade;

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.child,
    this.lockedWidget,
    this.showPreviewBanner = true,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(featureAccessProvider(featureKey));

    return accessAsync.when(
      data: (result) {
        final access = FeatureAccess.fromResult(result);
        return _buildContent(context, access);
      },
      loading: () => child, // Show content while loading
      error: (e, _) => child, // On error, allow access
    );
  }

  Widget _buildContent(BuildContext context, FeatureAccess access) {
    // Get current route to pass as returnPath
    final currentRoute = GoRouterState.of(context).uri.toString();

    switch (access.accessLevel) {
      case FeatureAccessLevelLocal.fullAccess:
        return child;

      case FeatureAccessLevelLocal.preview:
        if (!showPreviewBanner) return child;
        return Column(
          children: [
            PreviewBanner(
              featureName: access.featureName ?? _getFeatureDisplayName(featureKey),
              requiredTier: access.requiredTier ?? 'BASIC',
              onUpgrade: onUpgrade ?? () => context.go('/subscriptions?returnPath=${Uri.encodeComponent(currentRoute)}'),
            ),
            Expanded(child: child),
          ],
        );

      case FeatureAccessLevelLocal.locked:
        return lockedWidget ??
            FeatureLockedScreen(
              featureKey: featureKey,
              requiredTier: access.requiredTier,
              reason: access.reason,
              onUpgrade: onUpgrade ?? () => context.go('/subscriptions?returnPath=${Uri.encodeComponent(currentRoute)}'),
            );
    }
  }

  String _getFeatureDisplayName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Banner shown at the top of a page when viewing preview/mock data
class PreviewBanner extends StatelessWidget {
  final String featureName;
  final String requiredTier;
  final VoidCallback onUpgrade;
  final bool isDismissible;

  const PreviewBanner({
    super.key,
    required this.featureName,
    required this.requiredTier,
    required this.onUpgrade,
    this.isDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.preview_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Preview Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Viewing sample data. Upgrade to $requiredTier for real $featureName.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page screen shown when a feature is locked
class FeatureLockedScreen extends StatelessWidget {
  final String featureKey;
  final String? requiredTier;
  final String? reason;
  final VoidCallback onUpgrade;

  const FeatureLockedScreen({
    super.key,
    required this.featureKey,
    this.requiredTier,
    this.reason,
    required this.onUpgrade,
  });

  String get _featureDisplayName {
    // Convert feature key to readable name
    return featureKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 32),

              // Feature Name
              Text(
                _featureDisplayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                reason ?? 'This feature requires a $requiredTier subscription or higher.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tier Badge
              if (requiredTier != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getTierGradient(requiredTier!),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTierIcon(requiredTier!),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Requires $requiredTier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 48),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View Plans & Upgrade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getTierGradient(String tier) {
    switch (tier.toUpperCase()) {
      case 'BASIC':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'GOLD':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'PLATINUM':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toUpperCase()) {
      case 'BASIC':
        return Icons.star_outline_rounded;
      case 'GOLD':
        return Icons.star_rounded;
      case 'PLATINUM':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.lock_outline_rounded;
    }
  }
}

/// Inline upgrade prompt for use within feature pages
class InlineUpgradePrompt extends StatelessWidget {
  final String message;
  final String buttonText;
  final VoidCallback onUpgrade;
  final IconData? icon;

  const InlineUpgradePrompt({
    super.key,
    required this.message,
    this.buttonText = 'Upgrade',
    required this.onUpgrade,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

/// A professional dialog shown when a feature requires a higher subscription tier.
/// Use [showFeatureUpgradeDialog] for convenience.
class FeatureUpgradeDialog extends StatelessWidget {
  final String featureName;
  final String? requiredTier;
  final VoidCallback onUpgrade;
  final VoidCallback? onCancel;

  const FeatureUpgradeDialog({
    super.key,
    required this.featureName,
    this.requiredTier,
    required this.onUpgrade,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getTierGradient(requiredTier ?? 'GOLD'),
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTierIcon(requiredTier ?? 'GOLD'),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Upgrade Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              '$featureName is available on ${requiredTier ?? 'GOLD'} and higher plans. '
              'Upgrade your subscription to unlock this feature.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Tier badge
            if (requiredTier != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getTierGradient(requiredTier!)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTierIcon(requiredTier!), color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Requires $requiredTier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Upgrade Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getTierGradient(String tier) {
    switch (tier.toUpperCase()) {
      case 'BASIC':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'GOLD':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'PLATINUM':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toUpperCase()) {
      case 'BASIC':
        return Icons.star_outline_rounded;
      case 'GOLD':
        return Icons.star_rounded;
      case 'PLATINUM':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.lock_outline_rounded;
    }
  }
}

/// Shows the [FeatureUpgradeDialog] and returns when closed.
/// [onUpgrade] is called when the user taps "Upgrade Now".
void showFeatureUpgradeDialog(
  BuildContext context, {
  required String featureName,
  String? requiredTier,
  VoidCallback? onUpgrade,
}) {
  showDialog(
    context: context,
    builder: (ctx) => FeatureUpgradeDialog(
      featureName: featureName,
      requiredTier: requiredTier ?? 'GOLD',
      onUpgrade: onUpgrade ?? () {
        Navigator.of(ctx).pop();
        // Default: navigate to subscription settings
        // Assumes GoRouter is used and settingsSubscription route exists
      },
    ),
  );
}
