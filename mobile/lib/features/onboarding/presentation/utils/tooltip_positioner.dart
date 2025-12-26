import 'package:flutter/material.dart';
import '../theme/onboarding_theme.dart';
import '../models/tour_models.dart';

/// Calculated position for a tour tooltip
class TooltipPosition {
  final double left;
  final double top;
  final bool isValid;

  const TooltipPosition({
    required this.left,
    required this.top,
    this.isValid = true,
  });

  const TooltipPosition.invalid()
      : left = 0,
        top = 0,
        isValid = false;
}

/// Utility for calculating safe tooltip positions
class TooltipPositioner {
  final Size screenSize;
  final double tooltipWidth;
  final double tooltipHeight;
  final EdgeInsets safeArea;

  const TooltipPositioner({
    required this.screenSize,
    this.tooltipWidth = OnboardingTheme.maxCardWidth,
    this.tooltipHeight = 200, // Estimated height
    this.safeArea = EdgeInsets.zero,
  });

  /// Calculate tooltip position that stays on screen
  TooltipPosition calculate({
    required Offset targetPosition,
    required Size targetSize,
    required TourStepPosition preferredPosition,
  }) {
    // Try preferred position first
    var position = _calculateForPosition(
      targetPosition: targetPosition,
      targetSize: targetSize,
      position: preferredPosition,
    );

    // If off-screen, try opposite position
    if (!_isOnScreen(position)) {
      final opposite = _getOppositePosition(preferredPosition);
      position = _calculateForPosition(
        targetPosition: targetPosition,
        targetSize: targetSize,
        position: opposite,
      );
    }

    // If still off-screen, fallback to centered below
    if (!_isOnScreen(position)) {
      position = _calculateCenteredBelow(targetPosition, targetSize);
    }

    return position;
  }

  TooltipPosition _calculateForPosition({
    required Offset targetPosition,
    required Size targetSize,
    required TourStepPosition position,
  }) {
    double left;
    double top;

    switch (position) {
      case TourStepPosition.above:
        left = _calculateHorizontalCenter(targetPosition, targetSize);
        top = targetPosition.dy - tooltipHeight - OnboardingTheme.tooltipOffset;
        break;

      case TourStepPosition.below:
        left = _calculateHorizontalCenter(targetPosition, targetSize);
        top = targetPosition.dy +
            targetSize.height +
            OnboardingTheme.tooltipOffset;
        break;

      case TourStepPosition.left:
        left = OnboardingTheme.tooltipMinEdgeDistance;
        top = _calculateVerticalCenter(targetPosition, targetSize);
        break;

      case TourStepPosition.right:
        left = screenSize.width -
            tooltipWidth -
            OnboardingTheme.tooltipMinEdgeDistance;
        top = _calculateVerticalCenter(targetPosition, targetSize);
        break;
    }

    // Clamp to screen bounds
    left = left.clamp(
      OnboardingTheme.tooltipMinEdgeDistance + safeArea.left,
      screenSize.width -
          tooltipWidth -
          OnboardingTheme.tooltipMinEdgeDistance -
          safeArea.right,
    );

    top = top.clamp(
      OnboardingTheme.tooltipMinEdgeDistance + safeArea.top,
      screenSize.height -
          tooltipHeight -
          OnboardingTheme.tooltipMinEdgeDistance -
          safeArea.bottom,
    );

    return TooltipPosition(left: left, top: top);
  }

  double _calculateHorizontalCenter(Offset target, Size targetSize) {
    final targetCenter = target.dx + targetSize.width / 2;
    return targetCenter - tooltipWidth / 2;
  }

  double _calculateVerticalCenter(Offset target, Size targetSize) {
    return target.dy;
  }

  TooltipPosition _calculateCenteredBelow(Offset target, Size targetSize) {
    return TooltipPosition(
      left: (screenSize.width - tooltipWidth) / 2,
      top: target.dy + targetSize.height + OnboardingTheme.tooltipOffset,
    );
  }

  bool _isOnScreen(TooltipPosition position) {
    return position.left >= OnboardingTheme.tooltipMinEdgeDistance &&
        position.left + tooltipWidth <=
            screenSize.width - OnboardingTheme.tooltipMinEdgeDistance &&
        position.top >= OnboardingTheme.tooltipMinEdgeDistance &&
        position.top + tooltipHeight <=
            screenSize.height - OnboardingTheme.tooltipMinEdgeDistance;
  }

  TourStepPosition _getOppositePosition(TourStepPosition position) {
    switch (position) {
      case TourStepPosition.above:
        return TourStepPosition.below;
      case TourStepPosition.below:
        return TourStepPosition.above;
      case TourStepPosition.left:
        return TourStepPosition.right;
      case TourStepPosition.right:
        return TourStepPosition.left;
    }
  }
}
