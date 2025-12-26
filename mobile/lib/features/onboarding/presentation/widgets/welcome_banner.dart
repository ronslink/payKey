import 'package:flutter/material.dart';
import '../theme/onboarding_theme.dart';

/// Welcome banner shown to new users
/// 
/// Displays a greeting and offers to start a guided tour.
class WelcomeBanner extends StatelessWidget {
  /// User's display name
  final String userName;

  /// Called when user dismisses the banner
  final VoidCallback onDismiss;

  /// Called when user chooses to start the tour
  final VoidCallback onStartTour;

  const WelcomeBanner({
    super.key,
    required this.userName,
    required this.onDismiss,
    required this.onStartTour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(OnboardingTheme.paddingLarge),
      padding: const EdgeInsets.all(OnboardingTheme.paddingXLarge),
      decoration: BoxDecoration(
        gradient: OnboardingTheme.welcomeGradient,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusXLarge),
        boxShadow: OnboardingTheme.welcomeBannerShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: OnboardingTheme.paddingLarge),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName! 👋',
                style: OnboardingTextStyles.welcomeTitle,
              ),
              const SizedBox(height: OnboardingTheme.paddingSmall),
              const Text(
                "Let's get you started with PayKey. We'll show you around!",
                style: OnboardingTextStyles.welcomeSubtitle,
              ),
            ],
          ),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: onDismiss,
      icon: const Icon(Icons.close, color: Colors.white54),
      tooltip: 'Dismiss',
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        _buildStartTourButton(),
        const SizedBox(width: OnboardingTheme.paddingMedium),
        _buildMaybeLaterButton(),
      ],
    );
  }

  Widget _buildStartTourButton() {
    return ElevatedButton.icon(
      onPressed: onStartTour,
      icon: const Icon(Icons.play_arrow_rounded, size: 18),
      label: const Text('Start Tour'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: OnboardingTheme.primaryBlue,
        padding: const EdgeInsets.symmetric(
          horizontal: OnboardingTheme.paddingXLarge,
          vertical: OnboardingTheme.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildMaybeLaterButton() {
    return TextButton(
      onPressed: onDismiss,
      style: TextButton.styleFrom(foregroundColor: Colors.white70),
      child: const Text('Maybe later'),
    );
  }
}

/// Compact welcome banner for returning users
class CompactWelcomeBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onDismiss;

  const CompactWelcomeBanner({
    super.key,
    required this.userName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: OnboardingTheme.paddingLarge,
        vertical: OnboardingTheme.paddingSmall,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingTheme.paddingLarge,
        vertical: OnboardingTheme.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: OnboardingTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        border: Border.all(
          color: OnboardingTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.waving_hand,
            color: OnboardingTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: OnboardingTheme.paddingMedium),
          Expanded(
            child: Text(
              'Welcome back, $userName!',
              style: TextStyle(
                color: OnboardingTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close,
              size: 18,
              color: OnboardingTheme.textMuted,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
