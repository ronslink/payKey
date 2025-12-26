import 'package:flutter/material.dart';

/// Theme constants for onboarding UI components
class OnboardingTheme {
  OnboardingTheme._();

  // ===========================================================================
  // COLORS
  // ===========================================================================

  /// Primary accent color for highlights and buttons
  static const Color primaryBlue = Color(0xFF3B82F6);

  /// Darker blue for gradients
  static const Color primaryBlueDark = Color(0xFF2563EB);

  /// Purple for gradient accents
  static const Color accentPurple = Color(0xFF8B5CF6);

  /// Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Border and divider color
  static const Color borderColor = Color(0xFFE5E7EB);

  /// Overlay colors
  static const double overlayOpacity = 0.7;
  static const double lightOverlayOpacity = 0.6;

  // ===========================================================================
  // DIMENSIONS
  // ===========================================================================

  /// Maximum width for tooltips and cards
  static const double maxCardWidth = 340.0;

  /// Standard padding values
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;

  /// Border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 20.0;

  /// Spotlight border width
  static const double spotlightBorderWidth = 2.0;
  static const double spotlightPadding = 8.0;

  /// Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Tooltip offset from target
  static const double tooltipOffset = 16.0;

  /// Minimum tooltip distance from screen edge
  static const double tooltipMinEdgeDistance = 24.0;

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentPurple],
  );

  // ===========================================================================
  // BOX SHADOWS
  // ===========================================================================

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get spotlightShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> get welcomeBannerShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get iconShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Text styles for onboarding components
class OnboardingTextStyles {
  OnboardingTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: OnboardingTheme.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: OnboardingTheme.textPrimary,
  );

  static const TextStyle description = TextStyle(
    fontSize: 14,
    color: OnboardingTheme.textSecondary,
    height: 1.5,
  );

  static const TextStyle descriptionCentered = TextStyle(
    fontSize: 14,
    color: OnboardingTheme.textSecondary,
    height: 1.6,
  );

  static const TextStyle welcomeTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );
}
