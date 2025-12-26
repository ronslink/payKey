import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tour_progress_provider.dart';
import '../theme/onboarding_theme.dart';

/// A contextual tip that appears when a user first visits a feature
/// 
/// Wraps a child widget and shows a modal tip overlay if the user
/// hasn't dismissed this tip before.
class FeatureTip extends ConsumerWidget {
  /// Unique key for this tip (for persistence)
  final String tipKey;

  /// Title shown in the tip card
  final String title;

  /// Description explaining the feature
  final String description;

  /// Icon displayed in the tip card
  final IconData icon;

  /// The child widget to wrap
  final Widget child;

  /// Optional action button callback
  final VoidCallback? onActionPressed;

  /// Optional action button text
  final String? actionText;

  const FeatureTip({
    super.key,
    required this.tipKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tourProgressProvider);

    // Show child only if not loaded yet or already dismissed
    if (!progress.isLoaded || progress.hasSeen(tipKey)) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: _TipOverlay(
            title: title,
            description: description,
            icon: icon,
            actionText: actionText,
            onDismiss: () {
              ref.read(tourProgressProvider.notifier).dismissTip(tipKey);
            },
            onAction: onActionPressed,
          ),
        ),
      ],
    );
  }
}

/// Overlay that displays the tip card
class _TipOverlay extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _TipOverlay({
    required this.title,
    required this.description,
    required this.icon,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: OnboardingTheme.lightOverlayOpacity),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(OnboardingTheme.paddingXXLarge),
          child: _TipCard(
            title: title,
            description: description,
            icon: icon,
            onDismiss: onDismiss,
            onAction: onAction,
            actionText: actionText,
          ),
        ),
      ),
    );
  }
}

/// Card displaying the tip content
class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: OnboardingTheme.maxCardWidth),
      padding: const EdgeInsets.all(OnboardingTheme.paddingXXLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusXXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: OnboardingTheme.paddingXLarge),
          _buildTitle(),
          const SizedBox(height: OnboardingTheme.paddingMedium),
          _buildDescription(),
          const SizedBox(height: OnboardingTheme.paddingXXLarge),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(OnboardingTheme.paddingLarge),
      decoration: BoxDecoration(
        gradient: OnboardingTheme.primaryGradient,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusXLarge),
        boxShadow: OnboardingTheme.iconShadow,
      ),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: OnboardingTextStyles.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
      style: OnboardingTextStyles.descriptionCentered,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(child: _buildDismissButton()),
        if (onAction != null) ...[
          const SizedBox(width: OnboardingTheme.paddingMedium),
          Expanded(child: _buildActionButton()),
        ],
      ],
    );
  }

  Widget _buildDismissButton() {
    return OutlinedButton(
      onPressed: onDismiss,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        ),
        side: const BorderSide(color: OnboardingTheme.borderColor),
      ),
      child: const Text('Got it', style: TextStyle(color: OnboardingTheme.textSecondary)),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: () {
        onDismiss();
        onAction?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: OnboardingTheme.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        ),
        elevation: 0,
      ),
      child: Text(actionText ?? 'Continue'),
    );
  }
}
